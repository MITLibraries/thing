# Generates Dublin Core metadata required to publish a Thesis object to DSpace@MIT via the DSpace Submission System
# DSS. This class assumes that the input Thesis is ready for publication and has all the requisite metadata and file
# attachments. Validation of those requirements will occur in the Thesis model.

class DspaceMetadata
  def initialize(thesis)
    @metadata_entries = []
    add_metadata('dc.publisher', 'Massachusetts Institute of Technology')
    add_metadata('dc.type', 'Thesis')
    title(thesis)
    contributors(thesis.users, thesis.advisors)
    departments(thesis.departments)
    degrees(thesis.degrees)
    copyright(thesis.copyright, thesis.license)
    date_transferred(thesis.files)
  end

  # Generates JSON metadata file required for submission to DSS.
  def serialize_dss_metadata
    if Flipflop.enabled?(:dspace_v8_metadata)
      serialize_dspace8.to_json
    else
      { 'metadata' => serialize_dspace6 }.to_json
    end
  end

  def title(thesis)
    add_metadata('dc.title', thesis.title)
    add_metadata('dc.description.abstract', thesis.abstract) if thesis.abstract
    add_metadata('dc.date.issued', thesis.grad_date.strftime('%Y-%m'))
  end

  def contributors(thesis_users, thesis_advisors)
    thesis_users.each do |a|
      add_metadata('dc.contributor.author', a.preferred_name)
    end
    parse_orcids(thesis_users)
    thesis_advisors.each do |adv|
      add_metadata('dc.contributor.advisor', adv.name)
    end
  end

  # We don't care about the order of the ORCIDs because DSpace can't assign them to a specific user.
  def parse_orcids(thesis_users)
    return unless thesis_users.any?(&:orcid)

    orcids = thesis_users.map(&:orcid).compact
    return unless orcids.present?

    orcids.each do |orcid|
      add_metadata('dc.identifier.orcid', orcid)
    end
  end

  def departments(thesis_depts)
    thesis_depts.each do |d|
      add_metadata('dc.contributor.department', d.name_dspace)
    end
  end

  def degrees(thesis_degrees)
    thesis_degrees.each do |degree|
      add_metadata('dc.description.degree', degree.abbreviation)
      add_metadata('thesis.degree.name', degree.name_dspace)
    end

    # Degree types should not be repeated if they are the same type.
    types = thesis_degrees.map { |degree| degree.degree_type.name }.uniq
    types.each do |t|
      add_metadata('mit.thesis.degree', t)
    end
  end

  def copyright(thesis_copyright, thesis_license)
    if thesis_copyright.holder != 'Author' # copyright holder is anyone but author
      add_metadata('dc.rights', thesis_copyright.statement_dspace)
      add_metadata('dc.rights', "Copyright #{thesis_copyright.holder}")
      add_metadata('dc.rights.uri', thesis_copyright.url) if thesis_copyright.url
    elsif thesis_license # author holds copyright and provides a license
      add_metadata('dc.rights', thesis_license.map_license_type)
      add_metadata('dc.rights', 'Copyright retained by author(s)')

      # Theoretically both license and copyright URLs are required for publication, but there are no constraints on
      # the models, and we want to future-proof this.
      add_metadata('dc.rights.uri', thesis_license.evaluate_license_url)
    else # author holds copyright and no license provided
      add_metadata('dc.rights', thesis_copyright.statement_dspace)
      add_metadata('dc.rights', 'Copyright retained by author(s)')
      add_metadata('dc.rights.uri', thesis_copyright.url) if thesis_copyright.url
    end
  end

  def date_transferred(files)
    add_metadata('dc.date.submitted', files.select { |file| file.purpose == 'thesis_pdf' }.first.blob.created_at)
  end

  private

  def add_metadata(key, value)
    return if value.nil?

    @metadata_entries << { 'key' => key, 'value' => value }
  end

  def serialize_dspace6
    @metadata_entries
  end

  def serialize_dspace8
    result = {}

    @metadata_entries.each do |entry|
      key = entry['key']
      value = entry['value']

      result[key] ||= []
      result[key] << { 'value' => value }
    end

    result
  end
end
