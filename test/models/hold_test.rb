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

  test 'can list the create dates and names of the parent thesis files' do
    h = holds(:valid)
    f = Rails.root.join('test','fixtures','files','a_pdf.pdf')
    h.thesis.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    thesis_file = h.thesis.files.first
    assert_equal "a_pdf.pdf", thesis_file.filename.to_s
    assert_equal h.dates_thesis_files_received, "#{thesis_file.created_at.strftime('%Y-%m-%d')} (#{thesis_file.filename.to_s})"

    f2 = Rails.root.join('test','fixtures','files','registrar.csv')
    h.thesis.files.attach(io: File.open(f2), filename: 'registrar.csv')
    dates_display = h.thesis.files.map { |file| "#{file.created_at.strftime('%Y-%m-%d')} (#{file.filename.to_s})" }.join("\n")
    assert_equal h.dates_thesis_files_received, dates_display
  end

  test 'can list associated degrees' do
    hold = holds(:valid)
    assert_equal "MFA\nJD", hold.degrees
  end

  test 'can list associated grad date' do
    hold = holds(:valid)
    assert_equal Date.parse("2017-09-13"), hold.grad_date
  end

  test 'can list associated author names' do
    h = holds(:valid)
    assert_equal "Robot, Basic; Yobot, Yo", h.author_names
  end
end
