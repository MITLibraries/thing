# Generates a JSON metadata file from a collection of theses to add to the Libraries catalog.
#
# Produces a tempfile containing a JSON object with a 'theses' array, where each thesis is
# exported via CatalogExporter.
#
# Example:
#   batch = CatalogBatch.new(theses_array, 'export.json')
#   catalog_file = batch.build
#   File.write('export.json', File.read(catalog_file.path))
#   catalog_file.close!  # Clean up tempfile
class CatalogBatch
  def initialize(theses, filename)
    @theses = theses
    @filename = filename
  end

  # Builds and returns a Tempfile containing the JSON metadata export. The file is ready to read
  # (file pointer rewound after writing). Caller is responsible for closing the file.
  def build
    catalog_file = Tempfile.new(@filename)
    write_catalog_file(catalog_file)
    catalog_file
  end

  private

  def write_catalog_file(catalog_file)
    theses_data = @theses.map do |thesis|
      CatalogExporter.new(thesis).to_hash
    end

    json_output = { theses: theses_data }

    catalog_file.write(JSON.pretty_generate(json_output))
    catalog_file.rewind
  end
end
