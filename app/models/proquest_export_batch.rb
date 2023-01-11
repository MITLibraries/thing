class ProquestExportBatch < ApplicationRecord
  has_many :theses

  has_one_attached :proquest_export
  has_one_attached :budget_report

  def build_json(theses)
    thesis_records = theses.map { |thesis| record(thesis) }
    { records: thesis_records }.to_json
  end

  private

  def record(thesis)
    {
      dspace_handle: thesis.dspace_handle,
      full_harvest: evaluate_export_type(thesis)
    }
  end

  def evaluate_export_type(thesis)
    thesis.proquest_exported == 'Full harvest'
  end
end
