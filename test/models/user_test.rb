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
#  name       :string
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

  test 'invalid without name' do
    user = users(:yo)
    user.name = nil
    assert(user.invalid?)
  end

  test 'invalid with duplicate uid' do
    uid = users(:yo).uid
    user = User.new(uid: uid, email: 'yo@example.com', name: 'Zaphod B.')
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

  test 'created user from omniauth has a name' do
    auth = OmniAuth::AuthHash.new(uid: '1234', provider: 'example',
                                  info: { name: 'Blue Cat',
                                          email: 'bcat@example.com' })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.name, 'Blue Cat')
  end

  test 'uses existing user from omniauth' do
    user = users(:yo)
    auth = OmniAuth::AuthHash.new(uid: user.uid, provider: 'example',
                                  info: { name: user.name,
                                          email: user.email })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.id, user.id)
  end
end
