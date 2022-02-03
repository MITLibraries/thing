class PreservationSubmissionJob < ActiveJob::Base
  queue_as :default

  def perform(thesis)
    Rails.logger.info("Thesis #{thesis.id} is now being prepared for preservation")
    sip = thesis.submission_information_packages.create
    preserve_sip(sip)
    Rails.logger.info("Thesis #{thesis.id} has been sent to preservation")
  rescue StandardError, Aws::Errors => e
    Rails.logger.info("Thesis #{thesis.id} could not be preserved: #{e}")
    sip.preservation_status = 'error'
    sip.save
  end

  private

  def preserve_sip(sip)
    SubmissionInformationPackageZipper.new(sip)
    sip.preservation_status = 'preserved'
    sip.preserved_at = DateTime.now
    sip.save
  end
end
