class ApplicationMailer < ActionMailer::Base
  default from: ENV['THESIS_ADMIN_EMAIL']
  layout 'mailer'
end
