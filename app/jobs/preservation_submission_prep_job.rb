class PreservationSubmissionPrepJob < ActiveJob::Base
  queue_as :default

  def perform(theses)
    Rails.logger.info("Preparing to send #{theses.count} theses to preservation")

    theses.each do |thesis|
      PreservationSubmissionJob.perform_later(thesis)
    end
  end
end
