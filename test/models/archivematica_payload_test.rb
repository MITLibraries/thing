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
require 'test_helper'

class ArchivematicaPayloadTest < ActiveSupport::TestCase
  def setup
    @thesis = theses(:published)
    @payload = @thesis.archivematica_payloads.create!
  end

  test 'new payload has default preservation_status of unpreserved' do
    assert_equal 'unpreserved', @payload.preservation_status
  end

  test 'payload_json exists and contains valid JSON' do
    assert @payload.payload_json.present?

    json = @payload.payload_json
    assert json.is_a?(String) # Payload JSON should be a string

    parsed = JSON.parse(json)
    assert parsed.is_a?(Hash) # Parsed JSON should be a valid hash
  end

  test 'payload_json contains expected structure' do
    parsed = JSON.parse(@payload.payload_json)
    assert_equal parsed['action'], 'create-bagit-zip'
    assert parsed['challenge_secret']
    assert_not_nil parsed['verbose']
    assert parsed['input_files'].is_a?(Array)
    assert_equal ['md5'], parsed['checksums_to_generate']
    assert parsed['output_zip_s3_uri'].end_with?('.zip')
    assert parsed['compress_zip'].in?([true, false])
    # Check S3 URI format
    parsed['input_files'].each do |file|
      assert_match %r{^s3://#{ENV.fetch('AWS_S3_BUCKET', nil)}/}, file['uri']
    end
  end

  test 'input_files includes thesis files and metadata_csv' do
    parsed = JSON.parse(@payload.payload_json)
    thesis_files = @thesis.files.count
    assert_equal thesis_files + 1, parsed['input_files'].size
    assert_equal @thesis.files.first.filename.to_s, parsed['input_files'].first['filepath']
    assert_equal 'metadata/metadata.csv', parsed['input_files'].last['filepath']
  end

  test 'metadata_csv is attached and has correct filename/content type' do
    assert @payload.metadata_csv.attached?
    assert_equal 'metadata.csv', @payload.metadata_csv.filename.to_s
    assert_equal 'text/csv', @payload.metadata_csv.content_type
  end
end
