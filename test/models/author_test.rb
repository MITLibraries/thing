require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
  test 'can edit graduation confirmation' do
    a = Author.first
    assert(a.graduation_confirmed == false)
    a.graduation_confirmed = true
    a.save
    assert(a.valid?)
  end
end
