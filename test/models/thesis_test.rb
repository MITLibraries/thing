# == Schema Information
#
# Table name: theses
#
#  id                 :integer          not null, primary key
#  title              :string
#  abstract           :text
#  grad_date          :date             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  status             :string           default("active")
#  processor_note     :text
#  author_note        :text
#  files_complete     :boolean          default(FALSE), not null
#  metadata_complete  :boolean          default(FALSE), not null
#  publication_status :string           default("Not ready for publication"), not null
#  coauthors          :string
#  copyright_id       :integer
#  license_id         :integer
#  dspace_handle      :string
#  issues_found       :boolean          default(FALSE), not null
#

require 'csv'
require 'test_helper'

class ThesisTest < ActiveSupport::TestCase
  test 'valid thesis' do
    thesis = theses(:one)
    assert(thesis.valid?)
  end

  test 'valid without title' do
    thesis = theses(:one)
    thesis.title = nil
    assert thesis.valid?
  end

  test 'valid without abstract' do
    thesis = theses(:one)
    thesis.abstract = nil
    assert thesis.valid?
  end

  test 'valid without advisor' do
    thesis = theses(:two)
    assert_equal 0, thesis.advisors.count
    assert thesis.valid?
  end

  test 'valid with one advisor' do
    thesis = theses(:one)
    assert_equal 1, thesis.advisors.count
    assert thesis.valid?
  end

  test 'can have multiple advisors' do
    thesis = theses(:one)
    thesis.advisors = [advisors(:first), advisors(:second)]
    assert_equal 2, thesis.advisors.count
    assert thesis.valid?
  end

  test 'invalid without grad date' do
    thesis = theses(:one)
    thesis.grad_date = nil
    thesis.graduation_month = nil
    thesis.graduation_year = nil
    assert(thesis.invalid?)
  end

  test 'grad year should be vaguely reasonable' do
    thesis = theses(:one)
    thesis.graduation_year = '1861'
    assert thesis.valid?

    thesis.graduation_year = '2018'
    assert thesis.valid?

    thesis.graduation_year = 1861
    assert thesis.valid?

    thesis.graduation_year = 2018
    assert thesis.valid?

    thesis.graduation_year = '1860'
    assert thesis.invalid?

    thesis.graduation_year = '10'
    assert thesis.invalid?

    thesis.graduation_year = '10000'
    assert thesis.invalid?

    thesis.graduation_year = 'honeybadgers'
    assert thesis.invalid?
  end

  test 'invalid without user' do
    thesis = theses(:one)
    thesis.users = []
    thesis.save
    assert(thesis.invalid?)
  end

  test 'combine grad_date from month and year for new theses' do
    t = Thesis.new
    t.title = 'Sample'
    t.abstract = 'abstract'
    t.users.append(users(:yo))
    t.departments.append(departments(:one))
    t.graduation_month = 'February'
    t.graduation_year = '2020'
    assert t.valid?
    t.save

    assert_equal '2020-02-01', t.grad_date.to_s
  end

  test 'combine grad_date from month and year for thesis updates' do
    t = Thesis.second
    old_year = t.graduation_year
    old_date = t.grad_date
    t.graduation_year = t.graduation_year.to_i + 1
    assert t.valid?
    t.save

    t = Thesis.second
    assert_not_equal old_year.to_s, t.graduation_year.to_s
    assert_not_equal old_date.to_s, t.grad_date.to_s
  end

  test 'valid with multiple authors' do
    t = theses(:two)
    assert(t.authors.count > 1)
    assert(t.valid?)
  end

  test 'a thesis with associated authors and users can be deleted' do
    t = theses(:one)
    t.authors.any?
    t.users.any?
    assert_difference('Thesis.count', -1) { t.destroy }
  end

  test 'when a thesis is deleted, the associated author is also deleted' do
    t = theses(:one)
    t.authors.any?
    assert_difference('Author.count', -1) { t.destroy }
  end

  test 'when a thesis is deleted, the associated user is not deleted' do
    t = theses(:one)
    assert t.users.count == 1
    u = t.users.first
    assert_includes(User.all, u) { t.destroy }
  end

  test 'thesis deletion does not delete other author entries for the associated user' do
    t = theses(:one)
    u = users(:yo)
    assert_includes t.users, u
    assert_equal 4, u.authors.count
    assert_difference('u.authors.count', -1) { t.destroy }
  end

  test 'can have copyright or not' do
    thesis = theses(:one)
    assert_not_nil thesis.copyright
    assert(thesis.valid?)

    thesis.copyright = nil
    assert(thesis.valid?)
  end

  test 'invalid with multiple copyrights' do
    thesis = theses(:one)
    assert_raises(ActiveRecord::AssociationTypeMismatch) do
      thesis.copyright = [copyrights(:mit), copyrights(:author)]
    end
  end

  test 'invalid without department' do
    thesis = theses(:one)
    thesis.departments = []
    assert(thesis.invalid?)
  end

  test 'can have multiple departments' do
    thesis = theses(:one)
    thesis.departments = [departments(:one), departments(:two)]
    assert(thesis.valid?)
  end

  test 'can have license or not' do
    thesis = theses(:one)
    assert_not_nil thesis.license
    assert(thesis.valid?)

    thesis.license = nil
    assert(thesis.valid?)
  end

  test 'invalid with multiple licenses' do
    thesis = theses(:one)
    assert_raises(ActiveRecord::AssociationTypeMismatch) do
      thesis.license = [licenses(:nocc), licenses(:ccby)]
    end
  end

  test 'can have multiple degrees' do
    thesis = theses(:one)
    thesis.degrees = [degrees(:one), degrees(:two)]
    assert(thesis.valid?)
  end

  test 'can have active status' do
    thesis = theses(:one)
    thesis.status = 'active'
    thesis.save
    assert(thesis.valid?)
  end

  test 'can have withdrawn status' do
    thesis = theses(:one)
    thesis.status = 'withdrawn'
    thesis.save
    assert(thesis.valid?)
  end

  test 'can have downloaded status' do
    thesis = theses(:one)
    thesis.status = 'downloaded'
    thesis.save
    assert(thesis.valid?)
  end

  test 'cannot have other statuses' do
    thesis = theses(:one)
    thesis.status = 'nobel prize-winning'
    thesis.save
    assert_not(thesis.valid?)
  end

  test 'can have author note' do
    thesis = theses(:one)
    thesis.author_note = 'rad'
    thesis.save
    assert thesis.valid?
  end

  test 'can have processor note' do
    thesis = theses(:one)
    thesis.processor_note = 'confirmed that author is rad'
    thesis.save
    assert thesis.valid?
  end

  test 'can have dspace handle' do
    thesis = theses(:one)
    thesis.dspace_handle = 'https://example.com/12345.54321'
    thesis.save
    assert thesis.valid?
  end

  test 'invalid without files complete' do
    thesis = theses(:one)
    thesis.files_complete = nil
    thesis.save
    assert_not thesis.valid?
  end

  test 'files complete defaults to false' do
    thesis = Thesis.new
    assert thesis.files_complete == false
  end

  test 'invalid without metadata complete' do
    thesis = theses(:one)
    thesis.metadata_complete = nil
    thesis.save
    assert_not thesis.valid?
  end

  test 'metadata complete defaults to false' do
    thesis = Thesis.new
    assert(thesis.metadata_complete == false)
  end

  test 'invalid without issues_found' do
    thesis = theses(:one)
    assert thesis.valid?
    thesis.issues_found = nil
    thesis.save
    assert_not thesis.valid?
  end

  test 'issues_found defaults to false' do
    thesis = Thesis.new
    assert(thesis.issues_found == false)
  end

  test 'only May, June, September, and February are valid months' do
    thesis = theses(:one)
    thesis.grad_date = nil
    thesis.graduation_year = 2018

    thesis.graduation_month = 'January'
    assert thesis.invalid?

    thesis.graduation_month = 'February'
    assert thesis.valid?

    thesis.graduation_month = 'March'
    assert thesis.invalid?

    thesis.graduation_month = 'April'
    assert thesis.invalid?

    thesis.graduation_month = 'May'
    assert thesis.valid?

    thesis.graduation_month = 'June'
    assert thesis.valid?

    thesis.graduation_month = 'July'
    assert thesis.invalid?

    thesis.graduation_month = 'August'
    assert thesis.invalid?

    thesis.graduation_month = 'September'
    assert thesis.valid?

    thesis.graduation_month = 'October'
    assert thesis.invalid?

    thesis.graduation_month = 'November'
    assert thesis.invalid?

    thesis.graduation_month = 'December'
    assert thesis.invalid?
  end

  test 'coauthors field can be populated or nil' do
    thesis = theses(:one)
    thesis.coauthors = nil
    assert thesis.valid?

    thesis.coauthors = 'My freeloader'
    assert thesis.valid?
  end

  test 'a thesis may have a hold' do
    thesis = theses(:with_hold)
    assert thesis.holds.count == 1

    thesis = theses(:one)
    assert thesis.holds.count.zero?
  end

  test 'thesis holds have readable attributes' do
    thesis = theses(:with_hold)
    assert thesis.holds.first.hold_source.source == 'technology licensing office'
    assert thesis.holds.first.status = 'active'
  end

  test 'a thesis hold can be moved to another thesis' do
    t1 = theses(:with_hold)
    t2 = theses(:one)
    assert t1.holds.any?
    assert_not t2.holds.any?
    t2.holds = [t1.holds.first]
    assert_not t1.holds.any?
    assert t2.holds.any?
  end

  test 'thesis with holds cannot be deleted' do
    t = theses(:with_hold)
    t.destroy
    assert t.errors[:base].include? 'Cannot delete record because dependent holds exist'
    assert t.present?
  end

  test 'thesis with no holds can be deleted' do
    t = theses(:one)
    assert_equal false, t.holds.any?
    assert_difference('Thesis.count', -1) { t.destroy }
  end

  test 'thesis with hold can be deleted after its hold has been removed' do
    t = theses(:with_hold)
    t.holds.first.destroy
    assert_equal false, t.holds.any?
    assert_difference('Thesis.count', -1) { t.destroy }
  end

  test 'thesis can be deleted after its hold has moved to another thesis' do
    t1 = theses(:with_hold)
    t2 = theses(:one)
    h = t1.holds.first
    t2.holds = [h]
    assert t2.holds.count == 1
    assert t1.holds.count.zero?
    assert_difference('Thesis.count', -1) { t1.destroy }
  end

  test 'finds existing thesis from csv' do
    filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    user = users(:yo)
    user.update(theses: [theses(:one)])
    thesis = Thesis.create_or_update_from_csv(user, degrees(:one), departments(:one), Date.new(2017, 9, 1), row)
    user.reload
    assert_equal 1, user.theses.size
    assert_equal theses(:one), thesis
  end

  test 'creates thesis from csv with expected attributes' do
    filepath = 'test/fixtures/files/registrar_data_thesis_new.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    user = users(:yo)
    user.update(theses: [])
    thesis = Thesis.create_or_update_from_csv(user, degrees(:one), departments(:one), Date.new(2017, 9, 1), row)
    user.reload
    assert_equal 'Coauthor, Mine', thesis.coauthors
    assert_equal degrees(:one), thesis.degrees.first
    assert_equal departments(:one), thesis.departments.first
    assert_equal 'September', thesis.graduation_month
    assert_equal 2017, thesis.graduation_year
    assert_equal 'A New Thesis', thesis.title
    assert_equal user, thesis.users.first
    assert_equal 1, user.theses.size
  end

  test 'updates all expected attributes of existing thesis from csv' do
    filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    thesis = theses(:one)
    thesis.update(
      coauthors: '',
      degrees: [degrees(:one)],
      departments: [departments(:one)],
      title: ''
    )
    user = users(:yo)
    user.update(theses: [thesis])
    Thesis.create_or_update_from_csv(user, degrees(:two), departments(:two), Date.new(2017, 9, 1), row)
    thesis.reload
    assert_equal 'My new co-author', thesis.coauthors
    assert_includes thesis.degrees, degrees(:two)
    assert_includes thesis.departments, departments(:two)
    assert_equal 'A New Title', thesis.title
  end

  test 'only updates existing attributes from CSV if needed' do
    filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    thesis = theses(:one)
    thesis.update(
      coauthors: 'My co-author; My new co-author',
      degrees: [degrees(:two)],
      departments: [departments(:two)]
    )
    assert_equal 'MyString', thesis.title
    user = users(:yo)
    user.update(theses: [thesis])
    Thesis.create_or_update_from_csv(user, degrees(:two), departments(:two), Date.new(2017, 9, 1), row)
    thesis.reload
    assert_equal 'My co-author; My new co-author', thesis.coauthors
    assert_equal thesis.degrees, [degrees(:two)]
    assert_equal thesis.departments, [departments(:two)]
    assert_equal 'MyString', thesis.title
  end

  test 'raises error if multiple theses found from CSV' do
    assert_raise RuntimeError do
      filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
      row = CSV.readlines(File.open(filepath), headers: true).first
      Thesis.create_or_update_from_csv(users(:yo), degrees(:one), departments(:one), Date.new(2017, 9, 1), row)
    end
  end

  test 'active_holds? returns true with an "active" hold' do
    thesis = theses(:with_hold)
    assert_equal 'active', thesis.holds.first.status
    assert_equal true, thesis.active_holds?
  end

  test 'active_holds? returns true with an "expired" hold' do
    thesis = theses(:downloaded)
    assert_equal 'expired', thesis.holds.first.status
    assert_equal true, thesis.active_holds?
  end

  test 'active_holds? returns false with only "released" holds' do
    thesis = theses(:released_hold)
    assert_equal 1, thesis.holds.count
    assert_equal 'released', thesis.holds.first.status
    assert_equal false, thesis.active_holds?
  end

  test 'active_holds? returns false with zero holds' do
    thesis = theses(:one)
    assert_equal 0, thesis.holds.count
    assert_equal false, thesis.active_holds?
  end

  test 'active_holds? returns true with any active/expired hold' do
    thesis = theses(:multiple_holds)
    assert_equal 2, thesis.holds.count
    assert_equal %w[released expired], thesis.holds.map(&:status)
    assert_equal true, thesis.active_holds?
  end

  test 'authors_graduated? returns true if sole author graduated' do
    thesis = theses(:with_note)
    assert_equal 1, thesis.authors.count
    assert_equal true, thesis.authors.first.graduation_confirmed
    assert_equal true, thesis.authors_graduated?
  end

  test 'authors_graduated? returns true if all authors have graduated' do
    author = authors(:three)
    author.graduation_confirmed = true
    author.save

    thesis = theses(:two)
    assert_equal 2, thesis.authors.count
    assert_equal [true, true], thesis.authors.map(&:graduation_confirmed)
    assert_equal true, thesis.authors_graduated?
  end

  test 'authors_graduated? returns false if sole author has not graduated' do
    thesis = theses(:one)
    assert_equal 1, thesis.authors.count
    assert_equal false, thesis.authors.first.graduation_confirmed
    assert_equal false, thesis.authors_graduated?
  end

  test 'authors_graduated? returns false if any author has not graduated' do
    thesis = theses(:two)
    assert_equal 2, thesis.authors.count
    assert_equal [false, true], thesis.authors.map(&:graduation_confirmed)
    assert_equal false, thesis.authors_graduated?
  end

  test 'authors_graduated? returns false if all authors have graduated' do
    thesis = theses(:with_hold)
    assert_equal 2, thesis.authors.count
    assert_equal [false, false], thesis.authors.map(&:graduation_confirmed)
    assert_equal false, thesis.authors_graduated?
  end

  test 'publication status defaults to not ready for publication' do
    thesis = Thesis.new
    assert thesis.publication_status == 'Not ready for publication'
  end

  test 'invalid without publication status' do
    thesis = theses(:one)
    assert thesis.valid?
    thesis.publication_status = nil
    assert_not thesis.valid?
  end

  test 'invalid without accepted publication status' do
    thesis = theses(:one)
    thesis.publication_status = 'Not ready for publication'
    assert thesis.valid?

    thesis.publication_status = 'Publication review'
    assert thesis.valid?

    thesis.publication_status = 'Pending publication'
    assert thesis.valid?

    thesis.publication_status = 'Published'
    assert thesis.valid?

    thesis.publication_status = 'Foo'
    assert_not thesis.valid?
  end

  test 'publication status gets set to "Publication review" when conditions are met' do
    thesis = theses(:publication_review)
    # Fixture meets all conditions
    assert_equal true, thesis.files_complete
    assert_equal true, thesis.metadata_complete
    assert_equal false, thesis.issues_found
    assert_equal true, thesis.authors_graduated?
    assert_equal false, thesis.active_holds?
    assert_equal 'Publication review', thesis.publication_status
    # Attempting to set a different status will be overwritten by the update_status method
    thesis.publication_status = 'Not ready for publication'
    thesis.update(thesis.as_json)
    assert_equal 'Publication review', thesis.publication_status
  end

  test 'Unsetting files_complete sets status to "Not ready for publication"' do
    thesis = theses(:publication_review)
    assert_equal 'Publication review', thesis.publication_status
    thesis.files_complete = false
    thesis.update(thesis.as_json)
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'Unsetting metadata_complete sets status to "Not ready for publication"' do
    thesis = theses(:publication_review)
    assert_equal 'Publication review', thesis.publication_status
    thesis.metadata_complete = false
    thesis.update(thesis.as_json)
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'Setting issues_found sets status to "Not ready for publication"' do
    thesis = theses(:publication_review)
    assert_equal 'Publication review', thesis.publication_status
    thesis.issues_found = true
    thesis.update(thesis.as_json)
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'Unsetting author graduation_confirmed sets status to "Not ready for publication"' do
    thesis = theses(:publication_review)
    assert_equal 'Publication review', thesis.publication_status
    author = thesis.authors.first
    author.graduation_confirmed = false
    author.save
    thesis.reload
    assert_equal false, thesis.authors_graduated?
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'Adding an active hold sets status to "Not ready for publication"' do
    thesis = theses(:publication_review)
    assert_equal 'Publication review', thesis.publication_status
    assert_equal 1, thesis.holds.count
    hold = thesis.holds.first
    hold.status = 'active'
    hold.save
    thesis.reload
    assert_equal true, thesis.active_holds?
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'Setting an existing hold to "expired" will set the thesis status back to "Not ready for publication"' do
    thesis = theses(:publication_review)
    assert_equal 'Publication review', thesis.publication_status
    assert_equal 1, thesis.holds.count
    hold = thesis.holds.first
    hold.status = 'expired'
    hold.save
    thesis.reload
    assert_equal true, thesis.active_holds?
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'Setting an existing hold to "released" can put the thesis into "Publication review" status' do
    thesis = theses(:publication_review_except_hold)
    assert_equal 'Not ready for publication', thesis.publication_status
    assert_equal 1, thesis.holds.count
    hold = thesis.holds.first
    hold.status = 'released'
    hold.save
    thesis.reload
    assert_equal 'Publication review', thesis.publication_status
  end

  test 'Adding a new hold will set the thesis status back to "Not ready for publication"' do
    thesis = theses(:publication_review)
    assert_equal 'Publication review', thesis.publication_status
    hold = Hold.new({
                      'thesis' => thesis,
                      'date_requested' => '2021-01-03',
                      'date_start' => '2021-01-01',
                      'date_end' => '2021-04-01',
                      'hold_source' => HoldSource.first,
                      'status' => 'active'
                    })
    assert_equal true, hold.valid?
    hold.save
    thesis.reload
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'Adding a new hold when a thesis is in "Pending publication" will change nothing' do
    thesis = theses(:pending_publication)
    assert_equal 'Pending publication', thesis.publication_status
    hold = Hold.new({
                      'thesis' => thesis,
                      'date_requested' => '2021-01-03',
                      'date_start' => '2021-01-01',
                      'date_end' => '2021-04-01',
                      'hold_source' => HoldSource.first,
                      'status' => 'active'
                    })
    assert_equal true, hold.valid?
    hold.save
    thesis.reload
    assert_equal 'Pending publication', thesis.publication_status
  end

  test 'Flagging an issue when a thesis is in "Pending publication" will change nothing' do
    thesis = theses(:pending_publication)
    assert_equal 'Pending publication', thesis.publication_status
    thesis.issues_found = true
    thesis.save
    thesis.reload
    assert_equal 'Pending publication', thesis.publication_status
  end

  test 'Adding a new hold when a thesis is in "Published" will change nothing' do
    thesis = theses(:published)
    assert_equal 'Published', thesis.publication_status
    hold = Hold.new({
                      'thesis' => thesis,
                      'date_requested' => '2021-01-03',
                      'date_start' => '2021-01-01',
                      'date_end' => '2021-04-01',
                      'hold_source' => HoldSource.first,
                      'status' => 'active'
                    })
    assert_equal true, hold.valid?
    hold.save
    thesis.reload
    assert_equal 'Published', thesis.publication_status
  end

  test 'Flagging an issue when a thesis is in "Published" will change nothing' do
    thesis = theses(:published)
    assert_equal 'Published', thesis.publication_status
    thesis.issues_found = true
    thesis.save
    thesis.reload
    assert_equal 'Published', thesis.publication_status
  end
end
