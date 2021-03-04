# == Schema Information
#
# Table name: departments
#
#  id          :integer          not null, primary key
#  name_dw     :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  code_dw     :string           default(""), not null
#  name_dspace :string
#

class Department < ApplicationRecord
  has_many :department_theses
  has_many :theses, through: :department_theses
  has_many :transfers
  has_many :submitters
  has_many :users, through: :submitters

  validates :name_dw, presence: true
  validates :code_dw, presence: true
end
