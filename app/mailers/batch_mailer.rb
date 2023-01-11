class BatchMailer < ApplicationMailer
  def marc_batch_email(marc_zip_filename, marc_zip_file, theses)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @theses = theses
    attachments[marc_zip_filename.to_s] = File.binread(marc_zip_file)
    mail(from: "MIT Libraries <#{ENV['THESIS_ADMIN_EMAIL']}>",
         to: ENV['METADATA_ADMIN_EMAIL'],
         cc: ENV['MAINTAINER_EMAIL'],
         subject: 'ETD MARC batch export')
  end

  def proquest_export_email(json_blob, thesis_count)
    return unless ENV.fetch('DISABLE_ALL_EMAIL', 'true') == 'false' # allows PR builds to disable emails

    @thesis_count = thesis_count
    attachments[json_blob.filename.to_s] = {
      mime_type: json_blob.content_type,
      content: json_blob.download
    }
    mail(from: "MIT Libraries <#{ENV['THESIS_ADMIN_EMAIL']}>",
         to: ENV['THESIS_ADMIN_EMAIL'],
         cc: ENV['MAINTAINER_EMAIL'],
         subject: 'ETD ProQuest export')
  end
end
