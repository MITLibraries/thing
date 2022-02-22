class MarcExportJob < ActiveJob::Base
  queue_as :default

  def perform(theses)
    marc_filename = "#{filename}.xml"
    zip_filename = "#{filename}.zip"
    begin
      zip_file = MarcBatch.new(theses, marc_filename, zip_filename).build
      BatchMailer.marc_batch_email(zip_filename, zip_file, theses).deliver_now
    ensure
      zip_file&.close
    end
  end

  private

  def filename
    "marc_#{DateTime.now.utc.strftime('%y%m%d_%H_%M')}"
  end
end
