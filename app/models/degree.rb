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
end
