require 'test_helper'

class ProquestExportJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test 'proquest_exported values are updated' do
    assert_equal 'Not exported', theses(:one).proquest_exported
    assert_equal 'Not exported', theses(:with_hold).proquest_exported

    ProquestExportJob.perform_now([theses(:with_hold)], [theses(:one)])
    assert_equal 'Full harvest', theses(:one).proquest_exported
    assert_equal 'Partial harvest', theses(:with_hold).proquest_exported
  end

  test 'batch export is created' do
    pq_export_batch_count = ProquestExportBatch.count
    ProquestExportJob.perform_now(Thesis.all, Thesis.all)
    assert_equal pq_export_batch_count + 1, ProquestExportBatch.count
  end

  # This test will require updating if we begin using ProQuestExportBatch fixtures.
  test 'JSON is attached to an export' do
    assert_empty ProquestExportBatch.all
    ProquestExportJob.perform_now(Thesis.all, Thesis.all)
    latest_batch = ProquestExportBatch.last
    assert_not_nil latest_batch.proquest_export.blob
    assert_equal 'application/json', latest_batch.proquest_export.blob.content_type
  end

  test 'sends batch email' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_emails 1 do
        ProquestExportJob.perform_now(Thesis.all, Thesis.all)
      end
    end
  end
end
