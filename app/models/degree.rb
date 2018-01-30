# == Schema Information
#
# Table name: degrees
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Degree < ApplicationRecord
  has_many :degree_theses
  has_many :theses, through: :degree_theses

  validates :name, presence: true
end
