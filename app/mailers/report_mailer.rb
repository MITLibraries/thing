class ReportMailer < ApplicationMailer
  def registrar_import_email(registrar, results)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @registrar = registrar
    @results = results
    mail(from: "MIT Libraries <#{ENV['THESIS_ADMIN_EMAIL']}>",
         to: ENV['THESIS_ADMIN_EMAIL'],
         cc: ENV['MAINTAINER_EMAIL'],
         subject: 'Registrar data import summary')
  end
end
