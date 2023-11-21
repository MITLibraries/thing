class PreservationSubmissionJob < ActiveJob::Base
  queue_as :default

  def perform(theses)
    Rails.logger.info("Preparing to send #{theses.count} theses to preservation")
    results = { total: theses.count, processed: 0, errors: [] }
    theses.each do |thesis|
      Rails.logger.info("Thesis #{thesis.id} is now being prepared for preservation")
      sip = thesis.submission_information_packages.create!
      preserve_sip(sip)
      Rails.logger.info("Thesis #{thesis.id} has been sent to preservation")
      results[:processed] += 1
    rescue StandardError, Aws::Errors => e
      preservation_error = "Thesis #{thesis.id} could not be preserved: #{e}"
      Rails.logger.info(preservation_error)
      results[:errors] << preservation_error
    end
    ReportMailer.preservation_results_email(results).deliver_now if results[:total].positive?
  end

  private

  def preserve_sip(sip)
    SubmissionInformationPackageZipper.new(sip)
    sip.preservation_status = 'preserved'
    sip.preserved_at = DateTime.now
    sip.save
  end
end
