# == Schema Information
#
# Table name: authors
#
#  id                   :integer          not null, primary key
#  user_id              :integer          not null
#  thesis_id            :integer          not null
#  graduation_confirmed :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Author < ApplicationRecord
  belongs_to :user
  belongs_to :thesis

  validates :graduation_confirmed, exclusion: [nil]
end
