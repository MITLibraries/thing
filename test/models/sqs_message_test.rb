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
    assert_equal(%w[thesis_pdf proquest_form signature_page thesis_source thesis_supplementary_file], @thesis.files.map do |f|
      f.purpose
    end)
    files = SqsMessage.new(@thesis).map_files
    assert_equal 2, files.length
    assert_equal(['Thesis PDF My thesis', 'Supplementary file'], files.map { |f| f['BitstreamDescription'] })
  end

  test 'thesis_pdf are attached before supplementary files' do
    f = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    @thesis.files.detach
    @thesis.files.attach(io: File.open(f), filename: 'supplemental_file.pdf')
    @thesis.files.last.purpose = 'thesis_supplementary_file'
    @thesis.files.attach(io: File.open(f), filename: 'thesis_pdf.pdf')
    @thesis.files.last.purpose = 'thesis_pdf'
    @thesis.files.attach(io: File.open(f), filename: 'flexible_pdf.pdf')
    @thesis.files.last.purpose = 'thesis_supplementary_file'
    @thesis.save
    @thesis.reload
    assert_equal(%w[thesis_supplementary_file thesis_pdf thesis_supplementary_file], @thesis.files.map do |f|
      f.purpose
    end)
    files = SqsMessage.new(@thesis).map_files
    assert_equal(['Thesis PDF', 'Supplementary file', 'Supplementary file'], files.map do |f|
      f['BitstreamDescription']
    end)
    assert_equal(['thesis_pdf.pdf', 'supplemental_file.pdf', 'flexible_pdf.pdf'], files.map { |f| f['BitstreamName'] })
    # Swapping file purposes will result in the same set of files being sorted into a different order. This is meant to
    # demonstrate confidence that alphabetical order is not part of the logic being used - the thesis pdf comes first,
    # followed by supplemental files in the order they were attached.
    #
    # On a console you can apply the filter-and-sort logic found in the map_files method, reversing the array order
    # but that cannot AFAICT be done in a unit test easily.
    @thesis.files.last.purpose = 'thesis_pdf' # last-attached "flexible_pdf" should now be sorted first
    @thesis.files.second.purpose = 'thesis_supplementary_file' # second-attached "thesis_pdf" should now be sorted last
    files = SqsMessage.new(@thesis).map_files
    assert_equal(['Thesis PDF', 'Supplementary file', 'Supplementary file'], files.map do |f|
      f['BitstreamDescription']
    end)
    assert_equal(['flexible_pdf.pdf', 'supplemental_file.pdf', 'thesis_pdf.pdf'], files.map { |f| f['BitstreamName'] })
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

  test 'sanitize_filename_for_dspace normalizes decomposed unicode to precomposed' do
    # Decomposed form: í as i (U+0069) + combining acute accent (U+0301)
    decomposed = 'saldías_belen_thesis.pdf' # Will be NFD if created on macOS
    sqs = SqsMessage.new(@thesis)
    sanitized = sqs.send(:sanitize_filename_for_dspace, decomposed)

    # Should normalize to precomposed form
    assert_equal 'saldías_belen_thesis.pdf'.unicode_normalize(:nfc), sanitized
  end

  test 'sanitize_filename_for_dspace removes zero-width spaces' do
    # Contains U+200B (zero-width space)
    filename_with_zwsp = "Liang-thesis\u200b.pdf"
    sqs = SqsMessage.new(@thesis)
    sanitized = sqs.send(:sanitize_filename_for_dspace, filename_with_zwsp)
    assert_equal 'Liang-thesis.pdf', sanitized
  end

  test 'sanitize_filename_for_dspace replaces en-dashes with hyphens' do
    # U+2013 is en-dash
    filename_with_endash = "Siddiqui\u2013sameed-thesis.pdf"
    sqs = SqsMessage.new(@thesis)
    sanitized = sqs.send(:sanitize_filename_for_dspace, filename_with_endash)
    assert_equal 'Siddiqui-sameed-thesis.pdf', sanitized
  end

  test 'sanitize_filename_for_dspace preserves safe precomposed accented characters' do
    # These are precomposed forms that DSpace accepts
    safe_filenames = [
      'garcía_thesis.pdf',      # U+00ED precomposed í
      'strømstad_thesis.pdf',   # U+00F8 precomposed ø
      'MillánBarea_thesis.pdf'  # U+00E1 precomposed á
    ]
    sqs = SqsMessage.new(@thesis)
    safe_filenames.each do |filename|
      sanitized = sqs.send(:sanitize_filename_for_dspace, filename)
      assert_equal filename, sanitized, "Safe character filename was modified: #{filename}"
    end
  end

  test 'sanitize_filename_for_dspace applied to map_files output' do
    # Test end-to-end: verify sanitized filenames appear in map_files output
    f = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    @thesis.files.detach

    # Attach file with decomposed unicode (i + combining acute accent, not precomposed í)
    decomposed_filename = "sald\u0069\u0301as_thesis.pdf"  # i (U+0069) + combining acute (U+0301)
    @thesis.files.attach(io: File.open(f), filename: decomposed_filename)
    @thesis.files.last.purpose = 'thesis_pdf'
    @thesis.files.last.description = 'My thesis'
    @thesis.save
    @thesis.reload

    files = SqsMessage.new(@thesis).map_files

    # Filename should be normalized (decomposed í converted to precomposed)
    assert_equal decomposed_filename.unicode_normalize(:nfc), files.first['BitstreamName']
  end
end
