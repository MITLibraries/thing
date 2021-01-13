# == Schema Information
#
# Table name: hold_sources
#
#  id         :integer          not null, primary key
#  source     :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class HoldSource < ApplicationRecord
  has_many :holds

  validates :source, presence: true
end
