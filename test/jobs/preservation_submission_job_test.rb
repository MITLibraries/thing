require 'test_helper'
require 'webmock/minitest'

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

  def setup_thesis_two
    thesis = theses(:published_with_sip)
    thesis.files = []
    thesis.save
    file = Rails.root.join('test', 'fixtures', 'files', 'registrar_data_small_sample.csv')
    thesis.files.attach(io: File.open(file), filename: 'registrar_data_small_sample.csv')
    thesis
  end

  def stub_apt_lambda_success
    stub_request(:post, ENV.fetch('APT_LAMBDA_URL', nil))
      .to_return(
        status: 200,
        body: {
          success: true,
          bag: {
            entries: {
              'manifest-md5.txt' => { md5: 'fakehash' }
            }
          },
          output_zip_s3_uri: 's3://my-bucket/apt-testing/test-one-medium.zip'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_apt_lambda_failure
    stub_request(:post, ENV.fetch('APT_LAMBDA_URL', nil))
      .to_return(
        status: 500,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_apt_lambda_200_failure
    stub_request(:post, ENV.fetch('APT_LAMBDA_URL', nil))
      .to_return(
        status: 200,
        body: {
          success: false,
          error: 'An error occurred (404) when calling the HeadObject operation: Not Found',
          bag: { entries: {} }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  test 'sends report emails on success' do
    stub_apt_lambda_success
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        PreservationSubmissionJob.perform_now([setup_thesis])
      end
    end
  end

  test 'sends report emails on failure' do
    stub_apt_lambda_success
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        PreservationSubmissionJob.perform_now([setup_thesis])
      end
    end
  end

  test 'sends report email if post succeeds but APT fails' do
    stub_apt_lambda_200_failure
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        PreservationSubmissionJob.perform_now([setup_thesis])
      end
    end
  end

  test 'creates an Archivematica payload' do
    stub_apt_lambda_success
    thesis = setup_thesis
    assert_equal 0, thesis.archivematica_payloads.count

    PreservationSubmissionJob.perform_now([thesis])
    assert_equal 1, thesis.archivematica_payloads.count
  end

  test 'creates multiple Archivematica payloads' do
    stub_apt_lambda_success
    thesis_one = setup_thesis
    thesis_two = theses(:engineer)
    assert_equal 0, thesis_one.archivematica_payloads.count
    assert_equal 0, thesis_two.archivematica_payloads.count

    theses = [thesis_one, thesis_two]
    PreservationSubmissionJob.perform_now(theses)
    assert_equal 1, thesis_one.archivematica_payloads.count
    assert_equal 1, thesis_two.archivematica_payloads.count

    PreservationSubmissionJob.perform_now(theses)
    assert_equal 2, thesis_one.archivematica_payloads.count
    assert_equal 2, thesis_two.archivematica_payloads.count
  end

  test 'updates preservation_status to "preserved" after successfully processing a thesis' do
    stub_apt_lambda_success
    thesis = setup_thesis
    PreservationSubmissionJob.perform_now([thesis])
    assert_equal 'preserved', thesis.archivematica_payloads.last.preservation_status
  end

  test 'updates preserved_at to the current time after successfully processing a thesis' do
    stub_apt_lambda_success
    time = DateTime.new.getutc
    Timecop.freeze(time) do
      thesis = setup_thesis
      PreservationSubmissionJob.perform_now([thesis])
      assert_equal time, thesis.archivematica_payloads.last.preserved_at
    end
  end

  test 'throws exceptions when a thesis is unbaggable' do
    stub_apt_lambda_failure
    assert_raises StandardError do
      PreservationSubmissionJob.perform_now([theses[:one]])
    end

    stub_apt_lambda_success
    assert_nothing_raised do
      PreservationSubmissionJob.perform_now([setup_thesis])
    end
  end

  test 'does not create payloads if job fails' do
    stub_apt_lambda_failure
    bad_thesis = theses(:one)
    good_thesis = setup_thesis
    another_good_thesis = setup_thesis_two
    assert_empty bad_thesis.archivematica_payloads
    assert_empty good_thesis.archivematica_payloads
    assert_empty another_good_thesis.archivematica_payloads

    PreservationSubmissionJob.perform_now([good_thesis, bad_thesis, another_good_thesis])

    # first thesis should succeed and have a payload
    assert_equal 1, good_thesis.archivematica_payloads.count

    # second thesis should fail and not have a payload
    assert_empty bad_thesis.archivematica_payloads

    # third thesis should succeed and have a payload, despite prior failure
    assert_equal 1, another_good_thesis.archivematica_payloads.count
  end

  test 'does not create payloads if post succeeds but APT fails' do
    stub_apt_lambda_200_failure
    bad_thesis = theses(:one)
    good_thesis = setup_thesis
    another_good_thesis = setup_thesis_two
    assert_empty bad_thesis.archivematica_payloads
    assert_empty good_thesis.archivematica_payloads
    assert_empty another_good_thesis.archivematica_payloads

    PreservationSubmissionJob.perform_now([good_thesis, bad_thesis, another_good_thesis])
    # first thesis should succeed and have a payload
    assert_equal 1, good_thesis.archivematica_payloads.count

    # second thesis should fail and not have a payload
    assert_empty bad_thesis.archivematica_payloads

    # third thesis should succeed and have a payload, despite prior failure
    assert_equal 1, another_good_thesis.archivematica_payloads.count
  end

  test 'throws exceptions and probably creates payloads when a bad key is provided' do
    skip('Test not implemented yet')
    # Our lambda returns 400 Bad Request with a error body of Invalid input payload
    # This should never happen as we submit it via ENV, but just in case we should understand what it looks like
  end

  test 'retries on 502 Bad Gateway errors' do
    # This syntax will cause the first two calls to return 502, and the third to succeed.
    stub_request(:post, ENV.fetch('APT_LAMBDA_URL', nil))
      .to_return(
        { status: 502 },
        { status: 502 },
        { status: 200, body: {
          success: true,
          bag: {
            entries: {
              'manifest-md5.txt' => { md5: 'fakehash' }
            }
          },
          output_zip_s3_uri: 's3://my-bucket/apt-testing/test-one-medium.zip'
        }.to_json, headers: { 'Content-Type' => 'application/json' } }
      )

    thesis = setup_thesis
    assert_equal 0, thesis.archivematica_payloads.count

    # We need to wrap this in perform_enqueued_jobs so that the retries are actually executed. Our normal syntax only
    # runs a single job, but because we are testing retries this wrapper executes the jobs this job queues.
    perform_enqueued_jobs do
      PreservationSubmissionJob.perform_now([thesis])
    end

    # 3 payloads were created. 2 for the failures, 1 for the success.
    # This isn't ideal, but it's the current behavior. A refactor to using a pre-preservation job to create
    # metadata.csv prior to this job would fix this but is out of scope for now.
    assert_equal 3, thesis.archivematica_payloads.count

    # The last payload should be marked as preserved.
    assert_equal 'preserved', thesis.archivematica_payloads.last.preservation_status
  end
end
