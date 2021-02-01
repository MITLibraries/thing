class ReceiptMailer < ApplicationMailer
  def receipt_email(thesis)
    return if ENV['DISABLE_ALL_EMAIL'] # allows PR builds to disable emails
    @thesis = thesis
    emails = thesis.users.map { |u| u.email }.join(",")
    mail(to: emails,
         cc: ENV['THESIS_ADMIN_EMAIL'],
         subject: 'Thesis Submission Receipt - MIT Libraries')
  end
end
