require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase
  test 'valid department' do
    department = departments(:one)
    assert(department.valid?)
  end

  test 'invalid without name' do
    department = departments(:one)
    department.name = nil
    assert(department.invalid?)
  end

  test 'can have multiple theses' do
    department = departments(:one)
    department.theses = [theses(:one), theses(:two)]
    assert(department.valid?)
  end

  test 'need not have any theses' do
    department = departments(:one)
    department.theses = []
    assert(department.valid?)
  end
end
