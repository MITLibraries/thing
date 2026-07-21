# == Schema Information
#
# Table name: registrars
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_registrars_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Registrar < ApplicationRecord
  belongs_to :user

  has_one_attached :graduation_list

  VALIDATION_MSGS = {
    graduation_list: 'Required - Attaching a CSV file is required.'
  }.freeze

  validates :graduation_list, presence: true
end
