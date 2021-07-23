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

  test 'sets primary to true if false in db, is passed true, and no other primary dept set' do
    new_primary = department_theses(:other)
    refute new_primary.primary
    new_primary.set_primary(true)
    new_primary.reload
    assert new_primary.primary
  end

  test 'sets primary to true if false in db and is passed true, and unsets existing other primary dept' do
    new_primary = department_theses(:other)
    refute new_primary.primary
    old_primary = department_theses(:primary)
    assert old_primary.primary
    new_primary.set_primary(true)
    new_primary.reload
    assert new_primary.primary
    old_primary.reload
    refute old_primary.primary
  end

  test 'leaves primary true if true in db and is passed true' do
    link = department_theses(:primary)
    assert link.primary
    link.set_primary(true)
    link.reload
    assert link.primary
  end

  test 'sets primary to false if true in db and is passed false' do
    link = department_theses(:primary)
    assert link.primary
    link.set_primary(false)
    link.reload
    refute link.primary
  end

  test 'leaves primary false if false in db and is passed false' do
    link = department_theses(:other)
    refute link.primary
    link.set_primary(false)
    link.reload
    refute link.primary
  end
end
