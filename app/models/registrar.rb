class Registrar < ApplicationRecord
  belongs_to :user

  has_one_attached :graduation_list

  VALIDATION_MSGS = {
    graduation_list: 'Required - Attaching a CSV file is required.',
  }

  validates :graduation_list, presence: true
end