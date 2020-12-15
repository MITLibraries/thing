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
#  given_name :string
#  surname    :string
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
    uid = users(:yo).uid
    user = User.new(uid: uid,
                    email: 'yo@example.com',
                    given_name: 'Zaphod',
                    surname: 'Beeblebrox')
    assert_raises ActiveRecord::RecordNotUnique do
      user.save
    end
  end

  # We don't do any validation of name properties, because
  # https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/ .

  test 'valid admin user' do
    user = users(:admin)
    assert(user.valid?)
  end

  test 'creates user from omniauth' do
    auth = OmniAuth::AuthHash.new(uid: '123', provider: 'example',
                                  info: { given_name: 'Orange',
                                          surname: 'Cat',
                                          email: 'ocat@example.com' })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.email, 'ocat@example.com')
  end

  test 'created user from omniauth has a name' do
    auth = OmniAuth::AuthHash.new(uid: '1234', provider: 'example',
                                  info: { given_name: 'Blue',
                                          surname: 'Cat',
                                          email: 'bcat@example.com' })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.given_name, 'Blue')
    assert_equal(omniuser.surname, 'Cat')
  end

  test 'uses existing user from omniauth' do
    user = users(:yo)
    auth = OmniAuth::AuthHash.new(uid: user.uid, provider: 'example',
                                  info: { given_name: user.given_name,
                                          surname: user.surname,
                                          email: user.email })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.id, user.id)
  end

  test 'name property' do
    user = users(:yo)
    assert_equal 'Yobot, Yo (yo@example.com)', user.name
  end

  test 'can have one or more transfers' do
    u = User.last
    assert(u.name == 'Yobot, Yo (yo@example.com)')
    tcount = u.transfers.count
    t1 = Transfer.new
    t1.department = Department.first
    t1.user = u
    t1.graduation_month = 'May'
    t1.graduation_year = '2020'
    t1.files.attach(io: File.open(Rails.root.join('test','fixtures','files','a_pdf.pdf')), filename: 'a_pdf.pdf')
    t1.save
    assert(u.transfers.count == tcount + 1)
  end

  test 'can access transfer from user' do
    u = users(:transfer_submitter)
    assert(u.name == 'Ransfer, Terry (transfer@example.com)')
    ttest = u.transfers.first
    assert(ttest.grad_date.to_s == '2020-05-01')
  end

  test 'can have zero or more departments as submitter' do
    transfer_submitter = users(:transfer_submitter)
    thesis_admin = users(:thesis_admin)
    bad = users(:bad)
    assert(transfer_submitter.departments.count == 2)
    assert(thesis_admin.departments.count == 1)
    assert(bad.departments.count == 0)
  end
end
