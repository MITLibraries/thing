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
