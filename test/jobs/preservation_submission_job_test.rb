require 'test_helper'

class PreservationSubmissionJobTest < ActiveJob::TestCase

  # because we need to actually use the file it's easier to attach it in the test rather
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

  test 'creates a SIP' do
    thesis = setup_thesis
    assert_equal 0, thesis.submission_information_packages.count

    PreservationSubmissionJob.perform_now(thesis)
    assert_equal 1, thesis.submission_information_packages.count
  end

  test 'updates preservation_status to "preserved" after successfully processing a thesis' do
    thesis = setup_thesis
    PreservationSubmissionJob.perform_now(thesis)
    assert_equal 'preserved', thesis.submission_information_packages.last.preservation_status
  end

  test 'updates preserved_at to the current time after successfully processing a thesis' do
    time = DateTime.new.getutc
    Timecop.freeze(time) do
      thesis = setup_thesis
      PreservationSubmissionJob.perform_now(thesis)
      assert_equal time, thesis.submission_information_packages.last.preserved_at
    end
  end

  test 'rescues exceptions by updating preservation_status to "error"' do
    thesis = theses(:one)
    PreservationSubmissionJob.perform_now(thesis)
    assert_equal 'error', thesis.submission_information_packages.last.preservation_status
  end

  test 'does not update preserved_at if the job enters an error state' do
    thesis = theses(:one)
    PreservationSubmissionJob.perform_now(thesis)
    assert_nil thesis.submission_information_packages.last.preserved_at
  end
end
