require 'zip'

class MarcBatch
  def initialize(theses, marc_filename, zip_filename)
    @theses = theses
    @marc_filename = marc_filename
    @zip_filename = zip_filename
  end

  def build
    marc_file = Tempfile.new(@marc_filename)
    zip_file = Tempfile.new(@zip_filename)
    create_marc_file(marc_file)
    zip_marc_file(zip_file, marc_file)
    zip_file
  end

  private

  def create_marc_file(marc_file)
    writer = MARC::Writer.new(marc_file.path)
    @theses.each do |thesis|
      record = Marc.new(thesis)
      writer.write(record.record)
    end
    writer.close
  end

  def zip_marc_file(zip_file, marc_file)
    Zip::File.open(zip_file.path, create: true) do |zip|
      zip.add(@marc_filename, marc_file.path)
    end
    marc_file.close
  end
end
