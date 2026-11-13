# == Schema Information
#
# Table name: holds
#
#  id               :integer          not null, primary key
#  case_number      :string
#  date_end         :date             not null
#  date_requested   :date             not null
#  date_start       :date             not null
#  processing_notes :text
#  status           :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  hold_source_id   :integer          not null
#  thesis_id        :integer          not null
#
# Indexes
#
#  index_holds_on_hold_source_id  (hold_source_id)
#  index_holds_on_thesis_id       (thesis_id)
#
# Foreign Keys
#
#  hold_source_id  (hold_source_id => hold_sources.id)
#  thesis_id       (thesis_id => theses.id)
#
require 'test_helper'

class HoldTest < ActiveSupport::TestCase
  test 'adding a hold to a related thesis removes an otherwise ready thesis from publication review' do
    thesis = theses(:publication_review)
    related_thesis = theses(:released_hold)
    Author.create!(user: thesis.users.first, thesis: related_thesis, graduation_confirmed: true)
    thesis.save!
    assert_equal 'Publication review', thesis.reload.publication_status

    hold = holds(:valid).dup
    hold.thesis = related_thesis
    hold.save!

    assert_equal 'Not ready for publication', thesis.reload.publication_status
  end

  test 'releasing the last related hold restores publication review' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    hold.update!(status: :active)
    assert_equal 'Not ready for publication', thesis.reload.publication_status

    hold.update!(status: :released)

    assert_equal 'Publication review', thesis.reload.publication_status
  end

  test 'expiring a related hold does not restore publication review' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    hold.update!(status: :active)

    hold.update!(status: :expired)

    assert_equal 'Not ready for publication', thesis.reload.publication_status
  end

  test 'deleting the last related hold restores publication review' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    hold.update!(status: :active)
    assert_equal 'Not ready for publication', thesis.reload.publication_status

    hold.destroy!

    assert_equal 'Publication review', thesis.reload.publication_status
  end

  test 'releasing one related hold leaves other active holds blocking publication review' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    hold.update!(status: :active)
    another_hold = hold.dup
    another_hold.save!

    hold.update!(status: :released)

    assert_equal 'Not ready for publication', thesis.reload.publication_status
  end

  test 'releasing a related hold does not waive other readiness requirements' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    hold.update!(status: :active)
    thesis.update!(issues_found: true)

    hold.update!(status: :released)

    assert_equal 'Not ready for publication', thesis.reload.publication_status
  end

  test 'a reviewed distinction preserves publication review when the related thesis is held again' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    thesis.related_hold_exceptions.create!(related_thesis: hold.thesis)

    hold.update!(status: :active)

    assert_equal 'Publication review', thesis.reload.publication_status
    assert hold.reload.active?
  end

  test 'moving a hold refreshes both the former and current author groups' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    hold.update!(status: :active)
    assert_equal 'Not ready for publication', thesis.reload.publication_status
    other_thesis = theses(:doctor)
    new_held_thesis = theses(:one)
    Author.create!(user: other_thesis.users.last, thesis: new_held_thesis, graduation_confirmed: true)
    other_thesis.save!
    assert_equal 'Publication review', other_thesis.reload.publication_status

    hold.update!(thesis: new_held_thesis)

    assert_equal 'Publication review', thesis.reload.publication_status
    assert_equal 'Not ready for publication', other_thesis.reload.publication_status
  end

  test 'related hold changes preserve pending published and publication error statuses' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    pending_thesis = theses(:pending_publication)
    published_thesis = theses(:published)
    error_thesis = theses(:two)
    Author.create!(user: thesis.users.first, thesis: pending_thesis, graduation_confirmed: true)
    Author.create!(user: thesis.users.first, thesis: published_thesis, graduation_confirmed: true)
    Author.create!(user: thesis.users.first, thesis: error_thesis, graduation_confirmed: true)
    error_thesis.update!(publication_status: 'Publication error')

    hold.update!(status: :active)

    assert_equal 'Pending publication', pending_thesis.reload.publication_status
    assert_equal 'Published', published_thesis.reload.publication_status
    assert_equal 'Publication error', error_thesis.reload.publication_status
  end

  test 'related hold changes do not save unrelated theses' do
    thesis = theses(:publication_review)
    hold = related_hold_for(thesis)
    unrelated_thesis = theses(:doctor)
    original_updated_at = unrelated_thesis.updated_at

    hold.update!(status: :active)

    assert_equal original_updated_at, unrelated_thesis.reload.updated_at
  end

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

  test 'invalid without thesis' do
    hold = holds(:valid)
    assert hold.thesis.present?
    assert hold.valid?

    hold.thesis = nil
    assert_not hold.valid?
  end

  test 'invalid without hold source' do
    hold = holds(:valid)
    assert hold.hold_source.present?
    assert hold.valid?

    hold.hold_source = nil
    assert_not hold.valid?
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
    hold.date_end = Date.current
    hold.save
    assert Hold.ends_today_or_before.pluck(:id).include?(hold.id)
  end

  test 'ends_today_or_before scope returns a hold which ends in the past' do
    hold = holds(:valid)
    hold.date_end = Date.current - 1
    hold.save
    assert Hold.ends_today_or_before.pluck(:id).include?(hold.id)
  end

  test 'ends_today_or_before scope does not return a hold which ends in the future' do
    hold = holds(:valid)
    hold.date_end = Date.current + 1
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

  private

  def related_hold_for(thesis)
    related_thesis = theses(:released_hold)
    Author.create!(user: thesis.users.first, thesis: related_thesis, graduation_confirmed: true)
    thesis.save!
    related_thesis.holds.sole
  end
end
