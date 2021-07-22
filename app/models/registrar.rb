# == Schema Information
#
# Table name: registrars
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Registrar < ApplicationRecord
  belongs_to :user

  has_one_attached :graduation_list

  VALIDATION_MSGS = {
    graduation_list: 'Required - Attaching a CSV file is required.'
  }.freeze

  validates :graduation_list, presence: true
end
