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
  require 'digest'

  include Checksums

  def initialize(thesis)
    @thesis = thesis
    @csv_hash = {
      headers: []
    }
    @thesis.files.each_with_index do |_f, i|
      @csv_hash["f#{i}".to_sym] = []
    end
    non_repeating
    static
    repeating
    @csv_hash[:headers].flatten!
  end

  def to_csv(debug: false)
    if debug
      CSV.open("tmp/thesis_#{@thesis.id}_archivematica.csv", 'wb') do |csv|
        @csv_hash.each do |row|
          csv << row[1].flatten
        end
      end
    end

    CSV.generate do |csv|
      @csv_hash.each do |row|
        csv << row[1].flatten
      end
    end
  end

  def md5
    Digest::MD5.hexdigest(to_csv(debug: false))
  end

  private

  # These fields contain static values
  def static
    @csv_hash[:headers] << ['BitstreamChecksumAlgorithm', 'dc.publisher']
    @thesis.files.each_with_index do |f, i|
      @csv_hash["f#{i}".to_sym] << 'MD5'
      @csv_hash["f#{i}".to_sym] << dc_publisher(f)
    end
  end

  # These fields are repeatable and need extra care
  def repeating
    dc_terms_is_part_of
    dc_contributor_author
    dc_identifier_orcid
    dc_contributor_advisor
    degree_fields
    dc_contributor_department
    rights_fields
  end

  # Convenience method that accepts a file and the value to use if the file is the thesis pdf
  def thesis_pdf_checker(file, value_if_thesis_pdf)
    return '' unless file.purpose == 'thesis_pdf'

    value_if_thesis_pdf
  end

  def rights_fields
    @csv_hash[:headers] << 'dc.rights'
    @csv_hash[:headers] << 'dc.rights'
    @csv_hash[:headers] << 'dc.rights.uri'
    @thesis.files.each_with_index do |file, i|
      if @thesis.copyright.holder != 'Author' # copyright holder is anyone but author
        rights_other(file, i)
      elsif @thesis.license # author holds copyright and provides a license
        rights_author_license(file, i)
      else
        rights_author(file, i)
      end
    end
  end

  def rights_other(file, file_number)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, @thesis.copyright.statement_dspace)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, "Copyright #{@thesis.copyright.holder}")
    @csv_hash["f#{file_number}".to_sym] << copyright_check(file)
  end

  def copyright_check(file)
    return '' unless @thesis.copyright.url

    thesis_pdf_checker(file, @thesis.copyright.url)
  end

  def rights_author_license(file, file_number)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, @thesis.license.map_license_type)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, 'Copyright retained by author(s)')
    @csv_hash["f#{file_number}".to_sym] << license_check(file)
  end

  def license_check(file)
    return '' unless @thesis.license.url

    thesis_pdf_checker(file, @thesis.license.url)
  end

  def rights_author(file, file_number)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, @thesis.copyright.statement_dspace)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, 'Copyright retained by author(s)')
    @csv_hash["f#{file_number}".to_sym] << copyright_check(file)
  end

  def dc_contributor_department
    @thesis.departments.each do |dept|
      @csv_hash[:headers] << 'dc.contributor.department'
      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << thesis_pdf_checker(file, dept.name_dspace)
      end
    end
  end

  def degree_fields
    @thesis.degrees.each do |degree|
      @csv_hash[:headers] << 'dc.description.degree'
      @csv_hash[:headers] << 'thesis.degree.name'
      @csv_hash[:headers] << 'mit.thesis.degree'

      @thesis.files.each_with_index do |file, i|
        degree_abbreviation(file, i, degree)
        degree_name_dspace(file, i, degree)
        degree_degree_type(file, i, degree)
      end
    end
  end

  def degree_abbreviation(file, file_number, degree)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, degree.abbreviation)
  end

  def degree_name_dspace(file, file_number, degree)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, degree.name_dspace)
  end

  def degree_degree_type(file, file_number, degree)
    @csv_hash["f#{file_number}".to_sym] << thesis_pdf_checker(file, degree.degree_type&.name.to_s)
  end

  def non_repeating
    @csv_hash[:headers] << ['filename', 'Level_of_DPCommitment', 'dc.title', 'dc.date.issued', 'dc.date.submitted',
                            'dc.type', 'dc.description.abstract', 'dc.identifier.uri', 'BitstreamDescription',
                            'BitstreamChecksumValue']
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
    end
  end

  def level_of_commitment(file)
    thesis_pdf_checker(file, 'Level 3')
  end

  def dc_title(file)
    thesis_pdf_checker(file, @thesis.title)
  end

  def dc_date_issued(file)
    thesis_pdf_checker(file, @thesis.grad_date.strftime('%Y-%m'))
  end

  def dc_date_submitted(file)
    thesis_pdf_checker(file, file.blob.created_at)
  end

  def dc_description_abstract(file)
    thesis_pdf_checker(file, @thesis.abstract)
  end

  def dc_identifier_uri(file)
    thesis_pdf_checker(file, @thesis.dspace_handle.to_s)
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

  # repeatable, take care to increment all file rows but only include details in thesis_pdf
  def dc_terms_is_part_of
    @thesis.departments.each do |dept|
      @csv_hash[:headers] << 'dcterms.isPartOf'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << thesis_pdf_checker(file,
                                                        "AIC##{ArchivematicaCourse.format_course(dept.code_dw)}_theses")
      end
    end
  end

  # repeatable, take care to increment all file rows but only include details in thesis_pdf
  def dc_contributor_author
    @thesis.authors.each do |author|
      @csv_hash[:headers] << 'dc.contributor.author'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << thesis_pdf_checker(file, author.user.preferred_name)
      end
    end
  end

  # repeatable, take care to increment all file rows but only include details in thesis_pdf
  def dc_identifier_orcid
    @thesis.authors.each do |author|
      @csv_hash[:headers] << 'dc.identifier.orcid'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << thesis_pdf_checker(file, author.user.orcid.to_s)
      end
    end
  end

  # repeatable, take care to increment all file rows but only include details in thesis_pdf
  def dc_contributor_advisor
    @thesis.advisors.each do |advisor|
      @csv_hash[:headers] << 'dc.contributor.advisor'

      @thesis.files.each_with_index do |file, i|
        @csv_hash["f#{i}".to_sym] << thesis_pdf_checker(file, advisor.name)
      end
    end
  end

  def dc_publisher(file)
    thesis_pdf_checker(file, 'Massachusetts Institute of Technology')
  end

  def dc_type(file)
    thesis_pdf_checker(file, 'Thesis')
  end
end
