require 'test_helper'

class BatchMailerTest < ActionMailer::TestCase
  test 'sends emails for MARC batch exports' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one), theses(:two)]
      marc_zip_file = MarcBatch.new(theses, 'marc.xml', 'marc.zip').build
      json_file = CatalogBatch.new(theses, 'marc.json').build
      email = BatchMailer.marc_batch_email('marc.zip', marc_zip_file, 'marc.json', json_file, theses)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      # Make sure it was sent to the right person with the expected attachments.
      assert_equal ['app@example.com'], email.from
      assert_equal ['test-metadata@example.com'], email.to
      assert_equal 'ETD metadata batch export', email.subject
      assert_equal 2, email.attachments.count
      filenames = email.attachments.map(&:filename)
      assert_includes filenames, 'marc.zip'
      assert_includes filenames, 'marc.json'
      assert_includes '2 theses', email.body.to_s
    end
  end

  test 'zip file is attached with correct mimetype' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one), theses(:two)]
      marc_zip_file = MarcBatch.new(theses, 'marc.xml', 'marc.zip').build
      json_file = CatalogBatch.new(theses, 'marc.json').build
      email = BatchMailer.marc_batch_email('marc.zip', marc_zip_file, 'marc.json', json_file, theses)
      attachment = email.attachments['marc.zip']
      assert_equal 'application/zip; filename=marc.zip', attachment.content_type
    end
  end

  test 'sends emails for ProQuest batch exports' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:doctor), theses(:engineer)]
      export = ProquestExportBatch.new
      export_json = export.build_json(theses)
      export_csv = export.build_budget_report(theses)
      export.proquest_export.attach(io: StringIO.new(export_json),
                                    filename: 'pq.json',
                                    content_type: 'application/json')
      export.budget_report.attach(io: StringIO.new(export_csv),
                                    filename: 'pq.csv',
                                    content_type: 'application/csv')
      export.save
      email = BatchMailer.proquest_export_email(export.proquest_export, export.budget_report,  theses.count,
                                                theses.count)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      # Make sure it was sent to the right person with the expected attachment.
      assert_equal ['app@example.com'], email.from
      assert_equal ['test@example.com'], email.to
      assert_equal 'ETD ProQuest export', email.subject
      assert_equal 'pq.json', email.attachments.first.filename
      assert_equal 'pq.csv', email.attachments.second.filename
      assert_includes '2 theses', email.body.to_s
      assert_includes '1 doctoral theses', email.body.to_s
    end
  end
end
