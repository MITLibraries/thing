# == Schema Information
#
# Table name: transfers
#
#  id         :integer          not null, primary key
#  note       :text
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
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

  test 'note is not required' do
    transfer = transfers(:valid)
    transfer.note = nil
    assert(transfer.valid?)
  end
end
