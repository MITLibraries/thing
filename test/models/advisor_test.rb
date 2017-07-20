# == Schema Information
#
# Table name: advisors
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class AdvisorTest < ActiveSupport::TestCase
  test 'valid advisor' do
    advisor = advisors(:one)
    assert(advisor.valid?)
  end

  test 'invalid without name' do
    advisor = advisors(:one)
    advisor.name = nil
    assert(advisor.invalid?)
  end

  test 'can have multiple theses' do
    advisor = advisors(:one)
    advisor.theses = [theses(:one), theses(:two)]
    assert(advisor.valid?)
  end

  test 'need not have any theses' do
    advisor = advisors(:one)
    advisor.theses = []
    assert(advisor.valid?)
  end
end
