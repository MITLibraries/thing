require 'test_helper'

class ReportMailerTest < ActionMailer::TestCase
  test 'sends reports for registrar data imports' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      registrar = registrar(:valid)
      results = { read: 0, processed: 0, new_users: 0, new_theses: 1, updated_theses: 0, new_degrees: [], new_depts: [],
                  errors: [] }
      email = ReportMailer.registrar_import_email(registrar, results)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      # Make sure it was sent to the right person with the right content. We are only testing a subset of the body
      # rather than a full sample email to avoid future testing complications
      assert_equal ['test@example.com'], email.from
      assert_equal ['test@example.com'], email.to
      assert_equal 'Registrar data import summary', email.subject
      assert_match 'New theses: 1', email.body.to_s
    end
  end
end
