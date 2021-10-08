class DspacePublicationJob < ActiveJob::Base
  queue_as :default

  def perform(thesis, sqs_client)
    # note, we pass in the sqs_client to allow for easier stubbing even though it is inconvenient for non-test
    # purposes
    queue_url = ENV.fetch('SQS_INPUT_QUEUE_URL')

    Rails.logger.info("Sending a message to queue #{queue_url}...")

    begin
      send_sqs_message(thesis, queue_url, sqs_client)
      Rails.logger.info("Thesis #{thesis.id} is queued for publication")
      thesis.publication_status = 'Pending publication'
      thesis.save
      Rails.logger.info("Thesis #{thesis.id} is now Pending publication")
    rescue StandardError, Aws::Errors, Aws::SQS::Errors => e
      Rails.logger.info("Message not sent: #{e}")
      # Update thesis record publication status is errored? (Tbd what this status is)
    end
  end

  def send_sqs_message(thesis, queue_url, sqs_client)
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

    sqs_client.send_message(
      queue_url: queue_url,
      message_body: message_body,
      message_attributes: message_attributes
    )
  end
end
