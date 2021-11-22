# Generates an SQS message containing the data needed for the DSpace Submission Service (DSS) to publish a Thesis object
# to DSpace@MIT. This class assumes that the input Thesis is ready for publication and has an attached DspaceMetadata
# object.

class SqsMessage
  def initialize(thesis)
    @thesis = thesis
    @package_id = "etd_#{@thesis.id}"
    @metadata_uri = thesis.dspace_metadata.blob.url(expires_in: 604800)
  end

  def message_attributes
    attributes = {}
    attributes['PackageID'] = { data_type: 'String', string_value: @package_id }
    attributes['SubmissionSource'] = { data_type: 'String', string_value: 'ETD' }
    attributes['OutputQueue'] = { data_type: 'String', string_value: ENV['SQS_OUTPUT_QUEUE_NAME'].to_s }
    attributes
  end

  def message_body
    body = {}
    body['SubmissionSystem'] = 'DSpace@MIT'
    body['CollectionHandle'] = collection_handle
    body['MetadataLocation'] = @metadata_uri
    body['Files'] = map_files

    # SQS requires the MessageBody to be a string
    body.to_json
  end

  def map_files
    @thesis.files.select { |f| %w[thesis_pdf thesis_supplementary_file].include? f.purpose }.map do |f|
      {
        'BitstreamName' => f.blob.filename.to_s,
        'FileLocation' => f.blob.url(expires_in: 604800),
        'BitstreamDescription' => bitstream_description(f)
      }
    end
  end

  # There is a handle for all MIT theses, but there are also subcollections for doctoral, graduate, and undergraduate
  # theses. Here we're trying to get the most specific handle possible.
  def collection_handle
    if @thesis.degrees.any? { |d| d.degree_type.name == 'Doctoral' }
      ENV.fetch('DSPACE_DOCTORAL_HANDLE')
    elsif @thesis.degrees.any? { |d| d.degree_type.name == 'Master' || d.degree_type.name == 'Engineer' }
      ENV.fetch('DSPACE_GRADUATE_HANDLE')
    else
      ENV.fetch('DSPACE_UNDERGRADUATE_HANDLE')
    end
  end

  def bitstream_description(file)
    file_purposes = { 'thesis_pdf' => 'Thesis PDF', 'thesis_source' => 'Thesis source', 'thesis_supplementary_file' =>
                      'Supplementary file', 'proquest_form' => 'Proquest form', 'signature_page' => 'Signature page' }
    translated_purpose = file_purposes[file.purpose]
    "#{translated_purpose} #{file.description}".strip
  end
end
