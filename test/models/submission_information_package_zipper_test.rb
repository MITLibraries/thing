require 'test_helper'

class SubmissionInformationPackageZipperTest < ActiveSupport::TestCase
    
  # because we need to actually use the file it's easier to attache it in the test rather
  # than use our fixtures as the fixtures oddly don't account for the file actually being
  # where ActiveStorage expects them to be. We also need this to be a record that looks like
  # a published record so we'll use the published fixture, remove the fixtured files, and attach
  # one again.
  def setup_thesis
    thesis = theses(:published)
    thesis.files = []
    thesis.save
    file = Rails.root.join('test', 'fixtures', 'files', 'registrar_data_small_sample.csv')
    thesis.files.attach(io: File.open(file), filename: 'registrar_data_small_sample.csv')
    thesis
  end

  test 'sip has an attached zipped bag' do
    thesis = setup_thesis
    sip = thesis.submission_information_packages.create
    SubmissionInformationPackageZipper.new(sip)

    assert_equal("application/zip", thesis.submission_information_packages.first.bag.blob.content_type)
  end

  # Failure to properly close the handles can allow the zip creation to appear correct but actually be invalid
  # this is a regression test to ensure we avoid that situation
  # You can see this test fail by removing the `tmpfile.close` from the end of bagamatic.
  test 'zip is valid' do
    thesis = setup_thesis
    sip = thesis.submission_information_packages.create
    SubmissionInformationPackageZipper.new(sip)

    blob = thesis.submission_information_packages.last.bag.blob
    Zip::File.open(blob.service.send(:path_for, blob.key)) do |zipfile|
      assert_nil(zipfile.find_entry("file_not_in_zipfile.txt"))
      assert_equal('manifest-md5.txt', zipfile.find_entry("manifest-md5.txt").to_s)
    end
  end
end
