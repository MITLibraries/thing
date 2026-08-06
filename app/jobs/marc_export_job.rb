class MarcExportJob < ActiveJob::Base
  queue_as :default

  def perform(theses)
    marc_filename = "#{filename}.mrc"
    zip_filename = "#{filename}.zip"
    catalog_filename = "#{filename}.json"

    begin
      marc_zip_file = MarcBatch.new(theses, marc_filename, zip_filename).build
      catalog_file = CatalogBatch.new(theses, catalog_filename).build
      BatchMailer.marc_batch_email(zip_filename, marc_zip_file, catalog_filename, catalog_file, theses).deliver_now
    ensure
      marc_zip_file&.close!
      catalog_file&.close!
    end
  end

  private

  def filename
    "marc_#{DateTime.now.utc.strftime('%y%m%d_%H_%M')}"
  end
end
