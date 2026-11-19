require 'test_helper'

class DspacePublicationJobTest < ActiveJob::TestCase
  def setup
    @thesis = theses(:one)
    @input_queue_url = ENV.fetch('SQS_INPUT_QUEUE_URL')
    dss_friendly_thesis(@thesis)
    @thesis.related_hold_exceptions.create!(related_thesis: theses(:with_hold))
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

  test 'a new related held thesis blocks publication despite an existing reviewed exception' do
    @thesis.update_columns(publication_status: 'Publication review')
    @thesis.related_hold_exceptions.load
    @thesis.users.load
    @thesis.holds.load
    Author.create!(user: users(:yo), thesis: theses(:downloaded), graduation_confirmed: true)
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)

    DspacePublicationJob.perform_now(@thesis, sqs_client)

    assert_empty sqs_client.api_requests
    assert_not @thesis.dspace_metadata.attached?
    assert_equal 'Not ready for publication', @thesis.reload.publication_status
  end

  test 'a revoked exception blocks publication even when the job has cached the exception' do
    @thesis.related_hold_exceptions.load
    RelatedHoldException.find_by!(thesis: @thesis).destroy!
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)

    DspacePublicationJob.perform_now(@thesis, sqs_client)

    assert_empty sqs_client.api_requests
    assert_not @thesis.dspace_metadata.attached?
    assert_equal 'Not ready for publication', @thesis.reload.publication_status
  end

  test 'reviewed related holds cannot waive a new direct hold before publication' do
    @thesis.holds.load
    holds(:valid).update!(thesis: @thesis)
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)

    DspacePublicationJob.perform_now(@thesis, sqs_client)

    assert_empty sqs_client.api_requests
    assert_not @thesis.dspace_metadata.attached?
    assert_equal 'Not ready for publication', @thesis.reload.publication_status
  end

  test 'a blocked publication leaves existing metadata and protected publication status intact' do
    @thesis.dspace_metadata.attach(io: StringIO.new('{}'), filename: 'existing.json', content_type: 'application/json')
    metadata_blob_id = @thesis.dspace_metadata.blob.id
    @thesis.update!(publication_status: 'Pending publication')
    @thesis.related_hold_exceptions.destroy_all
    sqs_client = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION'), stub_responses: true)

    DspacePublicationJob.perform_now(@thesis, sqs_client)

    assert_empty sqs_client.api_requests
    assert_equal metadata_blob_id, @thesis.reload.dspace_metadata.blob.id
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
