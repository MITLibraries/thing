# == Schema Information
#
# Table name: holds
#
#  id               :integer          not null, primary key
#  thesis_id        :integer          not null
#  date_requested   :date             not null
#  date_start       :date             not null
#  date_end         :date             not null
#  hold_source_id   :integer          not null
#  case_number      :string
#  status           :integer          not null
#  processing_notes :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'test_helper'

class HoldTest < ActiveSupport::TestCase
  test 'valid hold' do
    hold = holds(:valid)
    assert(hold.valid?)
  end

  test 'only valid status values' do
    hold = holds(:valid)
    hold.status = "active"
    assert(hold.valid?)
    hold.status = "expired"
    assert(hold.valid?)
    hold.status = "released"
    assert(hold.valid?)
    assert_raises ArgumentError do
      hold.status = "garbage"
    end
    assert_raises ActiveRecord::NotNullViolation do
      hold.status = nil
      hold.save
    end
  end
end
