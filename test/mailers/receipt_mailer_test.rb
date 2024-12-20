require 'test_helper'

class ReceiptMailerTest < ActionMailer::TestCase
  test 'sends confirmation emails for thesis records' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      thesis = theses(:one)
      user = users(:admin)
      email = ReceiptMailer.receipt_email(thesis, user)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      assert_equal ['app@example.com'], email.from
      assert_equal ['admin@example.com'], email.to
      assert_equal 'Your thesis information submission', email.subject
    end
  end

  # This used to be a test that the emails _do_ include ProQuest consent, but we removed that feature in December 2024.
  # This test is to ensure that grad students do not see a nonexistent metadata field in their receipt email.
  test 'confirmation emails for graduate theses do not include ProQuest consent' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      thesis = theses(:doctor)
      user = users(:basic)
      email = ReceiptMailer.receipt_email(thesis, user)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      refute_match '<strong>Consent to send thesis to ProQuest:</strong>', email.body.to_s
    end
  end

  test 'confirmation emails for undergraduate theses do not include ProQuest consent' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      thesis = theses(:one)
      user = users(:yo)
      email = ReceiptMailer.receipt_email(thesis, user)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      refute_match '<strong>Consent to send thesis to ProQuest:</strong>', email.body.to_s
    end
  end

  test 'sends confirmation emails for transfer records' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      transfer = transfers(:valid)
      f = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
      transfer.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
      user = users(:transfer_submitter)
      email = ReceiptMailer.transfer_receipt_email(transfer, user)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      # Test the body of the sent email contains what we expect it to
      assert_equal ['app@example.com'], email.from
      assert_equal ['transfer@example.com'], email.to
      assert_equal 'Thesis files transferred', email.subject
      # Please note: we are not attempting to assert_equal on the entire
      # message because this email currently includes a reference to the
      # transfer.created_at value, which puts us into dealing with timezones.
      # I have lost more hours testing timezones than I care to calculate.
      # Instead, we test for the presence of values we actually care about in
      # the email body (filenames, and a greeting).
      # Test that we are greeting the submitter by name
      assert_match 'Hello Terry,', email.body.to_s
      # Test that the filename we transferred appears in the body of the email
      assert_match 'a_pdf.pdf', email.body.to_s
    end
  end

  test 'does not send emails if DISABLE_ALL_EMAIL is not false' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'true' do
      thesis = theses(:one)
      user = users(:admin)
      email = ReceiptMailer.receipt_email(thesis, user)

      # Send the email, then confirm nothing was queued
      assert_emails 0 do
        email.deliver_now
      end
    end

    ClimateControl.modify DISABLE_ALL_EMAIL: 'foo' do
      thesis = theses(:one)
      user = users(:admin)
      email = ReceiptMailer.receipt_email(thesis, user)

      # Send the email, then confirm nothing was queued
      assert_emails 0 do
        email.deliver_now
      end
    end

    ClimateControl.modify DISABLE_ALL_EMAIL: 'hey why not' do
      thesis = theses(:one)
      user = users(:admin)
      email = ReceiptMailer.receipt_email(thesis, user)

      # Send the email, then confirm nothing was queued
      assert_emails 0 do
        email.deliver_now
      end
    end
  end
end
