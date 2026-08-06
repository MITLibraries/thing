require 'test_helper'

class MarcExportJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test 'sends batch email' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one)]
      assert_emails 1 do
        MarcExportJob.perform_now(theses)
      end
    end
  end

  test 'sent email attachments use expected filename format' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one)]
      Timecop.freeze(Time.utc(2022, 2, 14, 17, 10, 0)) do
        email = MarcExportJob.perform_now(theses)
        assert_equal 'marc_220214_17_10.zip', email.attachments.first.filename
      end
    end
  end

  test 'sent email includes both MARC and JSON attachments' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one)]
      Timecop.freeze(Time.utc(2022, 2, 14, 17, 10, 0)) do
        email = MarcExportJob.perform_now(theses)
        assert_equal 2, email.attachments.count
        filenames = email.attachments.map(&:filename)
        assert(filenames.include?('marc_220214_17_10.zip'))
        assert(filenames.include?('marc_220214_17_10.json'))
      end
    end
  end

  test 'JSON attachment is valid JSON' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      theses = [theses(:one)]
      email = MarcExportJob.perform_now(theses)
      json_attachment = email.attachments.find { |a| a.filename.ends_with?('.json') }
      assert_not_nil(json_attachment)

      json_data = JSON.parse(json_attachment.body.to_s)
      assert(json_data.key?('theses'))
    end
  end
end
