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

  test 'sends report emails' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        PreservationSubmissionJob.perform_now([setup_thesis])
      end
    end
  end

  test 'creates a SIP' do
    thesis = setup_thesis
    assert_equal 0, thesis.submission_information_packages.count

    PreservationSubmissionJob.perform_now([thesis])
    assert_equal 1, thesis.submission_information_packages.count
  end

  test 'creates multiple SIPs' do
    thesis_one = setup_thesis
    thesis_two = theses(:engineer)
    assert_equal 0, thesis_one.submission_information_packages.count
    assert_equal 0, thesis_two.submission_information_packages.count

    theses = [thesis_one, thesis_two]
    PreservationSubmissionJob.perform_now(theses)
    assert_equal 1, thesis_one.submission_information_packages.count
    assert_equal 1, thesis_two.submission_information_packages.count

    PreservationSubmissionJob.perform_now(theses)
    assert_equal 2, thesis_one.submission_information_packages.count
    assert_equal 2, thesis_two.submission_information_packages.count
  end

  test 'updates preservation_status to "preserved" after successfully processing a thesis' do
    thesis = setup_thesis
    PreservationSubmissionJob.perform_now([thesis])
    assert_equal 'preserved', thesis.submission_information_packages.last.preservation_status
  end

  test 'updates preserved_at to the current time after successfully processing a thesis' do
    time = DateTime.new.getutc
    Timecop.freeze(time) do
      thesis = setup_thesis
      PreservationSubmissionJob.perform_now([thesis])
      assert_equal time, thesis.submission_information_packages.last.preserved_at
    end
  end

  test 'throws exceptions when a thesis is unbaggable' do
    assert_raises StandardError do
      PreservationSubmissionJob.perform_now([theses[:one]])
    end

    assert_nothing_raised do
      PreservationSubmissionJob.perform_now([setup_thesis])
    end
  end

  test 'does not create a SIP if the job enters an error state' do
    thesis = theses(:one)
    assert_empty thesis.submission_information_packages

    PreservationSubmissionJob.perform_now([thesis])
    assert_empty thesis.submission_information_packages
  end
end
