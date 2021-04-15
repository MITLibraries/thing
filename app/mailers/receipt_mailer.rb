class ReceiptMailer < ApplicationMailer
  def receipt_email(thesis, user)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails
    @user = user
    @thesis = thesis
    mail(from: "MIT Libraries <#{ENV['THESIS_ADMIN_EMAIL']}>",
         to: @user.email,
         subject: 'Your thesis information submission')
  end

  def transfer_receipt_email(transfer, user)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails
    @user = user
    @transfer = transfer
    mail(from: "MIT Libraries <#{ENV['THESIS_ADMIN_EMAIL']}>",
         to: @user.email,
         subject: 'Thesis files transferred')
  end
end
