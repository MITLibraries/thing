# Preview all emails at http://localhost:3000/rails/mailers/receipt_mailer
class ReceiptMailerPreview < ActionMailer::Preview
  def receipt_email
    ReceiptMailer.receipt_email(Thesis.first, User.first)
  end
end
