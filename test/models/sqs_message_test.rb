require 'test_helper'

class SqsMessageTest < ActiveSupport::TestCase
  def setup
    @thesis = theses(:one)
    dss_friendly_thesis(@thesis)
  end

  def teardown
    @thesis.files.purge
    @thesis.dspace_metadata.purge
  end

  # Attaching thesis file and dspace_metadata so tests will pass.
  def dss_friendly_thesis(thesis)
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    thesis.files.first.description = 'My thesis'
    thesis.files.first.purpose = 'thesis_pdf'
    metadata_json = DspaceMetadata.new(thesis).serialize_dss_metadata
    thesis.dspace_metadata.attach(io: StringIO.new(metadata_json),
                                  filename: 'some_file.json')
    thesis.save
  end

  test 'files are mapped as expected' do
    files = SqsMessage.new(@thesis).map_files
    assert_equal Array, files.class
    assert_equal 1, files.length
    assert_equal %w[BitstreamName FileLocation BitstreamDescription], files.first.keys
    assert_equal 'a_pdf.pdf', files.first['BitstreamName']

    # Not checking the full URI here because ActiveStorage::SetCurrent doesn't generate URIs consistently.
    assert files.first['FileLocation'].ends_with?('a_pdf.pdf')

    # More thorough testing of bitstream description below.
    assert_equal 'Thesis PDF My thesis', files.first['BitstreamDescription']
  end

  test 'only thesis_pdf and supplementary files are published' do
    f = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    @thesis.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    @thesis.files.last.purpose = 'proquest_form'
    @thesis.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    @thesis.files.last.purpose = 'signature_page'
    @thesis.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    @thesis.files.last.purpose = 'thesis_source'
    @thesis.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    @thesis.files.last.purpose = 'thesis_supplementary_file'
    @thesis.save
    @thesis.reload
    assert_equal 5, @thesis.files.length
    assert_equal ['thesis_pdf', 'proquest_form', 'signature_page', 'thesis_source', 'thesis_supplementary_file'], @thesis.files.map{|f| f.purpose}
    files = SqsMessage.new(@thesis).map_files
    assert_equal 2, files.length
    assert_equal ['Thesis PDF My thesis', 'Supplementary file'], files.map{|f| f['BitstreamDescription']}
  end

  test 'returns correct bitstream description' do
    # File without description.
    @thesis.files.first.description = nil
    files = SqsMessage.new(@thesis).map_files
    assert_equal 'Thesis PDF', files.first['BitstreamDescription']

    # Different file purposes.
    f = @thesis.files.first
    f.purpose = 'thesis_source'
    assert_equal 'Thesis source', SqsMessage.new(@thesis).bitstream_description(f)

    @thesis.files.first.purpose = 'thesis_supplementary_file'
    assert_equal 'Supplementary file', SqsMessage.new(@thesis).bitstream_description(f)

    @thesis.files.first.purpose = 'proquest_form'
    assert_equal 'Proquest form', SqsMessage.new(@thesis).bitstream_description(f)

    @thesis.files.first.purpose = 'signature_page'
    assert_equal 'Signature page', SqsMessage.new(@thesis).bitstream_description(f)
  end

  test 'returns correct collection handle' do
    assert_equal 'Bachelor', @thesis.degrees.first.degree_type.name
    assert_equal '1721.1/777777', SqsMessage.new(@thesis).collection_handle

    engineer_degree = degrees(:four)
    @thesis.degrees << engineer_degree
    assert_equal 'Engineer', @thesis.degrees.second.degree_type.name
    assert_equal '1721.1/888888', SqsMessage.new(@thesis).collection_handle

    masters_degree = degrees(:three)
    @thesis.degrees.delete(engineer_degree)
    @thesis.degrees << masters_degree
    assert_equal 'Master', @thesis.degrees.second.degree_type.name
    assert_equal '1721.1/888888', SqsMessage.new(@thesis).collection_handle

    doctoral_degree = degrees(:two)
    @thesis.degrees << doctoral_degree
    assert_equal 'Doctoral', @thesis.degrees.third.degree_type.name
    assert_equal '1721.1/999999', SqsMessage.new(@thesis).collection_handle
  end

  test 'message_attributes is valid' do
    attributes = SqsMessage.new(@thesis).message_attributes
    package_id = { data_type: 'String', string_value: "etd_#{@thesis.id}" }
    output_queue = { data_type: 'String', string_value: 'etd-test-output' }
    submission_source = { data_type: 'String', string_value: 'ETD' }
    assert_equal %w[PackageID SubmissionSource OutputQueue], attributes.keys
    assert_equal package_id, attributes['PackageID']
    assert_equal submission_source, attributes['SubmissionSource']
    assert_equal output_queue, attributes['OutputQueue']
  end

  test 'message_body is valid' do
    body = SqsMessage.new(@thesis).message_body

    # Should be serialized.
    assert_equal String, body.class

    body_json = JSON.parse(body)

    # Checking for the presence of the Files key, but not checking the value here as we have a separate test for that.
    assert_equal %w[SubmissionSystem CollectionHandle MetadataLocation Files], body_json.keys
    assert_equal 'DSpace@MIT', body_json['SubmissionSystem']
    assert_equal '1721.1/777777', body_json['CollectionHandle']

    # Not checking the full URI here because ActiveStorage::SetCurrent doesn't generate URIs consistently.
    assert body_json['MetadataLocation'].ends_with?('some_file.json')
  end
end
