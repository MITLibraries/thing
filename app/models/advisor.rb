# == Schema Information
#
# Table name: advisors
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Advisor < ApplicationRecord
  has_and_belongs_to_many :theses
end
