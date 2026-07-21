# == Schema Information
#
# Table name: advisor_theses
#
#  advisor_id :integer
#  thesis_id  :integer
#
# Indexes
#
#  index_advisor_theses_on_advisor_id  (advisor_id)
#  index_advisor_theses_on_thesis_id   (thesis_id)
#
class AdvisorThesis < ApplicationRecord
  belongs_to :thesis
  belongs_to :advisor
end
