# == Schema Information
#
# Table name: theses
#
#  id         :integer          not null, primary key
#  title      :string           not null
#  abstract   :text             not null
#  grad_date  :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#  right_id   :integer
#

class Thesis < ApplicationRecord
  belongs_to :user
  belongs_to :right
  has_and_belongs_to_many :departments
  has_and_belongs_to_many :degrees
  has_and_belongs_to_many :advisors

  validates :title, presence: true
  validates :abstract, presence: true
  validates :grad_date, presence: true
  validates :departments, presence: true
  validates :degrees, presence: true
  validates :advisors, presence: true
end
