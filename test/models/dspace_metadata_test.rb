require 'test_helper'

class DspaceMetadataTest < ActiveSupport::TestCase
  # Attaching thesis file so tests will pass
  def dss_friendly_thesis(thesis)
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    thesis.files.first.description = 'My thesis'
    thesis.files.first.purpose = 'thesis_pdf'
    thesis.save
  end

  test 'metadata file contains thesis data' do
    t = theses(:one)
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.title', 'value' => 'MyString' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.date.issued', 'value' => '2017-09' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.description.abstract', 'value' => 'MyText' })

    # No abstract (optional for undergraduate theses)
    t.abstract = nil
    t.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)
    refute unserialized['metadata'].include?({ 'key' => 'dc.description.abstract', 'value' => '' })
  end

  test 'metadata file contains author data' do
    # One author
    t = Thesis.create(title: 'Who cares', graduation_year: '2021', graduation_month: 'February',
                      advisors: [advisors(:first)], users: [users(:second)], degrees: [degrees(:one)],
                      departments: [departments(:one)], copyright: copyrights(:mit))
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.contributor.author', 'value' => 'Student, Second' })

    # More than one author
    t.users = [users(:second), users(:third)]
    t.save

    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.contributor.author', 'value' => 'Student, Second' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.contributor.author', 'value' => 'Student, Third' })
  end

  test 'metadata file contains ORCIDs' do
    t = theses(:one)
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    # One author and one ORCID
    assert unserialized['metadata'].include?({ 'key' => 'dc.identifier.orcid', 'value' => '0001' })

    # Multiple authors and multiple ORCIDs
    t2 = theses(:two)
    dss_friendly_thesis(t2)

    # Since theses(:two) has no advisors, we need to attach one as DspaceMetadata expects this. This can be can be
    # removed once we update the Thesis validations to reflect publication requirements.
    t2.advisors = [advisors(:first)]
    t2.save
    serialized = DspaceMetadata.new(t2).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.identifier.orcid', 'value' => '0001' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.identifier.orcid', 'value' => '0002' })

    # Multiple authors and only one ORCID
    u = User.find_by_orcid('0002')
    u.orcid = nil
    u.save
    t2.reload
    serialized = DspaceMetadata.new(t2).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.identifier.orcid', 'value' => '0001' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.identifier.orcid', 'value' => '0002' })

    # Multiple authors and no ORCID
    u = User.find_by_orcid('0001')
    u.orcid = nil
    u.save
    t2.reload

    serialized = DspaceMetadata.new(t2).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    refute unserialized['metadata'].include?({ 'key' => 'dc.identifier.orcid', 'value' => '0001' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.identifier.orcid', 'value' => '0002' })
  end

  test 'metadata file contains advisor data' do
    t = theses(:one)
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    # One advisor
    assert unserialized['metadata'].include?({ 'key' => 'dc.contributor.advisor', 'value' => 'Addy McAdvisor' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.contributor.advisor', 'value' => 'Viola McAdvisor' })

    # More than one advisor
    t.advisors = [advisors(:first), advisors(:second)]
    t.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.contributor.advisor', 'value' => 'Addy McAdvisor' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.contributor.advisor', 'value' => 'Viola McAdvisor' })
  end

  test 'metadata file contains copyright data' do
    # Author holds copyright and license is present
    t = theses(:one)
    t.copyright = copyrights(:author)
    t.license = licenses(:ccby)
    t.users = [users(:yo)]
    t.advisors = [advisors(:first)]
    t.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'Attribution 4.0 International (CC BY 4.0)' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'In Copyright' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'Copyright retained by author(s)' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://creativecommons.org/licenses/by/4.0/' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://rightsstatements.org/page/InC/1.0/' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'In Copyright - Educational Use Permitted' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'U+00A9 MIT' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'http://rightsstatements.org/page/InC-EDU/1.0/' })

    # No URI
    t.license = licenses(:nocc)
    t.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    refute unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'Attribution 4.0 International (CC BY 4.0)' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'In Copyright' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'Copyright retained by author(s)' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://creativecommons.org/licenses/by/4.0/' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://rightsstatements.org/page/InC/1.0/' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'In Copyright - Educational Use Permitted' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'U+00A9 MIT' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'http://rightsstatements.org/page/InC-EDU/1.0/' })

    # Author holds copyright and no license
    t.license = nil
    t.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    refute unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'Attribution 4.0 International (CC BY 4.0)' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'In Copyright' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'Copyright retained by author(s)' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://creativecommons.org/licenses/by/4.0/' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://rightsstatements.org/page/InC/1.0/' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'In Copyright - Educational Use Permitted' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'U+00A9 MIT' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'http://rightsstatements.org/page/InC-EDU/1.0/' })

    # Any other copyright holder
    t.copyright = copyrights(:mit)
    t.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    refute unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'Attribution 4.0 International (CC BY 4.0)' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'In Copyright' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'Copyright retained by author(s)' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://creativecommons.org/licenses/by/4.0/' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'https://rightsstatements.org/page/InC/1.0/' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights',
                                               'value' => 'In Copyright - Educational Use Permitted' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights', 'value' => 'Copyright MIT' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.rights.uri',
                                               'value' => 'http://rightsstatements.org/page/InC-EDU/1.0/' })
  end

  test 'metadata file contains department data' do
    # One department
    t = theses(:one)
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?(
      { 'key' => 'dc.contributor.department',
        'value' => 'Massachusetts Institute of Technology. Department of Aeronautics and Astronautics' }
    )
    refute unserialized['metadata'].include?({ 'key' => 'dc.contributor.department',
                                               'value' => 'MIT Anthropology Program' })

    # Multiple departments
    t.departments = [departments(:one), departments(:two)]
    t.save
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?(
      { 'key' => 'dc.contributor.department',
        'value' => 'Massachusetts Institute of Technology. Department of Aeronautics and Astronautics' }
    )
    assert unserialized['metadata'].include?({ 'key' => 'dc.contributor.department',
                                               'value' => 'MIT Anthropology Program' })
  end

  test 'metadata file contains degree data' do
    # One degree
    t = theses(:one)
    d1 = degrees(:one)
    d1.degree_type_id = degree_types(:bachelor).id
    d1.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.description.degree', 'value' => 'MFA' })
    refute unserialized['metadata'].include?({ 'key' => 'dc.description.degree', 'value' => 'JD' })
    assert unserialized['metadata'].include?({ 'key' => 'thesis.degree.name', 'value' => 'Master of Fine Arts' })
    assert unserialized['metadata'].include?({ 'key' => 'mit.thesis.degree', 'value' => 'Bachelor' })
    refute unserialized['metadata'].include?({ 'key' => 'mit.thesis.degree', 'value' => 'Master' })

    # Multiple degrees
    d2 = degrees(:two)
    d2.degree_type_id = degree_types(:master).id
    d2.save
    t.degrees = [d1, d2]
    t.save
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.description.degree', 'value' => 'MFA' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.description.degree', 'value' => 'JD' })
    # TODO: are we supposed to be including the same degree name twice if they are the same?
    assert unserialized['metadata'].include?({ 'key' => 'thesis.degree.name', 'value' => 'Master of Fine Arts' })
    assert_equal 2, unserialized['metadata'].count({ 'key' => 'thesis.degree.name', 'value' => 'Master of Fine Arts' })

    assert unserialized['metadata'].include?({ 'key' => 'mit.thesis.degree', 'value' => 'Bachelor' })
    assert unserialized['metadata'].include?({ 'key' => 'mit.thesis.degree', 'value' => 'Master' })

    # Does not repeat degree types
    d2.degree_type_id = degree_types(:bachelor).id
    d2.save
    t.reload

    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.description.degree', 'value' => 'MFA' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.description.degree', 'value' => 'JD' })
    assert unserialized['metadata'].include?({ 'key' => 'thesis.degree.name', 'value' => 'Master of Fine Arts' })
    assert unserialized['metadata'].include?({ 'key' => 'thesis.degree.name', 'value' => 'Master of Fine Arts' })
    assert unserialized['metadata'].include?({ 'key' => 'mit.thesis.degree', 'value' => 'Bachelor' })
    refute unserialized['metadata'].include?({ 'key' => 'mit.thesis.degree', 'value' => 'Master' })
    assert_equal 1, unserialized['metadata'].count({ 'key' => 'mit.thesis.degree', 'value' => 'Bachelor' })
  end

  test 'metadata file contains file data' do
    t = theses(:one)
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    created_at = t.files.select { |file| file.purpose == 'thesis_pdf' }.first.blob.created_at.iso8601(3)
    assert unserialized['metadata'].include?({ 'key' => 'dc.date.submitted', 'value' => created_at })
  end

  test 'metadata file contains constituent DC metadata on instantiation' do
    t = theses(:one)
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata
    unserialized = JSON.parse(serialized)

    assert unserialized['metadata'].include?({ 'key' => 'dc.publisher',
                                               'value' => 'Massachusetts Institute of Technology' })
    assert unserialized['metadata'].include?({ 'key' => 'dc.type', 'value' => 'Thesis' })
  end

  test 'metadata file is structured as expected for DSS' do
    t = theses(:one)
    dss_friendly_thesis(t)
    serialized = DspaceMetadata.new(t).serialize_dss_metadata

    # Make sure the JSON is actually serialized
    assert_equal String, serialized.class

    # Unserialize the JSON so we can check that it's well-formed
    unserialized = JSON.parse(serialized)
    assert_equal ['metadata'], unserialized.keys
    assert_equal unserialized['metadata'].first, { 'key' => 'dc.publisher',
                                                   'value' => 'Massachusetts Institute of Technology' }
  end
end
