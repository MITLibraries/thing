class ProquestExportJob < ActiveJob::Base
  queue_as :default

  def perform(partial_harvest, full_harvest)
    export = ProquestExportBatch.new

    # update_all is an option here if performance is poor, but we would need a workaround to update paper_trail
    # versions as update_all does not trigger callbacks.
    if partial_harvest.present?
      partial_harvest.each do |thesis|
        thesis.update(proquest_exported: 'Partial harvest', proquest_export_batch: export)
      end
    end
    if full_harvest.present?
      full_harvest.each { |thesis| thesis.update(proquest_exported: 'Full harvest', proquest_export_batch: export) }
    end

    all_to_export = partial_harvest + full_harvest
    attach_and_send(export, all_to_export, partial_harvest)
  end

  private

  def attach_and_send(export, all_to_export, partial_harvest)
    export_json = export.build_json(all_to_export)
    budget_report = export.build_budget_report(partial_harvest)
    export.proquest_export.attach(io: StringIO.new(export_json),
                                  filename: "proquest_export_#{Date.today.strftime('%Y%m%d_%s')}.json",
                                  content_type: 'application/json')
    export.budget_report.attach(io: StringIO.new(budget_report),
                                filename: "proquest_budget_report_#{Date.today.strftime('%Y%m%d_%s')}.csv",
                                content_type: 'application/csv')
    export.save
    BatchMailer.proquest_export_email(export.proquest_export.blob, export.budget_report.blob, all_to_export.count,
                                      partial_harvest.count).deliver_later
  end
end
