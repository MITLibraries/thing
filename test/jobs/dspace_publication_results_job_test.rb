require 'test_helper'

class DspacePublicationResultsJobTest < ActiveJob::TestCase
  def setup
    @good_thesis = theses(:one)
    @bad_thesis = theses(:two)
    @no_handle_thesis = theses(:coauthor)
    @invalid_status_thesis = theses(:with_note)
    Aws.config[:sqs] = {
      stub_responses: {
        receive_message: [
          {
            messages: [
              # success
              { message_id: 'id1', receipt_handle: 'handle1', body: '{"ResultType": "success", "ItemHandle": "http://example.com/handle/123123123", "lastModified": "Thu Sep 09 17: 56: 39 UTC 2021"}',
                message_attributes: { 'PackageID' => { string_value: "etd_#{@good_thesis.id}", data_type: 'String' },
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
                message_attributes: { 'PackageID' => { string_value: "etd_9999999999999", data_type: 'String' },
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

    DspacePublicationResultsJob.perform_now
    @bad_thesis.reload
    @no_handle_thesis.reload
    @invalid_status_thesis.reload
    assert_equal 'Publication error', @bad_thesis.publication_status
    assert_equal 'Publication error', @no_handle_thesis.publication_status
    assert_equal 'Publication error', @invalid_status_thesis.publication_status
  end

  test 'thesis handle is updated' do
    assert_nil @good_thesis.dspace_handle

    DspacePublicationResultsJob.perform_now
    @good_thesis.reload
    assert_equal 'http://example.com/handle/123123123', @good_thesis.dspace_handle
  end

  test 'results hash is populated' do
    results = DspacePublicationResultsJob.perform_now

    # 6 total results confirms that the non-ETD message was skipped
    assert_equal 6, results[:total]
    assert_equal 1, results[:processed]
    assert_equal 5, results[:errors].count
  end

  test 'sends emails' do
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
    assert_includes results[:errors], "Unknown status small victory; cannot continue (thesis #{@invalid_status_thesis.id})"

    # invalid data
    assert_includes results[:errors], "Error reading from SQS queue: undefined method `split' for nil:NilClass"

    # no thesis
    assert_includes results[:errors], "Couldn't find Thesis with 'id'=9999999999999"
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
