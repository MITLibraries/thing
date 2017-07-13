# == Schema Information
#
# Table name: rights
#
#  id         :integer          not null, primary key
#  statement  :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Right < ApplicationRecord
  has_many :theses

  validates :statement, presence: true
end
