# All metadata about the thesis must be in a single CSV file with a column for each metadata field and a row for each
# file associated with the thesis.
# Thesis-level metadata  (title, abstract, author, etc.) should be in the row for the thesis PDF file.
#
# Repeated fields must have a column for each instance of the field in the metadata.
#
# Note: If a rights field includes the copyright character, it must be UTF-8 encoded in the CSV file for Archivematica
# to parse it correctly.
#
# Other files included in the CSV should have blank values for any fields not directly related to the file -- fields
# associated with the thesis such as title, abstract, author should be blank, but fields specific to the file such as
# BitstreamChecksumValue should have the value present in the row for that file
class ArchivematicaMetadata
  require 'csv'

  def initialize(thesis)
    @thesis = thesis
    @csv_hash = {
      headers: []
    }
    @thesis.files.each_with_index do |_f, i|
      @csv_hash["f#{i}".to_sym] = []
    end
    non_repeating
    dc_terms_is_part_of
    dc_contributor_author
    dc_identifier_orcid
    dc_contributor_advisor
    degree_fields
    dc_contributor_department
    rights_fields
  end

  def rights_fields
    @csv_hash[:headers] << 'dc.rights'
    @csv_hash[:headers] << 'dc.rights'
    @csv_hash[:headers] << 'dc.rights.uri'
    @thesis.files.each_with_index do |file, i|
      if file.purpose == 'thesis_pdf'
        if @thesis.copyright.holder != 'Author' # copyright holder is anyone but author
          @csv_hash["f#{i}".to_sym] << @thesis.copyright.statement_dspace
          @csv_hash["f#{i}".to_sym] << "Copyright #{@thesis.copyright.holder}"
          @csv_hash["f#{i}".to_sym] << @thesis.copyright.url if @thesis.copyright.url
        elsif @thesis.license # author holds copyright and provides a license
          @csv_hash["f#{i}".to_sym] << @thesis.license.map_license_type
          @csv_hash["f#{i}".to_sym] << 'Copyright retained by author(s)'
          @csv_hash["f#{i}".to_sym] << @thesis.license.url if @thesis.license.url
        else
          @csv_hash["f#{i}".to_sym] << @thesis.copyright.statement_dspace
          @csv_hash["f#{i}".to_sym] << 'Copyright retained by author(s)'
          @csv_hash["f#{i}".to_sym] << @thesis.copyright.url if @thesis.copyright.url
        end
      else
        @csv_hash["f#{i}".to_sym] << ''
        @csv_hash["f#{i}".to_sym] << ''
        @csv_hash["f#{i}".to_sym] << ''
      end
    end
  end

  def dc_contributor_department
    @thesis.departments.each do |dept|
      @csv_hash[:headers] << 'dc.contributor.department'
      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       dept.name_dspace
                                     else
                                       ''
                                     end
      end
    end
  end

  def degree_fields
    @thesis.degrees.each do |degree|
      @csv_hash[:headers] << 'dc.description.degree'
      @csv_hash[:headers] << 'thesis.degree.name'
      @csv_hash[:headers] << 'mit.thesis.degree'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       degree.abbreviation
                                     else
                                       ''
                                     end
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       degree.name_dspace
                                     else
                                       ''
                                     end
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       degree.degree_type&.name.to_s
                                     else
                                       ''
                                     end
      end
    end
  end

  def non_repeating
    @csv_hash[:headers] << ['filename', 'Level_of_DPCommitment', 'dc.title', 'dc.date.issued', 'dc.date.submitted',
                            'dc.type', 'dc.description.abstract', 'dc.identifier.uri', 'BitstreamDescription',
                            'BitstreamChecksumValue', 'BitstreamChecksumAlgorithm', 'dc.publisher']
    @thesis.files.each_with_index do |f, i|
      @csv_hash["f#{i}".to_sym] << "data/#{f.blob.filename}"
      @csv_hash["f#{i}".to_sym] << level_of_commitment(f)
      @csv_hash["f#{i}".to_sym] << dc_title(f)
      @csv_hash["f#{i}".to_sym] << dc_date_issued(f)
      @csv_hash["f#{i}".to_sym] << dc_date_submitted(f)
      @csv_hash["f#{i}".to_sym] << dc_type(f)
      @csv_hash["f#{i}".to_sym] << dc_description_abstract(f)
      @csv_hash["f#{i}".to_sym] << dc_identifier_uri(f)
      @csv_hash["f#{i}".to_sym] << bitstream_description(f)
      @csv_hash["f#{i}".to_sym] << bitstream_checksum_value(f)
      @csv_hash["f#{i}".to_sym] << 'MD5'
      @csv_hash["f#{i}".to_sym] << dc_publisher(f)
    end
  end

  def level_of_commitment(file)
    return '' unless file.purpose == 'thesis_pdf'

    'Level 3'
  end

  def dc_title(file)
    return '' unless file.purpose == 'thesis_pdf'

    @thesis.title
  end

  def dc_date_issued(file)
    return '' unless file.purpose == 'thesis_pdf'

    @thesis.grad_date.strftime('%Y-%m')
  end

  def dc_date_submitted(file)
    return '' unless file.purpose == 'thesis_pdf'

    file.blob.created_at
  end

  def dc_description_abstract(file)
    return '' unless file.purpose == 'thesis_pdf'

    @thesis.abstract
  end

  def dc_identifier_uri(file)
    return '' unless file.purpose == 'thesis_pdf'

    @thesis.dspace_handle.to_s
  end

  def bitstream_description(file)
    # NOTE: these file purposes are repeated from sqs_message.rb and should be moved to a common location
    file_purposes = { 'thesis_pdf' => 'Thesis PDF', 'thesis_source' => 'Thesis source', 'thesis_supplementary_file' =>
                      'Supplementary file', 'proquest_form' => 'Proquest form', 'signature_page' => 'Signature page' }
    file_purposes[file.purpose]
  end

  def bitstream_checksum_value(file)
    base64_to_hex(file.checksum)
  end

  # Duplicated logic from dspace_publication_results_job.rb and should be considered form shared location
  def base64_to_hex(base64_string)
    Base64.decode64(base64_string).each_byte.map { |b| format('%02x', b.to_i) }.join
  end

  # repeatable, take care to increment all file rows but only include details in thesis_pdf
  # There is more logic to implement for this. We only preface dept code with "Course_" if it is a numeric code
  # and we pad to two digits if it is a numeric code.
  def dc_terms_is_part_of
    @thesis.departments.each do |dept|
      @csv_hash[:headers] << 'dc.terms.isPartOf'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       "AIC#Course_#{dept.code_dw}_theses"
                                     else
                                       ''
                                     end
      end
    end
  end

  # repeatable, take care to increment all file rows but only include details in thesis_pdf
  def dc_contributor_author
    @thesis.authors.each do |author|
      @csv_hash[:headers] << 'dc.contributor.author'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       author.user.preferred_name
                                     else
                                       ''
                                     end
      end
    end
  end

  # repeatable, take care to increment all file rows but only include details in thesis_pdf
  def dc_identifier_orcid
    @thesis.authors.each do |author|
      @csv_hash[:headers] << 'dc.identifier.orcid'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       author.user.orcid.to_s
                                     else
                                       ''
                                     end
      end
    end
  end

  def dc_contributor_advisor
    @thesis.advisors.each do |advisor|
      @csv_hash[:headers] << 'dc.contributor.advisor'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << if file.purpose == 'thesis_pdf'
                                       advisor.name
                                     else
                                       ''
                                     end
      end
    end
  end

  def dc_publisher(file)
    return '' unless file.purpose == 'thesis_pdf'

    'Massachusetts Institute of Technology'
  end

  def dc_type(file)
    return '' unless file.purpose == 'thesis_pdf'

    'Thesis'
  end

  def to_csv
    CSV.generate do |csv|
      @csv_hash.each do |row|
        csv << row
      end
    end

    # uncomment to debug by writing to a file
    CSV.open('tmp/file.csv', 'wb') do |csv|
      @csv_hash.each do |row|
        csv << row[1].flatten
      end
    end
  end
end
