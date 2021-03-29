require 'test_helper'

class ReceiptMailerTest < ActionMailer::TestCase
  test 'sends confirmation emails' do
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      thesis = theses(:one)
      user = users(:admin)
      email = ReceiptMailer.receipt_email(thesis, user)

      # Send the email, then test that it got queued
      assert_emails 1 do
        email.deliver_now
      end

      # Test the body of the sent email contains what we expect it to
      assert_equal ['test@example.com'], email.from
      assert_equal ['admin@example.com'], email.to
      assert_equal 'Your thesis information submission', email.subject
      assert_equal read_fixture('receipt_email').join, email.body.to_s
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
