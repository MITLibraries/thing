class DspacePublicationPrepJob < ActiveJob::Base
  queue_as :default

  def perform(theses)
    Rails.logger.info("Preparing to publish #{theses.count} theses")

    theses.each do |thesis|
      DspacePublicationJob.perform_later(thesis)
    end
  end
end
