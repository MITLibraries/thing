require 'test_helper'

class BatchMailerTest < ActionMailer::TestCase
  test 'sends emails for MARC batch exports' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one), theses(:two)]
      zip_file =  MarcBatch.new(theses, 'marc.xml', 'marc.zip').build
      email = BatchMailer.marc_batch_email('marc.zip', zip_file, theses)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      # Make sure it was sent to the right person with the expected attachment.
      assert_equal ['app@example.com'], email.from
      assert_equal ['test-metadata@example.com'], email.to
      assert_equal 'ETD MARC batch export', email.subject
      assert_equal 'marc.zip', email.attachments.first.filename
      assert_includes '2 theses', email.body.to_s
    end
  end

  test 'zip file is attached with correct mimetype' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one), theses(:two)]
      zip_file =  MarcBatch.new(theses, 'marc.xml', 'marc.zip').build
      email = BatchMailer.marc_batch_email('marc.zip', zip_file, theses)
      attachment = email.attachments['marc.zip']
      assert_equal 'application/zip; filename=marc.zip', attachment.content_type
    end
  end

  test 'sends emails for ProQuest batch exports' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:doctor), theses(:engineer)]
      export = ProquestExportBatch.new
      export_json = export.build_json(theses)
      export.proquest_export.attach(io: StringIO.new(export_json),
                                    filename: 'pq.json',
                                    content_type: 'application/json')
      export.save
      email = BatchMailer.proquest_export_email(export.proquest_export, theses)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      # Make sure it was sent to the right person with the expected attachment.
      assert_equal ['app@example.com'], email.from
      assert_equal ['test@example.com'], email.to
      assert_equal 'ETD ProQuest export', email.subject
      assert_equal 'pq.json', email.attachments.first.filename
      assert_includes '2 theses', email.body.to_s
    end
  end
end
