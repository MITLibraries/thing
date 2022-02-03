require 'test_helper'

class ArchivematicaMetadatataTest < ActiveSupport::TestCase

  # Attaching thesis file so tests will pass
  def publishing_friendly_thesis(thesis)
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    thesis.files.first.description = 'My thesis'
    thesis.files.first.purpose = 'thesis_pdf'
    thesis.save

    file = Rails.root.join('test', 'fixtures', 'files', 'b_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'b_pdf.pdf')
    thesis.files.second.description = 'Not a thesis'
    thesis.files.second.purpose = 'signature_page'
    thesis.save
  end

  test 'requested value is returned for thesis_pdf but blank is returned for other file purposes' do
    t = theses(:one)
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)

    assert_equal("Hello", meta.send(:thesis_pdf_checker, t.files.first, "Hello"))
    assert_equal("", meta.send(:thesis_pdf_checker, t.files.last, "Hello"))
  end

  test 'header pdf fields' do
    t = theses(:one)
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:headers],
      ["filename", "Level_of_DPCommitment", "dc.title", "dc.date.issued", "dc.date.submitted", "dc.type", "dc.description.abstract", "dc.identifier.uri", "BitstreamDescription", "BitstreamChecksumValue", "BitstreamChecksumAlgorithm", "dc.publisher", "dc.terms.isPartOf", "dc.contributor.author", "dc.identifier.orcid", "dc.contributor.advisor", "dc.description.degree", "thesis.degree.name", "mit.thesis.degree", "dc.contributor.department", "dc.rights", "dc.rights", "dc.rights.uri"]
    )
  end

  test 'non-thesis pdf fields' do
    t = theses(:one)
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:f1],
      ["data/b_pdf.pdf", "", "", "", "", "", "", "", "Signature page", "2800ec8c99c60f5b15520beac9939a46", "MD5", "", "", "", "", "", "", "", "", "", "", "", ""]
    )
  end

  # test output for various rights, licenses, etc for the 

  test 'thesis pdf fields rights not the author' do
    t = theses(:one)
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:f0],
      ["data/a_pdf.pdf", "Level 3", "MyString", "2017-09", t.files.first.blob.created_at, "Thesis", "MyText", "", "Thesis PDF", "2800ec8c99c60f5b15520beac9939a46", "MD5", "Massachusetts Institute of Technology", "AIC#Course_16_theses", "Yobot, Yo", "0001", "Addy McAdvisor", "MFA", "Master of Fine Arts", "Bachelor", "Massachusetts Institute of Technology. Department of Aeronautics and Astronautics", "In Copyright - Educational Use Permitted", "Copyright MIT", "http://rightsstatements.org/page/InC-EDU/1.0/"]
    )
  end

  test 'thesis pdf fields rights author no license' do
    t = theses(:one)
    t.copyright = copyrights(:author)
    t.license = nil
    t.save
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:f0],
      ["data/a_pdf.pdf", "Level 3", "MyString", "2017-09", t.files.first.blob.created_at, "Thesis", "MyText", "", "Thesis PDF", "2800ec8c99c60f5b15520beac9939a46", "MD5", "Massachusetts Institute of Technology", "AIC#Course_16_theses", "Yobot, Yo", "0001", "Addy McAdvisor", "MFA", "Master of Fine Arts", "Bachelor", "Massachusetts Institute of Technology. Department of Aeronautics and Astronautics", "In Copyright", "Copyright retained by author(s)", "https://rightsstatements.org/page/InC/1.0/"]
    )
  end

  test 'thesis pdf fields rights author with license' do
    t = theses(:one)
    t.copyright = copyrights(:author)
    t.license = licenses(:ccby)
    t.save
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:f0],
      ["data/a_pdf.pdf", "Level 3", "MyString", "2017-09", t.files.first.blob.created_at, "Thesis", "MyText", "", "Thesis PDF", "2800ec8c99c60f5b15520beac9939a46", "MD5", "Massachusetts Institute of Technology", "AIC#Course_16_theses", "Yobot, Yo", "0001", "Addy McAdvisor", "MFA", "Master of Fine Arts", "Bachelor", "Massachusetts Institute of Technology. Department of Aeronautics and Astronautics", "Attribution 4.0 International (CC BY 4.0)", "Copyright retained by author(s)", "https://creativecommons.org/licenses/by/4.0/"]
    )
  end

  test 'thesis pdf course does not start with a number' do
    t = theses(:one)
    t.departments = [departments(:non_number_code)]
    t.save
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:f0],
    ["data/a_pdf.pdf", "Level 3", "MyString", "2017-09", t.files.first.blob.created_at, "Thesis", "MyText", "", "Thesis PDF", "2800ec8c99c60f5b15520beac9939a46", "MD5", "Massachusetts Institute of Technology", "AIC#hallo_theses", "Yobot, Yo", "0001", "Addy McAdvisor", "MFA", "Master of Fine Arts", "Bachelor", "MIT. Non numeric code", "In Copyright - Educational Use Permitted", "Copyright MIT", "http://rightsstatements.org/page/InC-EDU/1.0/"]
    )
  end

  test 'thesis course starts with a number and is entirely numeric' do
    t = theses(:one)
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:f0],
    ["data/a_pdf.pdf", "Level 3", "MyString", "2017-09", t.files.first.blob.created_at, "Thesis", "MyText", "", "Thesis PDF", "2800ec8c99c60f5b15520beac9939a46", "MD5", "Massachusetts Institute of Technology", "AIC#Course_16_theses", "Yobot, Yo", "0001", "Addy McAdvisor", "MFA", "Master of Fine Arts", "Bachelor", "Massachusetts Institute of Technology. Department of Aeronautics and Astronautics", "In Copyright - Educational Use Permitted", "Copyright MIT", "http://rightsstatements.org/page/InC-EDU/1.0/"]
    )
  end

  test 'thesis course starts with a number but contains a non-numeric component' do
    t = theses(:one)
    t.departments = [departments(:two)]
    t.save
    publishing_friendly_thesis(t)
    meta = ArchivematicaMetadata.new(t)
    csv = meta.instance_variable_get(:@csv_hash)
    assert_equal(csv[:f0],
    ["data/a_pdf.pdf", "Level 3", "MyString", "2017-09", t.files.first.blob.created_at, "Thesis", "MyText", "", "Thesis PDF", "2800ec8c99c60f5b15520beac9939a46", "MD5", "Massachusetts Institute of Technology", "AIC#Course_21A_theses", "Yobot, Yo", "0001", "Addy McAdvisor", "MFA", "Master of Fine Arts", "Bachelor", "MIT Anthropology Program", "In Copyright - Educational Use Permitted", "Copyright MIT", "http://rightsstatements.org/page/InC-EDU/1.0/"]
    )
  end

  test 'generates csv' do
    require 'csv'

    # We need to freeze because the file content changes based on the dates in the Thesis so we need to compare against
    # a fixture created for a specific date and create the csv with that same date to get a match.
    Timecop.freeze(Time.utc(2021, 12, 25, 12, 20, 0)) do
      t = theses(:one)
      publishing_friendly_thesis(t)

      # load a csv fixture
      expected_csv = CSV.read('test/fixtures/files/thesis_1234_archivematica.csv', headers: true).to_csv

      # generate our csv
      actual_csv = ArchivematicaMetadata.new(t).to_csv

      assert_equal(expected_csv, actual_csv)
    end
  end

  test 'can calculate an MD5 digest' do

    # We need to freeze because the file content changes based on the dates in the Thesis record and that changes the
    # MD5 digest. Freezing time provides the consistent digest we need for this test.
    Timecop.freeze(Time.utc(2021, 12, 25, 12, 20, 0)) do

      t = theses(:one)
      publishing_friendly_thesis(t)
      assert_equal("c38f8ac8cdeb08bc344b6d5b7002458a", ArchivematicaMetadata.new(t).md5)

    end
  end
end
