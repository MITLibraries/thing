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

    ReportMailer.publication_results_email(results).deliver_now if results[:processed].positive?
    results
  end

  private

  def update_handle(thesis, body, results)
    handle = body['ItemHandle']
    if handle
      thesis.dspace_handle = handle
      thesis.publication_status = 'Published'
      thesis.save
      Rails.logger.info("Thesis #{thesis.id} updated to status #{thesis.publication_status} with handle #{thesis.dspace_handle}")
      results[:processed] += 1
    else
      thesis.publication_status = 'Publication error'
      thesis.save
      Rails.logger.info("Handle not provided #{body}; Cannot continue")
      results[:errors] << "Handle not provided; cannot continue (thesis #{thesis.id})"
    end
  end

  def update_publication_status(thesis, body, results, status)
    case status
    when 'success'
      update_handle(thesis, body, results)
    when 'error'
      error = body['ExceptionMessage']
      thesis.publication_status = 'Publication error'
      thesis.save
      Rails.logger.info("Thesis #{thesis.id} updated to status #{thesis.publication_status}. Error from DSS: #{error}")
      results[:errors] << "#{error} (thesis #{thesis.id})"
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
