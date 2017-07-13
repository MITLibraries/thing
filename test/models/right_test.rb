require 'test_helper'

class RightTest < ActiveSupport::TestCase
  test 'valid right' do
    right = rights(:one)
    assert(right.valid?)
  end

  test 'invalid without name' do
    right = rights(:one)
    right.statement = nil
    assert(right.invalid?)
  end

  test 'can have multiple theses' do
    right = rights(:one)
    right.theses = [theses(:one), theses(:two)]
    assert(right.valid?)
  end

  test 'need not have any theses' do
    right = rights(:one)
    right.theses = []
    assert(right.valid?)
  end
end
