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
#  right_id           :integer
#  status             :string           default("active")
#  processor_note     :text
#  author_note        :text
#  files_complete     :boolean          default(FALSE), not null
#  metadata_complete  :boolean          default(FALSE), not null
#  publication_status :string           default("Not ready for publication"), not null
#

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
    thesis.advisors = [advisors(:first),advisors(:second)]
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

  test 'valid with multiple authors' do
    t = theses(:two)
    assert(t.authors.count > 1)
    assert(t.valid?)
  end

  test 'a thesis with associated authors and users can be deleted' do
    t = theses(:one)
    t.authors.any?
    t.users.any?
    assert_difference("Thesis.count", -1) { t.destroy }
  end

  test 'when a thesis is deleted, the associated author is also deleted' do
    t = theses(:one)
    t.authors.any?
    assert_difference("Author.count", -1) { t.destroy }
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
    assert_equal 2, u.authors.count
    assert_difference("u.authors.count", -1) { t.destroy }
  end

  test 'invalid without right' do
    thesis = theses(:one)
    thesis.right = nil
    assert(thesis.invalid?)
  end

  test 'invalid with multiple rights' do
    thesis = theses(:one)
    assert_raises(ActiveRecord::AssociationTypeMismatch) do
      thesis.right = [rights(:one), rights(:two)]
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

  test 'invalid without degree' do
    thesis = theses(:one)
    thesis.degrees = []
    assert(thesis.invalid?)
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

  test 'invalid without publication status' do
    thesis = theses(:one)
    thesis.publication_status = nil
    thesis.save
    assert_not thesis.valid?
  end

  test 'publication status defaults to not ready for publication' do
    thesis = Thesis.new
    assert thesis.publication_status == 'Not ready for publication'
  end

  test 'invalid without accepted publication status' do
    thesis = theses(:one)
    thesis.publication_status = 'Not ready for publication'
    thesis.save
    assert thesis.valid?

    thesis.publication_status = 'Publication review'
    thesis.save
    assert thesis.valid?

    thesis.publication_status = 'Ready for publication'
    thesis.save
    assert thesis.valid?

    thesis.publication_status = 'Published'
    thesis.save
    assert thesis.valid?

    thesis.publication_status = 'Foo'
    thesis.save
    assert_not thesis.valid?
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

  test 'a thesis may have a hold' do
    thesis = theses(:with_hold)
    assert thesis.holds.count == 1

    thesis = theses(:one)
    assert thesis.holds.count == 0
  end

  test 'thesis holds have readable attributes' do
    thesis = theses(:with_hold)
    assert thesis.holds.first.hold_source.source == 'technology licensing office'
    assert thesis.holds.first.status = 'active'
  end
end
