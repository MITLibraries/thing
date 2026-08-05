class MarcExportJob < ActiveJob::Base
  queue_as :default

  def perform(theses)
    marc_filename = "#{filename}.mrc"
    zip_filename = "#{filename}.zip"
    json_filename = "#{filename}.json"

    begin
      marc_zip_file = MarcBatch.new(theses, marc_filename, zip_filename).build
      json_file = CatalogBatch.new(theses, json_filename).build
      BatchMailer.marc_batch_email(zip_filename, marc_zip_file, json_filename, json_file, theses).deliver_now
    ensure
      marc_zip_file&.close!
      json_file&.close!
    end
  end

  private

  def filename
    "marc_#{DateTime.now.utc.strftime('%y%m%d_%H_%M')}"
  end
end
