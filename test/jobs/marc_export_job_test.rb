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
end
