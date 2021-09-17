require 'test_helper'

class DspaceMetadataTest < ActiveSupport::TestCase
  # Adding some properties that are not included in our fixtures
  def dss_friendly_thesis(thesis)
    degree = thesis.degrees.first
    degree.degree_type_id = degree_types(:bachelor).id
    degree.save
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    thesis.files.first.description = 'My thesis'
    thesis.files.first.purpose = 'thesis_pdf'
    thesis.save
  end

  test 'parses thesis data as DSpace DC' do
    t = theses(:one)
    dss_friendly_thesis(t)
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal 'MyString', dc['dc.title']
    assert_equal '2017-09', dc['dc.date.issued']
    assert_equal 'MyText', dc['dc.description.abstract']

    # No abstract (optional for undergraduate theses)
    t.abstract = nil
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_nil dc['dc.description.abstract']
  end

  test 'parses author data as DSpace DC' do
    # One author
    t = Thesis.create(title: 'Who cares', graduation_year: '2021', graduation_month: 'February',
                      advisors: [advisors(:first)], users: [users(:second)], degrees: [degrees(:one)],
                      departments: [departments(:one)], copyright: copyrights(:mit))
    dss_friendly_thesis(t)
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['Student, Second'], dc['dc.contributor.author']

    # More than one author
    t.users = [users(:second), users(:third)]
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['Student, Second', 'Student, Third'], dc['dc.contributor.author']
  end

  test 'parses ORCIDs' do
    # One author and one ORCID
    t1 = theses(:one)
    dss_friendly_thesis(t1)
    dc = DspaceMetadata.new(t1).instance_variable_get(:@dc)
    assert_equal ['0001'], dc['dc.identifier.orcid']

    # Multiple authors and multiple ORCIDs
    t2 = theses(:two)
    dss_friendly_thesis(t2)

    # Since theses(:two) has no advisors, we need to attach one as DspaceMetadata expects this. This can be can be
    # removed once we update the Thesis validations to reflect publication requirements.
    t2.advisors = [advisors(:first)]
    t2.save
    dc = DspaceMetadata.new(t2).instance_variable_get(:@dc)
    assert_equal %w[0002 0001], dc['dc.identifier.orcid']

    # Multiple authors and only one ORCID
    t2.users.second.orcid = nil
    t2.users.second.save
    dc = DspaceMetadata.new(t2).instance_variable_get(:@dc)
    assert_equal ['0002'], dc['dc.identifier.orcid']

    # One author and no ORCID
    t1.users.first.orcid = nil
    t1.users.first.save
    dc = DspaceMetadata.new(t1).instance_variable_get(:@dc)
    assert_nil dc['dc.identifier.orcid']
  end

  test 'parses advisor data as DSpace DC' do
    t = theses(:one)
    dss_friendly_thesis(t)
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)

    # One advisor
    assert_equal ['Addy McAdvisor'], dc['dc.contributor.advisor']

    # More than one advisor
    t.advisors = [advisors(:first), advisors(:second)]
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['Addy McAdvisor', 'Viola McAdvisor'], dc['dc.contributor.advisor']
  end

  test 'parses copyright data as DSpace DC' do
    # Author holds copyright and license is present
    t = theses(:downloaded)
    t.copyright = copyrights(:author)
    t.license = licenses(:ccby)
    t.users = [users(:yo)]
    t.advisors = [advisors(:first)]
    t.save
    dss_friendly_thesis(t)
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['Attribution 4.0 International (CC BY 4.0)', 'Copyright retained by author(s)'],
                 dc['dc.rights']
    assert_equal 'https://creativecommons.org/licenses/by/4.0/', dc['dc.rights.uri']

    # No URI
    t.license = licenses(:nocc)
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_nil dc['dc.rights.uri']

    # Author holds copyright and no license
    t.license = nil
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['In Copyright', 'Copyright retained by author(s)'], dc['dc.rights']
    assert_equal 'https://rightsstatements.org/page/InC/1.0/', dc['dc.rights.uri']

    # Any other copyright holder
    t.copyright = copyrights(:mit)
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['In Copyright - Educational Use Permitted', 'U+00A9 MIT'], dc['dc.rights']
    assert_equal 'http://rightsstatements.org/page/InC-EDU/1.0/', dc['dc.rights.uri']
  end

  test 'parses department data as DSpace DC' do
    # One department
    t = theses(:one)
    dss_friendly_thesis(t)
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['Massachusetts Institute of Technology. Department of Aeronautics and Astronautics'],
                 dc['dc.contributor.department']

    # Multiple departments
    t.departments = [departments(:one), departments(:two)]
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['Massachusetts Institute of Technology. Department of Aeronautics and Astronautics',
                  'MIT Anthropology Program'], dc['dc.contributor.department']
  end

  test 'parses degree data as DSpace DC' do
    # One degree
    t = theses(:one)
    dss_friendly_thesis(t)
    d1 = degrees(:one)
    d1.degree_type_id = degree_types(:bachelor).id
    d1.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['MFA'], dc['dc.description.degree']
    assert_equal ['Master of Fine Arts'], dc['thesis.degree.name']
    assert_equal ['Bachelor'], dc['mit.thesis.degree']

    # Multiple degrees
    d2 = degrees(:two)
    d2.degree_type_id = degree_types(:master).id
    d2.save
    t.degrees = [d1, d2]
    t.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal %w[MFA JD], dc['dc.description.degree']
    assert_equal ['Master of Fine Arts', 'Master of Fine Arts'], dc['thesis.degree.name']
    assert_equal %w[Bachelor Master], dc['mit.thesis.degree']

    # Does not repeat degree types
    d2.degree_type_id = degree_types(:bachelor).id
    d2.save
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal ['Bachelor'], dc['mit.thesis.degree']
  end

  test 'parses file data as DSpace DC' do
    t = theses(:one)
    dss_friendly_thesis(t)
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    blob = t.files.first.blob
    assert_equal blob.created_at, dc['dc.date.submitted']
  end

  test 'compiles constituent DC metadata on instantiation' do
    t = theses(:one)
    dss_friendly_thesis(t)
    dc = DspaceMetadata.new(t).instance_variable_get(:@dc)
    assert_equal 'Massachusetts Institute of Technology', dc['dc.publisher']
    assert_equal 'Thesis', dc['dc.type']

    # Checking for presence of keys instead of exact values, as we verify values in other tests.
    assert_equal ['dc.publisher', 'dc.type', 'dc.title', 'dc.description.abstract', 'dc.date.issued',
                  'dc.contributor.author', 'dc.identifier.orcid', 'dc.contributor.advisor', 'dc.contributor.department',
                  'dc.description.degree', 'thesis.degree.name', 'mit.thesis.degree', 'dc.rights', 'dc.rights.uri',
                  'dc.date.submitted'], dc.keys
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
