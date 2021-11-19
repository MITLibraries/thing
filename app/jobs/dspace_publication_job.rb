class DspacePublicationJob < ActiveJob::Base
  queue_as :default

  def setup(sqs_client)
    # note, we pass in the sqs_client to allow for easier stubbing even though it is inconvenient for non-test
    # purposes
    @queue_url = ENV.fetch('SQS_INPUT_QUEUE_URL')
    Rails.logger.info("Sending a message to queue #{@queue_url}...")

    # We allow the SQS client to be passed in to allow for easier mocking in tests. However, passing the client in via
    # the controller in dev/prod leads to errors. This is non-ideal, but it allow for us to use a client if one is
    # passed and create one if not.
    @sqs_client = sqs_client
    @sqs_client ||= Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'))

    # In development, all of these jobs will fail if this is not set in some way and this seems adequate.
    ActiveStorage::Current.host = ENV.fetch('CURRENT_HOST', 'localhost:5000') if Rails.env == 'development'
  end

  def perform(thesis, sqs_client = nil)
    setup(sqs_client)

    Rails.logger.debug('Setup complete')

    begin
      send_sqs_message(thesis)
      Rails.logger.info("Thesis #{thesis.id} is queued for publication")
      thesis.publication_status = 'Pending publication'
      thesis.save
      Rails.logger.info("Thesis #{thesis.id} is now Pending publication")
    rescue StandardError, Aws::Errors, Aws::SQS::Errors => e
      Rails.logger.error("Message not sent: #{e}")
      Sentry.capture_exception(e)
      thesis.publication_status = 'Publication error'
      thesis.save
    end
  end

  def send_sqs_message(thesis)
    Rails.logger.info("Preparing sqs message for Thesis #{thesis.id}")

    metadata_json = DspaceMetadata.new(thesis).serialize_dss_metadata

    # ActiveStorage will replace any existing metadata file with a new one by deleting the old one after creating the
    # new one because this is setup as a has one relationship
    if thesis.dspace_metadata.attached?
      Rails.logger.info("A metadata file was already attached for Thesis #{thesis.id}.")
      Rails.logger.info("Previous metadata file key: #{thesis.dspace_metadata.key}.")
    end

    thesis.dspace_metadata.attach(io: StringIO.new(metadata_json),
                                  filename: "#{thesis.users.first.kerberos_id}_#{thesis.id}.json",
                                  content_type: 'application/json')
    thesis.save
    Rails.logger.info("New metadata file key: #{thesis.dspace_metadata.key}.")

    Rails.logger.info("Metadata URL: #{thesis.dspace_metadata.blob.url}")

    message_body = SqsMessage.new(thesis).message_body
    Rails.logger.info("Message body: #{message_body}")

    message_attributes = SqsMessage.new(thesis).message_attributes
    Rails.logger.info("Message attributes: #{message_attributes}")

    @sqs_client.send_message(
      queue_url: @queue_url,
      message_body: message_body,
      message_attributes: message_attributes
    )
  end
end
