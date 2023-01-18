class ApplicationMailer < ActionMailer::Base
  default from: ENV['ETD_APP_EMAIL']
  layout 'mailer'
end
