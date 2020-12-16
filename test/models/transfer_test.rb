# == Schema Information
#
# Table name: transfers
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  department_id :integer          not null
#  grad_date     :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  note          :text
#
require 'test_helper'

class TransferTest < ActiveSupport::TestCase
  setup do
    @transfer = transfers(:valid)
    file = Rails.root.join('test','fixtures','files','a_pdf.pdf')
    @transfer.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
  end

  teardown do
    @transfer.files.purge
  end

  test 'valid transfer' do
    assert @transfer.valid?
  end

  test 'needs valid user' do
    @transfer = transfers(:baduser)
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
    file2 = Rails.root.join('test','fixtures','files','a_pdf.pdf')
    @transfer.files.attach(io: File.open(file2), filename: 'a_pdf.pdf')
    assert @transfer.valid?
    file3 = Rails.root.join('test','fixtures','files','a_pdf.pdf')
    @transfer.files.attach(io: File.open(file3), filename: 'a_pdf.pdf')
    assert @transfer.valid?
  end

  test 'at least one file must be attached' do
    @transfer.files.detach
    assert @transfer.invalid?
    file2 = Rails.root.join('test','fixtures','files','a_pdf.pdf')
    @transfer.files.attach(io: File.open(file2), filename: 'a_pdf.pdf')
    assert @transfer.valid?
  end
end
