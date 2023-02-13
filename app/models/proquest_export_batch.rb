class ProquestExportBatch < ApplicationRecord
  require 'csv'

  has_many :theses

  has_one_attached :proquest_export
  has_one_attached :budget_report

  def build_json(theses)
    thesis_records = theses.map { |thesis| record(thesis) }
    { records: thesis_records }.to_json
  end

  def build_budget_report(partial_export_theses)
    CSV.generate do |csv|
      csv << ['author name(s)', 'department(s)', 'degree type(s)', 'degree period', 'handle', 'export date']
      partial_export_theses.each do |thesis|
        csv << [author_names(thesis), departments(thesis), degree_types(thesis), thesis.grad_date, thesis.dspace_handle,
                Date.today.strftime('%m-%d-%Y')].flatten
      end
    end
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

  def author_names(thesis)
    thesis.users.map(&:name).join('; ')
  end

  def departments(thesis)
    thesis.departments.map(&:name_dw).join('; ')
  end

  def degree_types(thesis)
    thesis.degrees.map { |degree| degree.degree_type.name }.join('; ')
  end
end
