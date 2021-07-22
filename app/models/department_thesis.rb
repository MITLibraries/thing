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
  validates_uniqueness_of :primary, scope: [:thesis_id], conditions: lambda {
                                                                       where(primary: true)
                                                                     }, message: 'department has already been declared for this thesis'

  # Given a boolean value, set the primary attribute to match the
  # provided value if needed. If the provided value is true, first
  # checks to see if there is an existing primary department_thesis
  # relationship for this thesis, and if so changes it to false
  # because there can only be one primary department for a thesis.
  def set_primary(primary_value)
    return if primary == primary_value

    was_primary = thesis.department_theses.find_by(primary: true)
    if primary_value && was_primary
      was_primary.update!(primary: false)
      Rails.logger.info("Old primary department unset: #{was_primary.department.code_dw}")
    end
    update!(primary: primary_value)
    Rails.logger.info("Primary department set to: #{department.code_dw}")
  end
end
