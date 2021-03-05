# == Schema Information
#
# Table name: authors
#
#  id                   :integer          not null, primary key
#  user_id              :integer          not null
#  thesis_id            :integer          not null
#  graduation_confirmed :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
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
