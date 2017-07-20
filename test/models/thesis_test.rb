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
    assert(thesis.invalid?)
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
    assert_raises (ActiveRecord::AssociationTypeMismatch) {
      thesis.right = [rights(:one), rights(:two)]
    }
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

  test 'invalid without advisor' do
    thesis = theses(:one)
    thesis.advisors = []
    assert(thesis.invalid?)
  end

  test 'can have multiple advisors' do
    thesis = theses(:one)
    thesis.advisors = [advisors(:one), advisors(:two)]
    assert(thesis.valid?)
  end
end
