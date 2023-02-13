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

  test 'JSON is attached to an export' do
    assert_empty ProquestExportBatch.all
    ProquestExportJob.perform_now(Thesis.all, Thesis.all)
    latest_batch = ProquestExportBatch.last
    assert_not_nil latest_batch.proquest_export.blob
    assert_equal 'application/json', latest_batch.proquest_export.blob.content_type
  end

  test 'budget report is attached to an export' do
    assert_empty ProquestExportBatch.all
    ProquestExportJob.perform_now(Thesis.all, Thesis.all)
    latest_batch = ProquestExportBatch.last
    assert_not_nil latest_batch.budget_report.blob
    assert_equal 'application/csv', latest_batch.budget_report.blob.content_type
  end

  test 'budget report includes only theses exported for partial harvest' do
    ProquestExportJob.perform_now([theses(:proquest_export_partial)], [theses(:proquest_export_full)])
    csv = CSV.parse(ProquestExportBatch.last.budget_report.blob.download)
    assert_equal 2, csv.length
    assert_not_equal theses(:proquest_export_full).dspace_handle, csv[1][4]
    assert_equal theses(:proquest_export_partial).dspace_handle, csv[1][4]
  end

  test 'sends batch and budget report emails' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_emails 1 do
        ProquestExportJob.perform_now(Thesis.all, Thesis.all)
      end
    end
  end
end
