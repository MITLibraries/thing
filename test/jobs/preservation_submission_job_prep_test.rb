require 'test_helper'

class PreservationSubmissionPrepJobTest < ActiveJob::TestCase

  test 'queues 1 job for 1 thesis' do
    theses = [theses(:one)].to_a

    assert_enqueued_jobs 1 do
      PreservationSubmissionPrepJob.perform_now(theses)
    end
  end

  test 'queues 2 jobs for 2 theses' do
    theses = [theses(:one), theses(:two)].to_a

    assert_enqueued_jobs 2 do
      PreservationSubmissionPrepJob.perform_now(theses)
    end
  end

  test 'queues same number of theses it receives' do
    theses = Thesis.in_review.to_a

    assert_enqueued_jobs theses.count do
      PreservationSubmissionPrepJob.perform_now(theses)
    end
  end
end
