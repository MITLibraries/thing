# == Schema Information
#
# Table name: degrees
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Degree < ApplicationRecord
  has_and_belongs_to_many :theses
end
