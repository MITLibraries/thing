# == Schema Information
#
# Table name: degrees
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class DegreeTest < ActiveSupport::TestCase
  test 'valid degree' do
    degree = degrees(:one)
    assert(degree.valid?)
  end

  test 'invalid without name' do
    degree = degrees(:one)
    degree.name = nil
    assert(degree.invalid?)
  end

  test 'can have multiple theses' do
    degree = degrees(:one)
    degree.theses = [theses(:one), theses(:two)]
    assert(degree.valid?)
  end

  test 'need not have any theses' do
    degree = degrees(:one)
    degree.theses = []
    assert(degree.valid?)
  end
end
