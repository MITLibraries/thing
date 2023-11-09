class ReportMailer < ApplicationMailer
  def registrar_import_email(registrar, results)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @registrar = registrar
    @results = results
    mail(from: "MIT Libraries <#{ENV['ETD_APP_EMAIL']}>",
         to: ENV['THESIS_ADMIN_EMAIL'],
         cc: ENV['MAINTAINER_EMAIL'],
         subject: 'Registrar data import summary')
  end

  def publication_results_email(results)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @results = results
    mail(from: "MIT Libraries <#{ENV['ETD_APP_EMAIL']}>",
         to: ENV['THESIS_ADMIN_EMAIL'],
         cc: ENV['MAINTAINER_EMAIL'],
         subject: 'DSpace publication results summary')
  end

  def preservation_results_email(results)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @results = results
    mail(from: "MIT Libraries <#{ENV['ETD_APP_EMAIL']}>",
         to: ENV['THESIS_ADMIN_EMAIL'],
         cc: ENV['MAINTAINER_EMAIL'],
         subject: 'Archivematica preservation submission results summary')
  end
end
