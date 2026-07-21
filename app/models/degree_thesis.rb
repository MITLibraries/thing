# == Schema Information
#
# Table name: degree_theses
#
#  degree_id :integer
#  thesis_id :integer
#
# Indexes
#
#  index_degree_theses_on_degree_id  (degree_id)
#  index_degree_theses_on_thesis_id  (thesis_id)
#

class DegreeThesis < ApplicationRecord
  belongs_to :thesis
  belongs_to :degree
end
