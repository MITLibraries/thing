# == Schema Information
#
# Table name: departments
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

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

  test 'can have one or more transfers' do
    d = Department.last
    assert(d.name == 'Underwater Basketweaving')
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
    assert(d.name == 'Underwater Basketweaving')
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
end
