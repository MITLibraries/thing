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

  test 'sets primary to true if false and no other primary dept set' do
    link = department_theses(:primary)
    link.primary = false
    link.set_primary(true)
    assert link.primary
  end

  test 'sets primary to true if false and unsets existing primary' do
    link = department_theses(:other)
    old_primary = department_theses(:primary)
    link.set_primary(true)
    assert link.primary
    old_primary.reload
    assert_not old_primary.primary
  end

  test 'sets primary to false if true' do
    link = department_theses(:primary)
    link.set_primary(false)
    assert_not link.primary
  end

  test 'primary value stays the same if set to same value' do
    link = department_theses(:primary)
    link.set_primary(true)
    assert link.primary
  end

end