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

  test 'valid date_requested' do
    hold = holds(:valid)
    assert(hold.valid?)
    hold.date_requested = nil
    assert(hold.invalid?)
    hold.date_requested = 'foo'
    assert(hold.invalid?)
    hold.date_requested = '2021-14-40'
    assert(hold.invalid?)
  end

  test 'valid date_start' do
    hold = holds(:valid)
    assert(hold.valid?)
    hold.date_start = nil
    assert(hold.invalid?)
    hold.date_start = 'foo'
    assert(hold.invalid?)
    hold.date_start = '2021-14-40'
    assert(hold.invalid?)
  end

  test 'valid date_end' do
    hold = holds(:valid)
    assert(hold.valid?)
    hold.date_end = nil
    assert(hold.invalid?)
    hold.date_end = 'foo'
    assert(hold.invalid?)
    hold.date_end = '2021-14-40'
    assert(hold.invalid?)
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
    hold.status = nil
    assert(hold.invalid?)
  end

  test 'editing hold generates an audit trail' do
    hold = holds(:valid)
    hold.save
    assert_equal hold.versions.count, 0
    hold.case_number = 2
    hold.save
    assert_equal hold.versions.count, 1
    assert_equal hold.versions.last.event, "update"
  end

  test 'audit records include the changeset' do
    hold = holds(:valid)
    hold.save
    hold.case_number = "2"
    hold.save
    change = hold.versions.last
    assert_equal change.changeset["case_number"], [nil, "2"]
  end
end
