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
#

class Thesis < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :departments
  has_and_belongs_to_many :degrees
end
