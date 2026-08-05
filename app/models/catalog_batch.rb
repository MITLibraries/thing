# Generates a JSON metadata file from a collection of theses to add to the Libraries catalog.
#
# Produces a tempfile containing a JSON object with a 'theses' array, where each thesis is
# exported via CatalogExporter.
#
# Example:
#   batch = CatalogBatch.new(theses_array, 'export.json')
#   json_file = batch.build
#   File.write('export.json', File.read(json_file.path))
#   json_file.close!  # Clean up tempfile
class CatalogBatch
  def initialize(theses, json_filename)
    @theses = theses
    @json_filename = json_filename
  end

  # Builds and returns a Tempfile containing the JSON metadata export. The file is ready to read
  # (file pointer rewound after writing). Caller is responsible for closing the file.
  def build
    json_file = Tempfile.new(@json_filename)
    write_json_file(json_file)
    json_file
  end

  private

  def write_json_file(json_file)
    theses_data = @theses.map do |thesis|
      CatalogExporter.new(thesis).to_hash
    end

    json_output = { theses: theses_data }

    json_file.write(JSON.pretty_generate(json_output))
    json_file.rewind
  end
end
