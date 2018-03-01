# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  uid        :string           not null
#  email      :string           not null
#  admin      :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role       :string           default("basic")
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'valid user' do
    user = users(:yo)
    assert(user.valid?)
  end

  test 'invalid without email' do
    user = users(:yo)
    user.email = nil
    assert(user.invalid?)
  end

  test 'invalid without uid' do
    user = users(:yo)
    user.uid = nil
    assert(user.invalid?)
  end

  test 'invalid with duplicate uid' do
    user = User.new(uid: 'some_id', email: 'yo@example.com')
    assert_raises ActiveRecord::RecordNotUnique do
      user.save
    end
  end

  test 'valid admin user' do
    user = users(:admin)
    assert(user.valid?)
  end

  test 'creates user from omniauth' do
    auth = OmniAuth::AuthHash.new(uid: '123', provider: 'example',
                                  info: { name: 'Orange Cat',
                                          email: 'ocat@example.com' })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.email, 'ocat@example.com')
  end
end
