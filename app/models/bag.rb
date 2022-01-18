# Creates the structure for an individual thesis to be preserved in Archivematica according to the BagIt spec:
# https://datatracker.ietf.org/doc/html/rfc8493.
class Bag
  include Checksums

  def initialize(thesis)
    @thesis = thesis
    raise 'This thesis is not baggable' unless baggable?
  end

  def data
    file_locations = {}
    @thesis.files.map { |f| file_locations["data/#{f.filename}"] = f.blob }

    file_locations['data/metadata.csv'] = ArchivematicaMetadata.new(@thesis).to_csv

    file_locations
  end

  def bag_declaration
    "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8"
  end

  def manifest
    # thesis files
    manifest = @thesis.files.map { |f| "#{base64_to_hex(f.checksum)} data/#{f.filename}" }

    # metadata file
    manifest << "#{ArchivematicaMetadata.new(@thesis).md5} data/metadata.csv"

    manifest.join("\n")
  end

  def bag_name
    safe_handle = @thesis.dspace_handle.gsub('/', '_')
    "#{safe_handle}-thesis"
  end

  # Before we try to bag anything, we need to check if it meets a few conditions. All published theses should have
  # at least one file attached, no duplicate filenames, and a handle pointing to its DSpace record.
  def baggable?
    @thesis.files.any? && @thesis.dspace_handle.present? && !duplicate_filenames? && @thesis.copyright.present?
  end

  def duplicate_filenames?
    filenames = @thesis.files.map { |f| f.filename.to_s }
    filenames.select { |f| filenames.count(f) > 1 }.uniq.any?
  end
end
