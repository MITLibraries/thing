# Creates the structure for an individual thesis to be preserved in Archivematica according to the BagIt spec:
# https://datatracker.ietf.org/doc/html/rfc8493.
#
# Note: instances of this class are invalid without an associated thesis that has a DSpace handle, a copyright, and
# at least one attached file with no duplicate filenames.
class SubmissionInformationPackage < ApplicationRecord
  include Checksums

  has_paper_trail
  belongs_to :thesis

  validates :baggable_thesis?, presence: true

  before_create :set_metadata, :set_bag_declaration, :set_manifest, :set_bag_name

  def data
    file_locations = {}
    thesis.files.map { |f| file_locations["data/#{f.filename}"] = f.blob }

    file_locations['data/metadata.csv'] = metadata

    file_locations
  end

  private

  def set_metadata
    self.metadata = ArchivematicaMetadata.new(thesis).to_csv
  end

  def set_bag_declaration
    self.bag_declaration = "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8"
  end

  def set_manifest
    # thesis files
    new_manifest = thesis.files.map { |f| "#{base64_to_hex(f.checksum)} data/#{f.filename}" }

    # metadata file
    new_manifest << "#{ArchivematicaMetadata.new(thesis).md5} data/metadata.csv"

    self.manifest = new_manifest.join("\n")
  end

  def set_bag_name
    safe_handle = thesis.dspace_handle.gsub('/', '_')
    self.bag_name = "#{safe_handle}-thesis"
  end

  # Before we try to bag anything, we need to check if it meets a few conditions. All published theses should have
  # at least one file attached, no duplicate filenames, and a handle pointing to its DSpace record.
  def baggable_thesis?
    return unless thesis

    thesis.files.any? && thesis.dspace_handle.present? && !duplicate_filenames? && thesis.copyright.present?
  end

  def duplicate_filenames?
    filenames = thesis.files.map { |f| f.filename.to_s }
    filenames.select { |f| filenames.count(f) > 1 }.uniq.any?
  end
end
