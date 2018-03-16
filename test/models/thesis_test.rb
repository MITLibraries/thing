# == Schema Information
#
# Table name: theses
#
#  id         :integer          not null, primary key
#  title      :string           not null
#  abstract   :text             not null
#  grad_date  :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#  right_id   :integer
#  status     :string           default("active")
#  note       :text
#

require 'test_helper'

class ThesisTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test 'valid thesis' do
    thesis = theses(:one)
    assert(thesis.valid?)
  end

  test 'invalid without title' do
    thesis = theses(:one)
    thesis.title = nil
    assert(thesis.invalid?)
  end

  test 'invalid without abstract' do
    thesis = theses(:one)
    thesis.abstract = nil
    assert(thesis.invalid?)
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
    thesis.user = nil
    assert(thesis.invalid?)
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

  test 'only June, September, and February are valid months' do
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
    assert thesis.invalid?

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
end
