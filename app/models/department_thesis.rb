# == Schema Information
#
# Table name: department_theses
#
#  thesis_id     :integer
#  department_id :integer
#

class DepartmentThesis < ApplicationRecord
  belongs_to :thesis
  belongs_to :department
end
