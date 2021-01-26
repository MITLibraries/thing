# == Schema Information
#
# Table name: advisors
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Advisor < ApplicationRecord
  has_many :advisor_theses
  has_many :theses, through: :advisor_theses

  validates :name, presence: true
end
