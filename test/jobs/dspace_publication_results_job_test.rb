require 'test_helper'

class DspacePublicationResultsJobTest < ActiveJob::TestCase
  def setup
    @good_thesis = theses(:bachelor)
    @bad_thesis = theses(:two)
    @bad_checksum = theses(:doctor)
    @no_handle_thesis = theses(:coauthor)
    @invalid_status_thesis = theses(:with_note)
    @valid_with_no_local_files = theses(:one)
    Aws.config[:sqs] = {
      stub_responses: {
        receive_message: [
          {
            messages: [
              # success
              { message_id: 'id1', receipt_handle: 'handle1',
                body: '{"ResultType": "success", "ItemHandle": "http://example.com/handle/123123123", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021", "Bitstreams": [{ "BitstreamName": "a_pdf.pdf", "BitstreamUUID": "fakeuuidshhhhh",  "BitstreamChecksum": { "value": "2800ec8c99c60f5b15520beac9939a46", "checkSumAlgorithm": "MD5"}}]}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@good_thesis.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },

              # success but invalid checksum
              { message_id: 'id1a', receipt_handle: 'handle1a',
                body: '{"ResultType": "success", "ItemHandle": "http://example.com/handle/123123123", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021", "Bitstreams": [{ "BitstreamName": "a_pdf.pdf", "BitstreamUUID": "fakeuuidshhhhh",  "BitstreamChecksum": { "value": "borkedchecksum", "checkSumAlgorithm": "MD5"}}]}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@bad_checksum.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },

              # success but thesis no longer has files locally
              { message_id: 'id1a', receipt_handle: 'handle1a',
                body: '{"ResultType": "success", "ItemHandle": "http://example.com/handle/123123123", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021", "Bitstreams": [{ "BitstreamName": "a_pdf.pdf", "BitstreamUUID": "fakeuuidshhhhh",  "BitstreamChecksum": { "value": "2800ec8c99c60f5b15520beac9939a46", "checkSumAlgorithm": "MD5"}}]}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@valid_with_no_local_files.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },

              # 500 error
              { message_id: 'id2', receipt_handle: 'handle2', body: '{"ResultType": "error", "ErrorTimestamp": "Thu Sep 09 17: 56: 39 UTC 2021", "ErrorInfo": "Stuff broke", "ExceptionMessage": "500 Server Error: Internal Server Error", "ExceptionTraceback": "Full unformatted stack trace of the Exception"}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@bad_thesis.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },
              # no handle
              { message_id: 'id3', receipt_handle: 'handle3', body: '{"ResultType": "success", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021"}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@no_handle_thesis.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },

              # invalid result type
              { message_id: 'id4', receipt_handle: 'handle4', body: '{"ResultType": "small victory", "ItemHandle": "http://example.com/handle/123123124", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021"}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@invalid_status_thesis.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },

              # no record
              { message_id: 'id5', receipt_handle: 'handle5', body: '{"ResultType": "success", "ItemHandle": "http://example.com/handle/123123125", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021"}',
                message_attributes: { 'PackageID' => { string_value: 'etd_9999999999999', data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },

              # bad data
              { message_id: 'id6', receipt_handle: 'handle6', body: '{"ResultType": "success", "ItemHandle": "http://example.com/handle/123123126", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021"}',
                message_attributes: { 'PackageID' => { string_value: nil, data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } },

              # bad submission source
              { message_id: 'id7', receipt_handle: 'handle7', body: '{"ResultType": "success", "ItemHandle": "http://example.com/handle/123123126", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021"}',
                message_attributes: { 'PackageID' => { string_value: nil, data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'Down the street', data_type: 'String' } } }
            ]
          },
          { messages: [] }
        ]
      }
    }
  end

  def teardown
    # Reset state just in case
    Aws.config.clear
  end

  test "thesis status changes to published if it's good" do
    assert_not_equal 'Published', @good_thesis.publication_status

    DspacePublicationResultsJob.perform_now
    @good_thesis.reload
    assert_equal 'Published', @good_thesis.publication_status
  end

  test "thesis status changes to errored if it's bad" do
    assert_not_equal 'Publication error', @bad_thesis.publication_status
    assert_not_equal 'Publication error', @no_handle_thesis.publication_status
    assert_not_equal 'Publication error', @invalid_status_thesis.publication_status
    assert_not_equal 'Publication error', @bad_checksum.publication_status

    DspacePublicationResultsJob.perform_now
    @bad_thesis.reload
    @no_handle_thesis.reload
    @invalid_status_thesis.reload
    @bad_checksum.reload
    assert_equal 'Publication error', @bad_thesis.publication_status
    assert_equal 'Publication error', @no_handle_thesis.publication_status
    assert_equal 'Publication error', @invalid_status_thesis.publication_status
    # assert_equal 'Publication error', @bad_checksum.publication_status # SQS mocks need to be updated
  end

  test 'thesis handle is updated' do
    assert_nil @good_thesis.dspace_handle
    assert_nil @bad_checksum.dspace_handle

    DspacePublicationResultsJob.perform_now
    @good_thesis.reload
    @bad_checksum.reload

    assert_equal 'http://example.com/handle/123123123', @good_thesis.dspace_handle
    # assert_equal 'http://example.com/handle/123123123', @bad_checksum.dspace_handle # SQS mocks need to be updated
  end

  test 'results hash is populated' do
    skip('SQS mocks need to be updated')
    results = DspacePublicationResultsJob.perform_now

    # 6 total results confirms that the non-ETD message was skipped
    assert_equal 8, results[:total]
    assert_equal 3, results[:processed]
    assert_equal 7, results[:errors].count
  end

  test 'sends emails' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        DspacePublicationResultsJob.perform_now
      end
    end
  end

  # This is a regression test to cover a bug where the job sends no emails if there are only errors
  test 'sends emails if there are no successes' do
    Aws.config[:sqs] = {
      stub_responses: {
        receive_message: [
          {
            messages: [
              # 500 error
              { message_id: 'id2', receipt_handle: 'handle2', body: '{"ResultType": "error", "ErrorTimestamp": "Thu Sep 09 17: 56: 39 UTC 2021", "ErrorInfo": "Stuff broke", "ExceptionMessage": "500 Server Error: Internal Server Error", "ExceptionTraceback": "Full unformatted stack trace of the Exception"}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@bad_thesis.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } }
            ]
          },
          { messages: [] }
        ]
      }
    }
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        DspacePublicationResultsJob.perform_now
      end
    end
  end

  test 'logs bad errors as expected' do
    results = DspacePublicationResultsJob.perform_now

    # no handle
    assert_includes results[:errors], "Handle not provided; cannot continue (thesis #{@no_handle_thesis.id})"

    # invalid result type
    assert_includes results[:errors],
                    "Unknown status small victory; cannot continue (thesis #{@invalid_status_thesis.id})"

    # invalid data
    assert_includes results[:errors], "Error reading from SQS queue: undefined method `split' for nil:NilClass"

    # no thesis
    assert_includes results[:errors], "Couldn't find Thesis with 'id'=9999999999999"

    # bad checksum
    # SQS mocks need to be updated
    # assert_includes results[:errors], 'Thesis 532738922 with handle http://example.com/handle/123123123 was published ' \
    #                                   'with non matching checksums. ETD checksums ' \
    #                                   '["2800ec8c99c60f5b15520beac9939a46"] dspace checksums ["borkedchecksum"]. This ' \
    #                                   'requires immediate attention to either manually replace the problem file in ' \
    #                                   'DSpace or delete the entire thesis from DSpace to ensure that nobody is able ' \
    #                                   'to download the broken file.'

    # no local files to checksum
    assert_includes results[:errors], 'Thesis 980190962 updated to status Publication error due to inability to ' \
                                      'validate checksums as no local files were attached to the record. This ' \
                                      'requires staff to manually check the ETD record and DSpace record and take ' \
                                      'appropriate action.'
  end

  test 'enqueues preservation submission prep job' do
    assert_enqueued_with(job: PreservationSubmissionJob) do
      DspacePublicationResultsJob.perform_now
    end
  end

  # There is only one valid thesis in our stubbed responses because one processed thesis has invalid checksums and
  # the other no longer has files locally.
  test 'only valid theses are ready for preservation' do
    results = DspacePublicationResultsJob.perform_now
    assert_equal 1, results[:preservation_ready].count
  end

  test 'enqueues MARC export job' do
    assert_enqueued_with(job: MarcExportJob) do
      DspacePublicationResultsJob.perform_now
    end
  end

  # The requirements are less strict than for preservation because any published thesis should be exported as MARC, even
  # if it's not valid by preservation standards.
  test 'only published theses are exported as MARC' do
    skip('SQS mocks need to be updated')
    results = DspacePublicationResultsJob.perform_now
    assert_equal 3, results[:marc_exports].count
  end

  test 'preservation and MARC export jobs are not enqueued if no theses are ready for preservation or export' do
    Aws.config[:sqs] = {
      stub_responses: {
        receive_message: [
          {
            messages: [
              # invalid result type
              { message_id: 'id4', receipt_handle: 'handle4', body: '{"ResultType": "small victory", "ItemHandle": "http://example.com/handle/123123124", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021"}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@invalid_status_thesis.id}", data_type: 'String' },
                                      'SubmissionSource' => { string_value: 'ETD', data_type: 'String' } } }
            ]
          },
          { messages: [] }
        ]
      }
    }
    DspacePublicationResultsJob.perform_now
    assert_enqueued_jobs 0
  end

  test 'do nothing if no messages in queue' do
    Aws.config[:sqs] = {
      stub_responses: {
        receive_message: [
          { messages: [] }
        ]
      }
    }
    results = DspacePublicationResultsJob.perform_now
    assert_equal 0, results[:total]
    assert_equal 0, results[:processed]
    assert_equal 0, results[:errors].count
  end
end
