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

end
