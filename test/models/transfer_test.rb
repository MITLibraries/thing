# == Schema Information
#
# Table name: transfers
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  department_id          :integer          not null
#  grad_date              :date             not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  note                   :text
#  files_count            :integer          default(0), not null
#  unassigned_files_count :integer          default(0), not null
#
require 'test_helper'

class TransferTest < ActiveSupport::TestCase
  setup do
    @transfer = transfers(:valid)
  end

  test 'valid transfer' do
    assert @transfer.valid?
  end

  test 'needs valid user' do
    @transfer = transfers(:valid)
    assert @transfer.valid?
    @transfer.user = nil
    assert @transfer.invalid?
  end

  test 'needs a department' do
    @transfer.department = nil
    assert @transfer.invalid?
  end

  test 'needs valid department' do
    @transfer.department_id = 'boo'
    assert @transfer.invalid?
  end

  test 'invalid without grad date' do
    @transfer.grad_date = nil
    @transfer.graduation_month = nil
    @transfer.graduation_year = nil
    assert @transfer.invalid?
  end

  test 'valid even without a note' do
    assert @transfer.valid?
    @transfer.note = nil
    assert @transfer.valid?
  end

  test 'grad year should be vaguely reasonable' do
    # Valid
    @transfer.graduation_year = '1861'
    assert @transfer.valid?

    @transfer.graduation_year = '2018'
    assert @transfer.valid?

    @transfer.graduation_year = 1861
    assert @transfer.valid?

    @transfer.graduation_year = 2018
    assert @transfer.valid?

    # Invalid
    @transfer.graduation_year = '1860'
    assert @transfer.invalid?

    @transfer.graduation_year = '10'
    assert @transfer.invalid?

    @transfer.graduation_year = '10000'
    assert @transfer.invalid?

    @transfer.graduation_year = 'honeybadgers'
    assert @transfer.invalid?
  end

  test 'only May, June, September, and February are valid months' do
    @transfer.grad_date = nil
    @transfer.graduation_year = 2020

    @transfer.graduation_month = 'January'
    assert @transfer.invalid?

    @transfer.graduation_month = 'February'
    assert @transfer.valid?

    @transfer.graduation_month = 'March'
    assert @transfer.invalid?

    @transfer.graduation_month = 'April'
    assert @transfer.invalid?

    @transfer.graduation_month = 'May'
    assert @transfer.valid?

    @transfer.graduation_month = 'June'
    assert @transfer.valid?

    @transfer.graduation_month = 'July'
    assert @transfer.invalid?

    @transfer.graduation_month = 'August'
    assert @transfer.invalid?

    @transfer.graduation_month = 'September'
    assert @transfer.valid?

    @transfer.graduation_month = 'October'
    assert @transfer.invalid?

    @transfer.graduation_month = 'November'
    assert @transfer.invalid?

    @transfer.graduation_month = 'December'
    assert @transfer.invalid?
  end

  test 'can support multiple attached files' do
    file2 = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    @transfer.files.attach(io: File.open(file2), filename: 'a_pdf.pdf')
    assert @transfer.valid?
    file3 = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    @transfer.files.attach(io: File.open(file3), filename: 'a_pdf.pdf')
    assert @transfer.valid?
  end

  test 'at least one file must be attached' do
    @transfer.files.detach
    assert @transfer.invalid?
    file2 = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    @transfer.files.attach(io: File.open(file2), filename: 'a_pdf.pdf')
    assert @transfer.valid?
  end

  test 'unassigned_files updates as needed' do
    # confirm an initial state on a transfer
    @transfer.save # required to update initial counts from fixtured data
    assert_equal 0, @transfer.unassigned_files_count
    assert_equal 1, @transfer.files_count

    # add a file to a transfer and confirm it is not assigned to a thesis
    @newfile = Rails.root.join('test', 'fixtures', 'files', 'b_pdf.pdf')
    @transfer.files.attach(io: File.open(@newfile), filename: 'b_pdf.pdf')
    @transfer.save
    assert_equal 1, @transfer.unassigned_files_count
    assert_equal 2, @transfer.files_count

    # assign that file to a thesis to confirm the unassigned changes appropriately
    file = @transfer.files.last
    @thesis = theses(:one)
    @thesis.files.attach(file.blob)
    @thesis.save
    @transfer.save
    assert_equal 0, @transfer.unassigned_files_count

    # unassign that file from a thesis to confirm the unassigned count changes appropriately
    @thesis.files = []
    @thesis.save
    @transfer.save
    assert_equal 1, @transfer.unassigned_files_count
    assert_equal 2, @transfer.files_count
  end
end
