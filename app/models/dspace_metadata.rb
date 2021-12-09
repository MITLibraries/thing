# Generates Dublin Core metadata required to publish a Thesis object to DSpace@MIT via the DSpace Submission System
# DSS. This class assumes that the input Thesis is ready for publication and has all the requisite metadata and file
# attachments. Validation of those requirements will occur in the Thesis model.

class DspaceMetadata
  def initialize(thesis)
    @dc = {}.compare_by_identity
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
    thesis_users.each do |a|
      @dc['dc.contributor.author'] = a.preferred_name
    end
    parse_orcids(thesis_users)
    thesis_advisors.each do |adv|
      @dc['dc.contributor.advisor'] = adv.name
    end
  end

  # We don't care about the order of the ORCIDs because DSpace can't assign them to a specific user.
  def parse_orcids(thesis_users)
    return unless thesis_users.any?(&:orcid)

    orcids = thesis_users.map(&:orcid).compact
    return unless orcids.present?

    orcids.each do |orcid|
      @dc['dc.identifier.orcid'] = orcid
    end
  end

  def departments(thesis_depts)
    thesis_depts.each do |d|
      @dc['dc.contributor.department'] = d.name_dspace
    end
  end

  def degrees(thesis_degrees)
    thesis_degrees.each do |degree|
      @dc['dc.description.degree'] = degree.abbreviation
      @dc['thesis.degree.name'] = degree.name_dspace
    end

    # Degree types should not be repeated if they are the same type.
    types = thesis_degrees.map { |degree| degree.degree_type.name }.uniq
    types.each do |t|
      @dc['mit.thesis.degree'] = t
    end
  end

  def copyright(thesis_copyright, thesis_license)
    if thesis_copyright.holder != 'Author' # copyright holder is anyone but author
      @dc['dc.rights'] = thesis_copyright.statement_dspace
      @dc['dc.rights'] = "© #{thesis_copyright.holder}"
      @dc['dc.rights.uri'] = thesis_copyright.url if thesis_copyright.url
    elsif thesis_license # author holds copyright and provides a license
      @dc['dc.rights'] = thesis_license.map_license_type
      @dc['dc.rights'] = 'Copyright retained by author(s)'

      # Theoretically both license and copyright URLs are required for publication, but there are no constraints on
      # the models, and we want to future-proof this.
      @dc['dc.rights.uri'] = thesis_license.url if thesis_license.url
    else # author holds copyright and no license provided
      @dc['dc.rights'] = thesis_copyright.statement_dspace
      @dc['dc.rights'] = 'Copyright retained by author(s)'
      @dc['dc.rights.uri'] = thesis_copyright.url if thesis_copyright.url
    end
  end

  def date_transferred(files)
    @dc['dc.date.submitted'] = files.select { |file| file.purpose == 'thesis_pdf' }.first.blob.created_at
  end
end
