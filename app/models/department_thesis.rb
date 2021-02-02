# == Schema Information
#
# Table name: department_theses
#
#  thesis_id     :integer
#  department_id :integer
#  id            :integer          not null, primary key
#  primary       :boolean          default(FALSE), not null
#

class DepartmentThesis < ApplicationRecord
  belongs_to :thesis
  belongs_to :department

  validates_uniqueness_of :department_id, scope: [:thesis_id], message: 'has already been assigned to this thesis'
  validates_uniqueness_of :primary, scope: [:thesis_id], conditions: -> { where(primary: true) }, message: 'department has already been declared for this thesis'
end
