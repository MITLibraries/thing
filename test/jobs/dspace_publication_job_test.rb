require 'test_helper'

class DspacePublicationJobTest < ActiveJob::TestCase
  def setup
    @thesis = theses(:one)
    @input_queue_url = ENV.fetch('SQS_INPUT_QUEUE_URL')
    dss_friendly_thesis(@thesis)
  end

  def teardown
    @thesis.files.purge
    @thesis.dspace_metadata.purge
  end

  # Attaching thesis file so tests will pass.
  def dss_friendly_thesis(thesis)
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    thesis.files.first.description = 'My thesis'
    thesis.files.first.purpose = 'thesis_pdf'
    thesis.save
  end

  test 'sends messages' do
    job = DspacePublicationJob.new
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)
    sqs_client.stub_responses(:send_message)
    job.instance_variable_set(:@sqs_client, sqs_client)
    job.instance_variable_set(:@queue_url, @input_queue_url)
    resp = job.send_sqs_message(@thesis)
    assert resp.successful?
  end

  test 'updates publication status when message is sent' do
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)
    sqs_client.stub_responses(:send_message)

    DspacePublicationJob.perform_now(@thesis, sqs_client)
    assert_equal 'Pending publication', @thesis.publication_status
  end

  test 'TimeoutError sets status to publication error' do
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)
    sqs_client.stub_responses(:send_message, Timeout::Error)

    DspacePublicationJob.perform_now(@thesis, sqs_client)
    assert_equal 'Publication error', @thesis.publication_status
  end

  # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Errors/ChecksumError.html
  test 'Aws::Errors::ChecksumError sets status to publication error' do
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)
    sqs_client.stub_responses(:send_message, Aws::Errors::ChecksumError)

    DspacePublicationJob.perform_now(@thesis, sqs_client)
    assert_equal 'Publication error', @thesis.publication_status
  end

  # All 400 and 500 errors use this error type
  # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Errors/ServiceError.html
  test 'Aws::Errors::ServiceError sets status to publication error' do
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)
    sqs_client.stub_responses(:send_message, Aws::Errors::ServiceError)

    DspacePublicationJob.perform_now(@thesis, sqs_client)
    assert_equal 'Publication error', @thesis.publication_status
  end
end
