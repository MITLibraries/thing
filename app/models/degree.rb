# == Schema Information
#
# Table name: degrees
#
#  id             :integer          not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  code_dw        :string           not null
#  name_dw        :string
#  abbreviation   :string
#  name_dspace    :string
#  degree_type_id :integer
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
      Rails.logger.warn("New degree created, requires Processor attention: " + new_degree.code_dw)
      return new_degree
    else
      return degree
    end
  end
end
