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
    assert_equal 3, u.authors.count
    assert_difference("u.authors.count", -1) { t.destroy }
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
    assert thesis.holds.count == 0
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
    assert t.errors[:base].include? "Cannot delete record because dependent holds exist"
    assert t.present?
  end

  test 'thesis with no holds can be deleted' do
    t = theses(:one)
    assert_equal false, t.holds.any?
    assert_difference("Thesis.count", -1) { t.destroy }
  end

  test 'thesis with hold can be deleted after its hold has been removed' do
    t = theses(:with_hold)
    t.holds.first.destroy
    assert_equal false, t.holds.any?
    assert_difference("Thesis.count", -1) { t.destroy }
  end

  test 'thesis can be deleted after its hold has moved to another thesis' do
    t1 = theses(:with_hold)
    t2 = theses(:one)
    h = t1.holds.first
    t2.holds = [h]
    assert t2.holds.count == 1
    assert t1.holds.count == 0
    assert_difference("Thesis.count", -1) { t1.destroy }
  end

  test 'finds existing thesis from csv' do
    filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    user = users(:yo)
    user.theses= [theses(:one)]
    thesis = Thesis.create_or_update_from_csv(user, degrees(:one), departments(:one), Date.new(2017, 9, 1), row)
    user.reload
    assert_equal 1, user.theses.size
    assert_equal theses(:one), thesis
  end

  test 'creates thesis from csv with expected attributes' do
    filepath = 'test/fixtures/files/registrar_data_thesis_new.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    user = users(:yo)
    user.theses = []
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
    row = CSV.readlines(open(filepath), headers: true).first
    thesis = theses(:one)
    thesis.update(title: '', coauthors: '')
    user = users(:yo)
    user.theses = [thesis]
    degree_count = thesis.degrees.size
    department_count = thesis.departments.size
    new_degree = degrees(:two)
    new_department = departments(:two)
    Thesis.create_or_update_from_csv(user, new_degree, new_department, Date.new(2017, 9, 1), row)
    thesis.reload
    assert_equal 'My new co-author', thesis.coauthors
    assert_includes thesis.degrees, new_degree
    assert_equal degree_count + 1, thesis.degrees.size
    assert_includes thesis.departments, new_department
    assert_equal department_count + 1, thesis.departments.size
    assert_equal 'A New Title', thesis.title
  end

  test 'only updates existing attributes from CSV if needed' do
    filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    thesis = theses(:one)
    thesis.degrees = [degrees(:two)]
    thesis.departments = [departments(:two)]
    user = users(:yo)
    user.theses = [thesis]
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
      row = CSV.readlines(open(filepath), headers: true).first
      Thesis.create_or_update_from_csv(users(:yo), degrees(:one), departments(:one), Date.new(2017, 9, 1), row)
    end
  end
end
