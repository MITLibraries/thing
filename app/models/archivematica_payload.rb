# == Schema Information
#
# Table name: archivematica_payloads
#
#  id                  :integer          not null, primary key
#  preservation_status :integer          default("unpreserved"), not null
#  payload_json        :text
#  preserved_at        :datetime
#  thesis_id           :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# This class assembles a payload to send to the Archival Packaging Tool (APT), which then creates a bag for
# preservation. It includes the thesis files, metadata, and checksums. The payload is then serialized to JSON
# for transmission.
#
# Instances of this class are invalid without an associated thesis that has a DSpace handle, a copyright, and
# at least one attached file with no duplicate filenames.
#
# There is some intentional duplication between this and the SubmissionInformationPackage model. The
# SubmissionInformationPackage is the legacy model that was used to create the bag, but it is not
# used in the current APT workflow. We are retaining it for historical purposes.
class ArchivematicaPayload < ApplicationRecord
  include Checksums
  include Baggable

  has_paper_trail
  belongs_to :thesis
  has_one_attached :metadata_csv

  validates :baggable?, presence: true

  before_create :set_metadata_csv, :set_payload_json

  enum preservation_status: %i[unpreserved preserved]

  private

  # compress_zip is cast to a boolean to override the string value from ENV. APT strictly requires
  # a boolean for this field.
  def build_payload
    {
      action: 'create-bagit-zip',
      challenge_secret: ENV.fetch('APT_CHALLENGE_SECRET', nil),
      verbose: ActiveModel::Type::Boolean.new.cast(ENV.fetch('APT_VERBOSE', false)),
      input_files: build_input_files,
      checksums_to_generate: ENV.fetch('APT_CHECKSUMS_TO_GENERATE', ['md5']),
      output_zip_s3_uri: bag_output_uri,
      compress_zip: ActiveModel::Type::Boolean.new.cast(ENV.fetch('APT_COMPRESS_ZIP', true))
    }
  end

  # Build input_files array from thesis files and attached metadata CSV
  def build_input_files
    files = thesis.files.map { |file| build_file_entry(file) }
    files << build_file_entry(metadata_csv) # Metadata CSV is the only file that is generated in this model
    files
  end

  # Build a file entry for each file, including the metadata CSV.
  def build_file_entry(file)
    {
      uri: ["s3://#{ENV.fetch('AWS_S3_BUCKET')}", file.blob.key].join('/'),
      filepath: set_filepath(file),
      checksums: {
        md5: base64_to_hex(file.blob.checksum)
      }
    }
  end

  def set_filepath(file)
    file == metadata_csv ? 'metadata/metadata.csv' : file.filename.to_s
  end

  # The bag_name has to be unique due to our using it as the basis of an ActiveStorage key. Using a UUID
  # was not preferred as the target system of these bags adds it's own UUID to the file when it arrives there
  # so the filename was unwieldy with two UUIDs embedded in it so we simply increment integers.
  def bag_name
    safe_handle = thesis.dspace_handle.gsub('/', '_')
    "#{safe_handle}-thesis-#{thesis.submission_information_packages.count + 1}"
  end

  # The bag_output_uri key is constructed to match the expected format for Archivematica.
  def bag_output_uri
    key = "etdsip-apt/#{thesis.graduation_year}/#{thesis.graduation_month}-#{thesis.accession_number}/#{bag_name}.zip"
    [ENV.fetch('APT_S3_BUCKET'), key].join('/')
  end

  def baggable?
    baggable_thesis?(thesis)
  end

  def set_metadata_csv
    csv_data = ArchivematicaMetadata.new(thesis).to_csv
    metadata_csv.attach(io: StringIO.new(csv_data), filename: 'metadata.csv', content_type: 'text/csv')
  end

  def set_payload_json
    self.payload_json = build_payload.to_json
  end
end
