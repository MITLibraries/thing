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
#
require 'test_helper'

class TransferTest < ActiveSupport::TestCase
  test 'valid transfer' do
    transfer = transfers(:valid)
    assert(transfer.valid?)
  end

  test 'needs valid user' do
    transfer = transfers(:baduser)
    assert(transfer.invalid?)
  end

  test 'needs a department' do
    transfer = transfers(:valid)
    transfer.department = nil
    assert(transfer.invalid?)
  end

  test 'needs valid department' do
    transfer = transfers(:valid)
    transfer.department_id = 'boo'
    assert(transfer.invalid?)
  end

  test 'invalid without grad date' do
    transfer = transfers(:valid)
    transfer.grad_date = nil
    transfer.graduation_month = nil
    transfer.graduation_year = nil
    assert(transfer.invalid?)
  end

  test 'grad year should be vaguely reasonable' do
    transfer = transfers(:valid)

    # Valid
    transfer.graduation_year = '1861'
    assert transfer.valid?

    transfer.graduation_year = '2018'
    assert transfer.valid?

    transfer.graduation_year = 1861
    assert transfer.valid?

    transfer.graduation_year = 2018
    assert transfer.valid?

    # Invalid
    transfer.graduation_year = '1860'
    assert transfer.invalid?

    transfer.graduation_year = '10'
    assert transfer.invalid?

    transfer.graduation_year = '10000'
    assert transfer.invalid?

    transfer.graduation_year = 'honeybadgers'
    assert transfer.invalid?
  end

  test 'only May, June, September, and February are valid months' do
    transfer = transfers(:valid)
    transfer.grad_date = nil
    transfer.graduation_year = 2020

    transfer.graduation_month = 'January'
    assert transfer.invalid?

    transfer.graduation_month = 'February'
    assert transfer.valid?

    transfer.graduation_month = 'March'
    assert transfer.invalid?

    transfer.graduation_month = 'April'
    assert transfer.invalid?

    transfer.graduation_month = 'May'
    assert transfer.valid?

    transfer.graduation_month = 'June'
    assert transfer.valid?

    transfer.graduation_month = 'July'
    assert transfer.invalid?

    transfer.graduation_month = 'August'
    assert transfer.invalid?

    transfer.graduation_month = 'September'
    assert transfer.valid?

    transfer.graduation_month = 'October'
    assert transfer.invalid?

    transfer.graduation_month = 'November'
    assert transfer.invalid?

    transfer.graduation_month = 'December'
    assert transfer.invalid?
  end
end
