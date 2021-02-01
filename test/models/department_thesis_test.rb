# == Schema Information
#
# Table name: department_theses
#
#  thesis_id     :integer
#  department_id :integer
#  id            :integer          not null, primary key
#  primary       :boolean          default(FALSE), not null
#

require 'test_helper'

class DepartmentThesisTest < ActiveSupport::TestCase
  test 'valid link with and without primary' do
    link = department_theses(:primary)
    assert_equal link.primary, true
    assert(link.valid?)
    link = department_theses(:other)
    assert_equal link.primary, false
    assert(link.valid?)
  end

  test 'only one primary department per thesis' do
    link = department_theses(:primary)
    assert_equal true, link.primary
    link = department_theses(:other)
    assert_equal false, link.primary
    assert(link.valid?)
    link.primary = true
    assert(link.invalid?)
  end

  test 'no delcared primary department is okay' do
    link = department_theses(:primary)
    link.primary = false
    assert(link.valid?)
  end

  test 'unique combination of thesis and department' do
    link = department_theses(:other)
    link.department = departments(:one)
    assert(link.invalid?)
    link.department = departments(:three)
    assert(link.valid?)
  end
end