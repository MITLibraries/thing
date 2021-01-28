# == Schema Information
#
# Table name: advisor_theses
#
#  thesis_id  :integer
#  advisor_id :integer
#
class AdvisorThesis < ApplicationRecord
  belongs_to :thesis
  belongs_to :advisor
end
