# == Schema Information
#
# Table name: copyrights
#
#  id                  :integer          not null, primary key
#  holder              :text             not null
#  display_to_author   :boolean          not null
#  display_description :text             not null
#  statement_dspace    :text             not null
#  url                 :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Copyright < ApplicationRecord
  has_many :theses

  validates :holder, presence: true
  validates :display_to_author, inclusion: [true, false]
  validates :display_description, presence: true
  validates :statement_dspace, presence: true

  scope :display_to_author, -> { where(display_to_author: true) }
end
