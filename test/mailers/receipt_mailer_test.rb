require 'test_helper'

class ReceiptMailerTest < ActionMailer::TestCase
  def test_receipt_email
    thesis = theses(:one)
    email = ReceiptMailer.receipt_email(thesis)

    # Send the email, then test that it got queued
    assert_emails 1 do
      email.deliver_now
    end

    # Test the body of the sent email contains what we expect it to
    assert_equal ['test@example.com'], email.from
    assert_equal ['yo@example.com'], email.to
    assert_equal ['test@example.com'], email.cc
    assert_equal 'Thesis Submission Receipt - MIT Libraries', email.subject
    assert_equal read_fixture('receipt_email').join, email.body.to_s
  end

  def test_disable_all_email
    ClimateControl.modify DISABLE_ALL_EMAIL: 'true' do
      thesis = theses(:one)
      email = ReceiptMailer.receipt_email(thesis)

      # Send the email, then confirm nothing was queued
      assert_emails 0 do
        email.deliver_now
      end
    end
  end
end
