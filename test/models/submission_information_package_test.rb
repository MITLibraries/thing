# == Schema Information
#
# Table name: submission_information_packages
#
#  id                  :integer          not null, primary key
#  preserved_at        :datetime
#  preservation_status :integer          default(0), not null
#  bag_declaration     :string
#  bag_name            :string
#  manifest            :text
#  metadata            :text
#  thesis_id           :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'test_helper'

class SubmissionInformationPackageTest < ActiveSupport::TestCase
  include Checksums

  test 'generates bag declaration on create' do
    sip = theses(:published).submission_information_packages.create
    assert_equal "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8", sip.bag_declaration
  end

  test 'bag declaration does not vary' do
    sip = theses(:published).submission_information_packages.create

    another_published_thesis = theses(:publication_review)
    another_published_thesis.dspace_handle = '1234/5678'
    another_sip = another_published_thesis.submission_information_packages.new
    another_published_thesis.save

    assert_equal sip.bag_declaration, another_sip.bag_declaration
  end

  test 'generates manifest on create' do
    thesis = theses(:published)
    checksums = []
    checksums << "#{base64_to_hex(thesis.files.first.checksum)} data/a_pdf.pdf"
    checksums << "#{ArchivematicaMetadata.new(thesis).md5} data/metadata.csv"
    sip = thesis.submission_information_packages.create
    assert_equal checksums.join("\n"), sip.manifest
  end

  test 'files in manifest are separated with newlines' do
    thesis = theses(:published)
    file = Rails.root.join('test', 'fixtures', 'files', 'registrar_data_small_sample.csv')
    thesis.files.attach(io: File.open(file), filename: 'registrar_data_small_sample.csv')
    assert thesis.files.length > 1

    sip = thesis.submission_information_packages.create
    assert_includes sip.manifest, "\n"
  end

  test 'generates bag name on create' do
    sip = theses(:published).submission_information_packages.create
    assert_equal '1234.5_6789-thesis-1', sip.bag_name
  end

  test 'generates metadata file on create' do
    t = theses(:published)
    sip = t.submission_information_packages.create
    expected = ArchivematicaMetadata.new(t).to_csv
    assert_equal expected, sip.metadata
  end

  test 'properties generated on create are persisted' do
    t = theses(:published)
    assert_empty t.submission_information_packages
    
    t.submission_information_packages.create
    assert t.submission_information_packages.any?

    sip = t.submission_information_packages.last
    assert_not_nil sip.manifest
    assert_not_nil sip.bag_name
    assert_not_nil sip.bag_declaration
    assert_not_nil sip.metadata

    t.reload
    sip = t.submission_information_packages.last
    assert_not_nil sip.manifest
    assert_not_nil sip.bag_name
    assert_not_nil sip.bag_declaration
    assert_not_nil sip.metadata
  end

  test 'preservation_status defaults to unpreserved' do
    sip = theses(:published).submission_information_packages.create
    assert_equal 'unpreserved', sip.preservation_status
  end

  test 'data generates file location hash' do
    thesis = theses(:published)
    sip = thesis.submission_information_packages.create
    expected = thesis.files.first.blob
    assert_equal expected, sip.data['data/a_pdf.pdf']
  end

  test 'data includes metadata CSV' do
    t = theses(:published)
    sip = t.submission_information_packages.create
    expected = ArchivematicaMetadata.new(t).to_csv
    assert_equal expected, sip.data['data/metadata.csv']
  end

  test 'a SIP is valid if its thesis is baggable' do
    # baggable thesis (files attached, DSpace handle, no duplicate filenames)
    sip = theses(:published).submission_information_packages.create
    assert sip.valid?
  end

  test 'a SIP is invalid if its thesis has no DSpace handle' do
    # unbaggable thesis (DSpace handle is nil)
    thesis = theses(:published)
    thesis.dspace_handle = nil
    sip = thesis.submission_information_packages.new
    thesis.save
    assert_not sip.valid?

    # unbaggable thesis (DSpace handle is an empty string)
    thesis.dspace_handle = ''
    sip = thesis.submission_information_packages.new
    thesis.save
    assert_not sip.valid?
  end

  test 'a SIP is invalid if its thesis has duplicate filenames' do
    # unbaggable thesis (duplicate filenames)
    thesis = theses(:published)
    thesis.dspace_handle = '1234/5678'
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    sip = thesis.submission_information_packages.new
    thesis.save
    assert_not sip.valid?
  end

  test 'a SIP is invalid if its thesis has no files attached' do
    # unbaggable thesis (no files attached)
    thesis = theses(:published)
    thesis.files = nil
    sip = thesis.submission_information_packages.new
    thesis.save
    assert_not sip.valid?
  end

  test 'a SIP is invalid if it has no thesis' do
    sip = SubmissionInformationPackage.create
    assert_not sip.valid?

    sip.thesis = theses(:published)
    assert sip.valid?
  end
end
