# == Schema Information
#
# Table name: submission_information_packages
#
#  id                  :integer          not null, primary key
#  preserved_at        :datetime
#  preservation_status :integer          default("unpreserved"), not null
#  bag_declaration     :string
#  bag_name            :string
#  manifest            :text
#  metadata            :text
#  thesis_id           :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

# This model is no longer used, but it is retained for historical purposes and to preserve existing
# data. Its functionality has been replaced by the ArchivematicaPayload model, which is used in the
# current preservation workflow.
#
# Creates the structure for an individual thesis to be preserved in Archivematica according to the BagIt spec:
# https://datatracker.ietf.org/doc/html/rfc8493.
#
# Note: instances of this class are invalid without an associated thesis that has a DSpace handle, a copyright, and
# at least one attached file with no duplicate filenames.
class SubmissionInformationPackage < ApplicationRecord
  include Baggable
  include Checksums

  has_paper_trail
  belongs_to :thesis
  has_one_attached :bag

  validates :baggable?, presence: true

  before_create :set_metadata, :set_bag_declaration, :set_manifest, :set_bag_name

  enum preservation_status: %i[unpreserved preserved]

  def data
    file_locations = {}
    thesis.files.map { |f| file_locations["data/#{f.filename}"] = f.blob }

    file_locations['data/metadata/metadata.csv'] = metadata

    file_locations
  end

  private

  def baggable?
    baggable_thesis?(thesis)
  end

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
    new_manifest << "#{ArchivematicaMetadata.new(thesis).md5} data/metadata/metadata.csv"

    self.manifest = new_manifest.join("\n")
  end

  # The bag_name has to be unique due to our using it as the basis of an ActiveStorage key. Using a UUID
  # was not preferred as the target system of these bags adds it's own UUID to the file when it arrives there
  # so the filename was unwieldy with two UUIDs embedded in it so we simply increment integers.
  def set_bag_name
    safe_handle = thesis.dspace_handle.gsub('/', '_')
    self.bag_name = "#{safe_handle}-thesis-#{thesis.submission_information_packages.count + 1}"
  end
end
