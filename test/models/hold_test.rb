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
    hold.status = 'active'
    assert(hold.valid?)
    hold.status = 'expired'
    assert(hold.valid?)
    hold.status = 'released'
    assert(hold.valid?)
    assert_raises ArgumentError do
      hold.status = 'garbage'
    end
    hold.status = nil
    assert(hold.invalid?)
  end

  test 'active_or_expired scope returns both statuses together' do
    assert_equal %w[active expired], Hold.active_or_expired.map(&:status).uniq.sort
  end

  test 'active_or_expired scope returns an active hold' do
    hold = holds(:valid)
    hold.status = :active
    hold.save
    assert Hold.active_or_expired.pluck(:id).include?(hold.id)
  end

  test 'active_or_expired scope returns an expired hold' do
    hold = holds(:valid)
    hold.status = :expired
    hold.save
    assert Hold.active_or_expired.pluck(:id).include?(hold.id)
  end

  test 'active_or_expired scope does not return a released hold' do
    hold = holds(:valid)
    hold.status = :released
    hold.save
    assert_not Hold.active_or_expired.pluck(:id).include?(hold.id)
  end

  test 'ends_today_or_before scope returns a hold which ends today' do
    hold = holds(:valid)
    hold.date_end = Date.today
    hold.save
    assert Hold.ends_today_or_before.pluck(:id).include?(hold.id)
  end

  test 'ends_today_or_before scope returns a hold which ends in the past' do
    hold = holds(:valid)
    hold.date_end = Date.today - 1
    hold.save
    assert Hold.ends_today_or_before.pluck(:id).include?(hold.id)
  end

  test 'ends_today_or_before scope does not return a hold which ends in the future' do
    hold = holds(:valid)
    hold.date_end = Date.today + 1
    hold.save
    assert_not Hold.ends_today_or_before.pluck(:id).include?(hold.id)
  end

  test 'editing hold generates an audit trail' do
    hold = holds(:valid)
    hold.save
    assert_equal hold.versions.count, 0
    hold.case_number = 2
    hold.save
    assert_equal hold.versions.count, 1
    assert_equal hold.versions.last.event, 'update'
  end

  test 'audit records include the changeset' do
    hold = holds(:valid)
    hold.save
    hold.case_number = '2'
    hold.save
    change = hold.versions.last
    assert_equal change.changeset['case_number'], [nil, '2']
  end

  test 'can list the create dates and names of the parent thesis files' do
    h = holds(:valid)
    f = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    h.thesis.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    thesis_file = h.thesis.files.first
    assert_equal 'a_pdf.pdf', thesis_file.filename.to_s
    assert_includes h.dates_thesis_files_received, thesis_file.created_at.strftime('%Y-%m-%d')
    assert_includes h.dates_thesis_files_received, 'a_pdf.pdf'

    f2 = Rails.root.join('test', 'fixtures', 'files', 'registrar.csv')
    h.thesis.files.attach(io: File.open(f2), filename: 'registrar.csv')
    create_dates = h.thesis.files.map { |file| file.created_at.strftime('%Y-%m-%d') }
    filenames = h.thesis.files.map { |file| file.filename.to_s }
    assert create_dates.each { |date| h.dates_thesis_files_received.include?(date) }
    assert filenames.each { |fname| h.dates_thesis_files_received.include?(fname) }
  end

  test 'can list associated degrees' do
    hold = holds(:valid)
    assert_equal "Master of Fine Arts\nJuris Doctor", hold.degrees
  end

  test 'can list associated grad date' do
    hold = holds(:valid)
    assert_equal Date.parse('2017-09-01'), hold.grad_date
  end

  test 'can list associated author names' do
    h = holds(:valid)
    assert_equal 'Student, Second; Yobot, Yo', h.author_names
  end

  test 'can access associated users' do
    h = holds(:valid)
    assert_equal 2, h.users.length
    assert_equal 'Second Student', h.users.first.display_name
    assert_equal 'Yo Yobot', h.users.second.display_name
  end

  test 'date_released renders release date' do
    hold = Hold.create('thesis' => Thesis.first, 'hold_source_id' => HoldSource.first.id,
                       'date_requested' => Date.today, 'date_start' => Date.today, 'date_end' => Date.tomorrow,
                       'status' => 'released')
    assert_equal 1, hold.versions.count
    assert_equal [nil, 'released'], hold.versions.last.changeset['status']

    pt_release_date = hold.versions.last.changeset['updated_at'][1]
    assert_equal pt_release_date, hold.date_released
  end

  test 'date_released renders release date even if status is stored as an integer' do
    hold = Hold.create('thesis' => Thesis.first, 'hold_source_id' => HoldSource.first.id,
                       'date_requested' => Date.today, 'date_start' => Date.today, 'date_end' => Date.tomorrow,
                       'status' => 'active')
    version = hold.versions.last
    version.object_changes['status'] = [nil, 2]
    version.save
    pt_release_date = hold.versions.last.changeset['updated_at'][1]
    assert_equal pt_release_date, hold.date_released
  end

  test 'date_released correctly evaluates release date' do
    hold = Hold.create('thesis' => Thesis.first, 'hold_source_id' => HoldSource.first.id,
                       'date_requested' => Date.today, 'date_start' => Date.today, 'date_end' => Date.tomorrow,
                       'status' => 'released')
    earlier_release_date = hold.versions.last.changeset['updated_at'][1]
    hold.status = 'active'
    hold.save
    hold.status = 'released'
    hold.save
    later_release_date = hold.versions.last.changeset['updated_at'][1]
    assert_not_equal earlier_release_date, later_release_date
    assert_equal later_release_date, hold.date_released
  end
end
