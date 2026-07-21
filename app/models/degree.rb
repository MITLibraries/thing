# == Schema Information
#
# Table name: degrees
#
#  id             :integer          not null, primary key
#  abbreviation   :string
#  code_dw        :string           not null
#  name_dspace    :string
#  name_dw        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  degree_type_id :integer
#
# Indexes
#
#  index_degrees_on_code_dw         (code_dw) UNIQUE
#  index_degrees_on_degree_type_id  (degree_type_id)
#
# Foreign Keys
#
#  degree_type_id  (degree_type_id => degree_types.id)
#

class Degree < ApplicationRecord
  has_many :degree_theses
  has_many :theses, through: :degree_theses
  belongs_to :degree_type, optional: true

  validates :code_dw, presence: true

  # Given a row of CSV data from Registrar import, find a degree by Data
  # Warehouse code or create one from the CSV data.
  def self.from_csv(row)
    degree = Degree.find_by(code_dw: row['Degree Code'])
    if degree.nil?
      new_degree = Degree.create!(
        code_dw: row['Degree Code'],
        name_dw: row['Degree Desc'],
        abbreviation: row['Degree Type']
      )
      Rails.logger.warn("New degree created, requires Processor attention: #{new_degree.code_dw}")
      new_degree
    else
      degree
    end
  end
end
