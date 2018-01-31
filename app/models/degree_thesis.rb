# == Schema Information
#
# Table name: degree_theses
#
#  thesis_id :integer
#  degree_id :integer
#

class DegreeThesis < ApplicationRecord
  belongs_to :thesis
  belongs_to :degree
end
