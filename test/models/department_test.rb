# == Schema Information
#
# Table name: departments
#
#  id          :integer          not null, primary key
#  name_dw     :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  code_dw     :string           default(""), not null
#  name_dspace :string
#

require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase
  test 'valid department' do
    department = departments(:one)
    assert(department.valid?)
  end

  test 'invalid without Data Warehouse name' do
    department = departments(:one)
    department.name_dw = nil
    assert(department.invalid?)
  end

  test 'invalid without Data Warehouse code' do
    department = departments(:one)
    department.code_dw = nil
    assert(department.invalid?)
  end

  test 'valid without DSpace name' do
    department = departments(:one)
    department.name_dspace = nil
    assert(department.valid?)
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

  test 'can have one or more transfers' do
    d = Department.last
    assert(d.name_dw == 'Department of Aeronautics and Astronautics')
    tcount = d.transfers.count
    t1 = Transfer.new
    t1.department = d
    t1.user = User.first
    t1.graduation_month = 'May'
    t1.graduation_year = '2020'
    t1.files.attach(io: File.open(Rails.root.join('test','fixtures','files','a_pdf.pdf')), filename: 'a_pdf.pdf')
    t1.save
    t2 = Transfer.new
    t2.department = d
    t2.user = User.first
    t2.graduation_month = 'May'
    t2.graduation_year = '2020'
    t2.files.attach(io: File.open(Rails.root.join('test','fixtures','files','a_pdf.pdf')), filename: 'a_pdf.pdf')
    t2.files.attach(io: File.open(Rails.root.join('test','fixtures','files','a_pdf.pdf')), filename: 'a_pdf.pdf')
    t2.save
    assert(d.transfers.count == tcount + 2)
  end

  test 'can access transfer information from department' do
    d = Department.last
    assert(d.name_dw == 'Department of Aeronautics and Astronautics')
    ttest = d.transfers.first
    assert(ttest.grad_date.to_s == '2020-05-01')
  end

  test 'can have zero or more users' do
    department_one = departments(:one)
    department_two = departments(:two)
    department_three = departments(:three)
    assert(department_one.users.count == 1)
    assert(department_two.users.count == 2)
    assert(department_three.users.count == 0)
  end

  test 'can have zero or more submitters' do
    department_one = departments(:one)
    department_two = departments(:two)
    department_three = departments(:three)
    assert(department_one.submitters.count == 1)
    assert(department_two.submitters.count == 2)
    assert(department_three.submitters.count == 0)
  end

  test 'finds existing department from csv' do
    filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    department = Department.from_csv(row)
    assert_equal departments(:one), department
  end

  test 'creates department from csv with all expected attributes' do
    filepath = 'test/fixtures/files/registrar_data_thesis_new.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    assert_not(Department.find_by(code_dw: 'UBW'))
    department = Department.from_csv(row)
    assert_equal 'UBW', department.code_dw
    assert_equal 'Underwater Basketweaving', department.name_dw
    assert_nil(department.name_dspace)
  end
end
