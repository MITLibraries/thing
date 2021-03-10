# == Schema Information
#
# Table name: degree_types
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class DegreeType < ApplicationRecord
  validates :name, presence: true
end
