class JsonBatch
  def initialize(theses, json_filename)
    @theses = theses
    @json_filename = json_filename
  end

  def build
    json_file = Tempfile.new(@json_filename)
    write_json_file(json_file)
    json_file
  end

  private

  def write_json_file(json_file)
    theses_data = @theses.map do |thesis|
      JsonExporter.new(thesis).to_hash
    end

    json_output = { theses: theses_data }

    json_file.write(JSON.pretty_generate(json_output))
    json_file.rewind
  end
end
