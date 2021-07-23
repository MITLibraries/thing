# == Schema Information
#
# Table name: departments
#
#  id                   :integer          not null, primary key
#  name_dw              :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  code_dw              :string           default(""), not null
#  name_dspace          :string
#  authority_key_dspace :string
#

class Department < ApplicationRecord
  has_many :department_theses
  has_many :theses, through: :department_theses
  has_many :transfers
  has_many :submitters
  has_many :users, through: :submitters

  validates :name_dw, presence: true
  validates :code_dw, presence: true

  # Given a row of CSV data from Registrar import, find a department by Data
  # Warehouse code or create one from the CSV data.
  def self.from_csv(row)
    department = Department.find_by(code_dw: row['Degree Department'])
    if department.nil?
      new_department = Department.create!(
        code_dw: row['Degree Department'],
        name_dw: row['Dept Name In Commencement Bk']
      )
      Rails.logger.warn("New department created, requires Processor attention: #{new_department.code_dw}")
      new_department
    else
      department
    end
  end
end
