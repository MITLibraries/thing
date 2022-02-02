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

  test 'creates a sip' do
    thesis = setup_thesis

    assert_equal(0, thesis.submission_information_packages.count)

    SubmissionInformationPackageZipper.new(thesis)
    assert_equal(1, thesis.submission_information_packages.count)
  end

  test 'sip has an attached zipped bag' do
    thesis = setup_thesis
    SubmissionInformationPackageZipper.new(thesis)

    assert_equal("application/zip", thesis.submission_information_packages.first.bag.blob.content_type)
  end
end
