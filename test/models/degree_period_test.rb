# == Schema Information
#
# Table name: degree_periods
#
#  id         :integer          not null, primary key
#  grad_month :string
#  grad_year  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'test_helper'

class DegreePeriodTest < ActiveSupport::TestCase
  test 'only grad years between 1900 and 2099 are valid' do
    d = degree_periods(:june_2023)
    assert d.valid?

    d.grad_year = '1982'
    assert d.valid?

    d.grad_year = '2007'
    assert d.valid?

    d.grad_year = '2099'
    assert d.valid?

    d.grad_year = '1723'
    assert_not d.valid?

    d.grad_year = '2155'
    assert_not d.valid?
  end

  test 'only certain grad months are valid' do
    d = degree_periods(:june_2023)
    assert_equal 'June', d.grad_month
    assert d.valid?

    d.grad_month = 'May'
    assert d.valid?

    d.grad_month = 'September'
    assert d.valid?

    d.grad_month = 'February'
    assert d.valid?

    d.grad_month = 'January'
    assert_not d.valid?

    d.grad_month = 'August'
    assert_not d.valid?

    d.grad_month = 'Foo'
    assert_not d.valid?
  end

  test 'preceding or trailing characters in a grad year are invalid' do
    d = degree_periods(:june_2023)
    assert_equal '2023', d.grad_year
    assert d.valid?

    d.grad_year = '2023 '
    assert_not d.valid?

    d.grad_year = ' 2023'
    assert_not d.valid?
  end

  test 'preceding or trailing characters in a grad month are invalid' do
    d = degree_periods(:june_2023)
    assert_equal 'June', d.grad_month
    assert d.valid?

    d.grad_month = 'June '
    assert_not d.valid?

    d.grad_month = ' June'
    assert_not d.valid?
  end

  test 'destroying a degree period also destroys its dependent archivematica accession' do
    d = degree_periods(:june_2023)
    archivematica_accession_count = ArchivematicaAccession.count
    d.destroy
    new_archivematica_accession_count = ArchivematicaAccession.count
    new_archivematica_accession_count == archivematica_accession_count - 1
  end

  test 'a degree period cannot have the same grad_month and grad_year as an existing degree period' do
    d = degree_periods(:june_2023)
    assert_equal '2023', d.grad_year
    assert_equal 'June', d.grad_month

    # Records with the same month or year are valid...
    same_month = DegreePeriod.new(grad_month: 'June', grad_year: '1999')
    assert same_month.valid?

    same_year = DegreePeriod.new(grad_month: 'February', grad_year: '2023')
    assert same_year.valid?

    # ...but one with the same month and year raises an error.
    assert_raises ActiveRecord::RecordInvalid do
      DegreePeriod.create!(grad_month: 'June', grad_year: '2023')
    end
  end

  test 'editing a degree period generates a version' do
    d = degree_periods(:june_2023)
    versions_count = d.versions.count

    d.grad_year = '2099'
    d.save
    assert_equal versions_count + 1, d.versions.count
  end

  test 'finds existing degree period from reformatted grad date' do
    date = Date.new(2023, 6, 1)
    degree_period = DegreePeriod.from_grad_date(date)
    assert_equal degree_periods(:june_2023), degree_period
  end

  test 'creates new degree period from reformatted grad date' do
    degree_period_count = DegreePeriod.count
    date = Date.new(2024, 6, 1)
    assert_not DegreePeriod.find_by(grad_month: 'June', grad_year: '2024')

    degree_period = DegreePeriod.from_grad_date(date)
    assert_equal degree_period_count + 1, DegreePeriod.count
    assert_equal degree_period, DegreePeriod.last
  end
end
