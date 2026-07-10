class ReportMailer < ApplicationMailer
  def registrar_import_email(registrar, results, multiple_hold_users = [])
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @registrar = registrar
    @results = results
    @multiple_hold_users = multiple_hold_users
    mail(from: "MIT Libraries <#{ENV.fetch('ETD_APP_EMAIL', nil)}>",
         to: ENV.fetch('THESIS_ADMIN_EMAIL', nil),
         cc: ENV.fetch('MAINTAINER_EMAIL', nil),
         subject: 'Registrar data import summary')
  end

  def publication_results_email(results)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @results = results
    mail(from: "MIT Libraries <#{ENV.fetch('ETD_APP_EMAIL', nil)}>",
         to: ENV.fetch('THESIS_ADMIN_EMAIL', nil),
         cc: ENV.fetch('MAINTAINER_EMAIL', nil),
         subject: 'DSpace publication results summary')
  end

  def preservation_results_email(results)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @results = results
    mail(from: "MIT Libraries <#{ENV.fetch('ETD_APP_EMAIL', nil)}>",
         to: ENV.fetch('THESIS_ADMIN_EMAIL', nil),
         cc: ENV.fetch('MAINTAINER_EMAIL', nil),
         subject: 'Archivematica preservation submission results summary')
  end
end
