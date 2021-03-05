# == Schema Information
#
# Table name: licenses
#
#  id                  :integer          not null, primary key
#  display_description :text             not null
#  license_type        :text             not null
#  url                 :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class License < ApplicationRecord
  has_many :theses

  validates :display_description, presence: true
  validates :license_type, presence: true
end
