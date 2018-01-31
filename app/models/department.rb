# == Schema Information
#
# Table name: departments
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Department < ApplicationRecord
  has_many :department_theses
  has_many :theses, through: :department_theses

  validates :name, presence: true
end
