class DspaceMetadata
  def initialize(thesis)
    @dc = {}
    @dc['dc.publisher'] = 'Massachusetts Institute of Technology'
    @dc['dc.type'] = 'Thesis'
    title(thesis)
    contributors(thesis.users, thesis.advisors)
    departments(thesis.departments)
    degrees(thesis.degrees)
    copyright(thesis.copyright, thesis.license)
    date_transferred(thesis.files)
  end

  # Generates JSON metadata file required for submission to DSS.
  def serialize_dss_metadata
    { 'metadata' => @dc.map { |k, v| { 'key' => k, 'value' => v } } }.to_json
  end

  def title(thesis)
    @dc['dc.title'] = thesis.title
    @dc['dc.description.abstract'] = thesis.abstract if thesis.abstract
    @dc['dc.date.issued'] = thesis.grad_date.strftime('%Y-%m')
  end

  def contributors(thesis_users, thesis_advisors)
    @dc['dc.contributor.author'] = thesis_users.map(&:preferred_name)
    @dc['dc.identifier.orcid'] = parse_orcids(thesis_users) if parse_orcids(thesis_users)
    @dc['dc.contributor.advisor'] = thesis_advisors.map(&:name)
  end

  # We don't care about the order of the ORCIDs because DSpace can't assign them to a specific user.
  def parse_orcids(thesis_users)
    return unless thesis_users.any?(&:orcid)

    orcids = thesis_users.map(&:orcid).compact
    return unless orcids.present?

    orcids
  end

  def departments(thesis_depts)
    @dc['dc.contributor.department'] = thesis_depts.map(&:name_dspace)
  end

  def degrees(thesis_degrees)
    @dc['dc.description.degree'] = thesis_degrees.map(&:abbreviation)
    @dc['thesis.degree.name'] = thesis_degrees.map(&:name_dspace)

    # Degree types should not be repeated if they are the same type.
    types = thesis_degrees.map { |degree| degree.degree_type.name }.uniq
    @dc['mit.thesis.degree'] = types
  end

  def copyright(thesis_copyright, thesis_license)
    if thesis_copyright.holder != 'Author' # copyright holder is anyone but author
      @dc['dc.rights'] = [thesis_copyright.statement_dspace, "U+00A9 #{thesis_copyright.holder}"]
      @dc['dc.rights.uri'] = thesis_copyright.url if thesis_copyright.url
    elsif thesis_license # author holds copyright and provides a license
      @dc['dc.rights'] = [thesis_license.license_type, 'Copyright retained by author(s)']

      # Theoretically both license and copyright URLs are required for publication, but there are no constraints on
      # the models, and we want to future-proof this.
      @dc['dc.rights.uri'] = thesis_license.url if thesis_license.url
    else # author holds copyright and no license provided
      @dc['dc.rights'] = [thesis_copyright.statement_dspace, 'Copyright retained by author(s)']
      @dc['dc.rights.uri'] = thesis_copyright.url if thesis_copyright.url
    end
  end

  def date_transferred(files)
    @dc['dc.date.submitted'] = files.select { |file| file.purpose == 'thesis_pdf' }.first.blob.created_at
  end
end
