class DspacePublicationJob < ActiveJob::Base
  queue_as :default

  def perform(thesis, sqs_client)
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
    thesis.dspace_metadata.attach(io: StringIO.new(metadata_json),
                                  filename: "#{thesis.users.first.kerberos_id}_#{thesis.id}")
    message_body = SqsMessage.new(thesis).message_body
    message_attributes = SqsMessage.new(thesis).message_attributes
    sqs_client.send_message(
      queue_url: queue_url,
      message_body: message_body,
      message_attributes: message_attributes
    )
  end
end
