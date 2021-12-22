class DspacePublicationResultsJob < ActiveJob::Base
  MAX_MESSAGES = ENV.fetch('SQS_RESULT_MAX_MESSAGES', 10)
  WAIT_TIME_SECONDS = ENV.fetch('SQS_RESULT_WAIT_TIME_SECONDS', 10)
  IDLE_TIMEOUT = ENV.fetch('SQS_RESULT_IDLE_TIMEOUT', 0)

  queue_as :default

  def perform
    results = { total: 0, processed: 0, errors: [] }
    queue_url = ENV.fetch('SQS_OUTPUT_QUEUE_URL')
    Rails.logger.info("Reading messages from queue #{queue_url}...")

    begin
      poll_messages(queue_url, results)
    rescue StandardError, Aws::Errors, Aws::SQS::Errors => e
      Rails.logger.info("Error reading from SQS queue: #{e}")
      results[:errors] << "Error reading from SQS queue: #{e}"
    end

    ReportMailer.publication_results_email(results).deliver_now if results[:total].positive? ||
                                                                   results[:errors].any?
    results
  end

  private

  def update_handle(thesis, body, results)
    handle = body['ItemHandle']
    if handle
      thesis.dspace_handle = handle
      thesis.publication_status = 'Published'
      thesis.save
      Rails.logger.info("Thesis #{thesis.id} updated to status #{thesis.publication_status} with handle"\
                        " #{thesis.dspace_handle}")
      results[:processed] += 1
    else
      thesis.publication_status = 'Publication error'
      thesis.save
      Rails.logger.info("Handle not provided #{body}; Cannot continue")
      results[:errors] << "Handle not provided; cannot continue (thesis #{thesis.id})"
    end
  end

  # Validating checksums is essential to ensure the files we published submitted successfully. Rails stores a different
  # version of the checksum than DSpace, so we convert our stored versions to what DSpace uses and then compare them.
  # However, we don't publish all files to DSpace, so the approach taken is to ensure that each returned checksum is
  # included in one of our locally stored checksums but not that each locally stored checksum is returned.
  # The business logic needs to allow for humans to react to this problem. Ideally, DSS would do this check and delete
  # the published thesis immediately if the checksums failed, but at this time DSS is not doing that validation. This
  # application first does our normal processing to store the published handle, and then validates the checksums. If
  # any returned checksums are not expected, we re-update the Thesis record to an error state and provide information to
  # stakeholders via email so they can take appropriate steps to either fix manually republish the problem file(s) or
  # delete the thesis from DSpace manually and republish it from this app.
  def validate_checksums(thesis, body, results)
    expected_checksums = convert_checksums(thesis)
    actual_checksums = collect_checksums(body)

    Rails.logger.info("Validating Checksums for #{thesis.id}")

    # confirm etd record has files to validate. This should never be an issue, but will be super confusing to figure
    # out what happened if we don't check and it is an issue.
    return unless thesis_has_files?(thesis, results)

    if actual_checksums.map { |c| c.in?(expected_checksums) }.all?(true)
      Rails.logger.info("All DSpace checksums for thesis #{thesis.id} are valid")
    else
      update_status_and_log_bad_checksums(thesis, results, actual_checksums, expected_checksums)
    end
  end

  def update_status_and_log_bad_checksums(thesis, results, actual_checksums, expected_checksums)
    thesis.publication_status = 'Publication error'
    thesis.save

    Rails.logger.info("Thesis #{thesis.id} updated to status #{thesis.publication_status} due to invalid checksum.")
    Rails.logger.info("Thesis #{thesis.id} valid checksums #{expected_checksums}. dspace returned"\
                      " checksums #{actual_checksums}.")
    results[:errors] << "Thesis #{thesis.id} with handle #{thesis.dspace_handle} was published with non matching"\
                        " checksums. ETD checksums #{expected_checksums} dspace checksums #{actual_checksums}. This"\
                        ' requires immediate attention to either manually replace the problem file in DSpace or'\
                        ' delete the entire thesis from DSpace to ensure that nobody is able to download the broken'\
                        ' file.'
  end

  def thesis_has_files?(thesis, results)
    if thesis.files.count.zero?
      update_status_and_log_bad_files(thesis, results)
      false
    else
      true
    end
  end

  def update_status_and_log_bad_files(thesis, results)
    thesis.publication_status = 'Publication error'
    thesis.save

    Rails.logger.info("Thesis #{thesis.id} updated to status #{thesis.publication_status} due to inability to"\
                      ' validate checksums as no local files were attached to the ETD record to validate.')
    results[:errors] << "Thesis #{thesis.id} updated to status #{thesis.publication_status} due to inability to"\
                        ' validate checksums as no local files were attached to the record. This requires staff to'\
                        ' manually check the ETD record and DSpace record and take appropriate action.'
  end

  def collect_checksums(body)
    body['Bitstreams'].map { |b| b['BitstreamChecksum']['value'] }
  end

  def convert_checksums(thesis)
    thesis.files.map { |f| base64_to_hex(f.checksum) }
  end

  def base64_to_hex(base64_string)
    Base64.decode64(base64_string).each_byte.map { |b| format('%02x', b.to_i) }.join
  end

  def update_publication_status(thesis, body, results, status)
    case status
    when 'success'
      update_handle(thesis, body, results)
    when 'error'
      error = body['DSpaceResponse']
      thesis.publication_status = 'Publication error'
      thesis.save
      Rails.logger.info("Thesis #{thesis.id} updated to status #{thesis.publication_status}. Error from DSS: #{error}")
      results[:errors] << "Status updated to #{thesis.publication_status}. Error from DSS: #{error} \
                           (thesis #{thesis.id})"
    else
      thesis.publication_status = 'Publication error'
      thesis.save
      Rails.logger.info("Unknown status #{status}; Cannot continue")
      results[:errors] << "Unknown status #{status}; cannot continue (thesis #{thesis.id})"
    end
  end

  def poll_messages(queue_url, results)
    # https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/sqs-example-poll-messages.html
    # Poller retrieves messages until there are none left and deletes them as it goes
    poller = Aws::SQS::QueuePoller.new(queue_url)

    poller.poll(max_number_of_messages: MAX_MESSAGES.to_i, wait_time_seconds: WAIT_TIME_SECONDS.to_i,
                idle_timeout: IDLE_TIMEOUT.to_i) do |messages|
      messages.each do |msg|
        Rails.logger.info(msg)

        source = msg.message_attributes['SubmissionSource'].string_value
        validate_source(source, results)

        package_id = msg.message_attributes['PackageID'].string_value
        Rails.logger.info("PackageID: #{package_id}")
        thesis_id = package_id.split('_').last

        Rails.logger.info("Thesis ID: #{thesis_id}")
        begin
          thesis = Thesis.find(thesis_id.to_i)
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.info(e)
          results[:errors] << e.to_s
          next
        end

        body = JSON.parse(msg.body)
        Rails.logger.info('Determine status')
        status = body['ResultType']
        update_publication_status(thesis, body, results, status)
        validate_checksums(thesis, body, results) if thesis.publication_status == 'Published'
      end
    end
    Rails.logger.info("No messages returned from queue #{queue_url}")
  end

  # Skip and don't count if not ETD
  # https://aws.amazon.com/blogs/developer/polling-messages-from-a-amazon-sqs-queue/
  def validate_source(source, results)
    Rails.logger.info("SubmissionSource: #{source}")
    if source == 'ETD'
      results[:total] += 1
    else
      throw :skip_delete
    end
  end
end
