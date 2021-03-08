# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  uid            :string           not null
#  email          :string           not null
#  admin          :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  role           :string           default("basic")
#  given_name     :string
#  surname        :string
#  kerberos_id    :string           not null
#  display_name   :string           not null
#  middle_name    :string
#  preferred_name :string
#  orcid          :string
#

require 'csv'
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

  test 'invalid without display_name' do
    user = users(:yo)
    user.display_name = nil
    assert(user.invalid?)
  end

  test 'invalid without kerberos_id' do
    user = users(:yo)
    user.kerberos_id = nil
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

  test 'generates kerb from uid when it should' do
    u = User.new(email: 'kso@mit.edu',
                 kerberos_id: 'ksoracle',
                 given_name: 'Kendrick',
                 surname: 'Scott')
    u.save
    assert u.valid?
    assert_equal 'ksoracle@mit.edu', u.uid
  end

  test 'generates uid from kerb when it should' do
    u = User.new(email: 'rgexperiment@mit.edu',
                 uid: 'rglasper@mit.edu',
                 given_name: 'Robert',
                 surname: 'Glasper')
    u.save
    assert u.valid?
    assert_equal 'rglasper', u.kerberos_id
  end

  test 'sets empty ORCID to nil on new record save' do
    u = User.new(email: 'acoltrane@mit.edu',
                 uid: 'acoltrane@mit.edu',
                 given_name: 'Alice',
                 surname: 'Coltrane',
                 orcid: '')
    u.save
    assert u.valid?
    assert_nil u.orcid
  end

  test 'sets empty ORCID to nil on existing record save' do
    u = users(:yo)
    u.orcid = ''
    u.save
    assert u.valid?
    assert_nil u.orcid
  end

  test 'saves non-empty ORCIDs as expected' do
    u = User.new(email: 'tyner@mit.edu',
                 kerberos_id: 'tyner',
                 given_name: 'McCoy',
                 surname: 'Tyner',
                 orcid: 'I-forget-how-these-are-structured')
    u.save
    assert u.valid?
    assert_equal u.orcid, 'I-forget-how-these-are-structured'
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
                                          display_name: 'Blue Cat',
                                          email: 'bcat@example.com' })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.given_name, 'Blue')
    assert_equal(omniuser.surname, 'Cat')
    assert_equal(omniuser.display_name, 'Blue Cat')
  end

  test 'created user from omniauth has a kerb id' do
    auth = OmniAuth::AuthHash.new(uid: 'bcat@mit.edu', provider: 'example',
                                  info: { given_name: 'Blue',
                                          surname: 'Cat',
                                          email: 'bcat@example.com' })
    omniuser = User.from_omniauth(auth)
    assert_equal(omniuser.kerberos_id, 'bcat')
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

  test 'finds existing user from csv' do
    filepath = 'test/fixtures/files/registrar_data_user_existing.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    user = User.create_or_update_from_csv(row)
    assert_equal users(:yo), user
  end

  test 'creates user from csv with all attributes' do
    filepath = 'test/fixtures/files/registrar_data_user_new.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    assert_not(User.find_by(kerberos_id: 'finleyjessica'))
    user = User.create_or_update_from_csv(row)
    assert_equal 'finleyjessica', user.kerberos_id
    assert_equal 'finleyjessica@mit.edu', user.uid
    assert_equal 'Jennifer', user.given_name
    assert_equal 'Marie', user.middle_name
    assert_equal 'Klein', user.surname
    assert_equal 'Klein, Jennifer', user.preferred_name
    assert_equal 'finleyjessica@example.com', user.email
  end

  test 'updates user from csv' do
    filepath = 'test/fixtures/files/registrar_data_user_updated.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    user = User.create_or_update_from_csv(row)
    user.reload
    assert_equal 'New', user.given_name
    assert_equal 'N.', user.middle_name
    assert_equal 'Name', user.surname
    assert_equal 'New Preferred Name', user.preferred_name
    assert_equal 'new@example.com', user.email
  end

  test 'only updates preferred_name from csv if blank' do
    filepath = 'test/fixtures/files/registrar_data_user_updated.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    user = users(:yo)
    user.update(preferred_name: 'Old Preferred Name')
    User.create_or_update_from_csv(row)
    assert_equal 'Old Preferred Name', user.preferred_name
  end

  test 'name property' do
    user = users(:yo)
    assert_equal 'Yobot, Yo', user.name
  end

  test 'generates kerberos_id from uid if not provided' do
    u = User.new(uid: 'coltrane@mit.edu', email: 'coltrane@mit.edu')
    u.save
    assert(u.valid?)
    assert_equal(u.kerberos_id, 'coltrane')
  end

  test 'generates display_name from name method if not provided' do
    u1 = User.new(uid: 'coltrane@mit.edu', email: 'coltrane@mit.edu')
    u1.save
    u2 = User.new(uid: 'parker@mit.edu', email: 'parker@mit.edu', 
                  preferred_name: 'Parker, Bird')
    u2.save
    u3 = User.new(uid: 'evans@mit.edu',email: 'evans@mit.edu', 
                  given_name: 'Bill', surname: 'Evans')
    assert(u1.valid?)
    assert_equal(u1.display_name, 'coltrane@mit.edu')
    assert(u2.valid?)
    assert_equal(u2.display_name, 'Parker, Bird')
    assert(u3.valid?)
    assert_equal(u3.display_name, 'Evans, Bill')
  end

  test 'display_name includes middle initial if available' do
    u = User.new(uid: 'jobim@mit.edu', email: 'jobim@mit.edu', 
                  given_name: 'Antonio', middle_name: 'Carlos', surname: 'Jobim')
    u.save
    assert_equal(u.display_name, 'Jobim, Antonio C.')
  end

  test 'updates display_name on record update' do
    u = users(:yo)
    assert_equal(u.display_name, 'Yo Yobot')
    u.given_name = 'John'
    u.surname = 'Coltrane'
    u.save
    assert_equal(u.display_name, 'Coltrane, John')
    u.preferred_name = 'Trane'
    u.save
    assert_equal(u.display_name, 'Trane')
  end

  test 'processing_queue_name adds email as needed' do
    u = User.new(uid: 'mehldau@mit.edu', email: 'mehldau@mit.edu', 
                 preferred_name: 'Mehldau, Brad')
    u.save
    assert_equal 'Mehldau, Brad (mehldau@mit.edu)', u.processing_queue_name
  end

  test 'processing_queue_name returns name method if email is in name' do
    u = User.new(uid: 'mehldau@mit.edu', email: 'mehldau@mit.edu')
    u.save
    assert_equal 'mehldau@mit.edu', u.name
    assert_equal 'mehldau@mit.edu', u.processing_queue_name
  end

  test 'can have one or more transfers' do
    u = User.last
    assert(u.name == 'Yobot, Yo')
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
    assert(u.name == 'Ransfer, Terry')
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

  test 'users have a submitter? helper method' do
    basic = users(:basic)
    assert_nil basic.submitter?
    transfer_submitter = users(:transfer_submitter)
    assert_equal transfer_submitter.submitter?, true
    thesis_admin = users(:thesis_admin)
    assert_equal thesis_admin.submitter?, true
    admin = users(:admin)
    assert_equal admin.submitter?, true
  end

  test 'thesis_submitters can see specified departments' do
    assert_equal users(:transfer_submitter).submittable_departments.length, users(:transfer_submitter).submitters.length
  end

  test 'thesis_admins can see all departments' do
    assert_equal users(:thesis_admin).submittable_departments.length, Department.all.length
  end

  test 'has zero or more theses through author table' do
    u1 = users(:yo)
    u2 = users(:bad)
    assert(u1.authors.any?)
    assert(u1.theses.any?)
    assert(u1.valid?)
    assert(u2.theses.empty?)
    assert(u2.valid?)
  end

  test 'cannot destroy a user with an associated thesis' do
    u = users(:yo)
    assert u.theses.any?
    u.destroy
    assert u.errors[:base].include? "Cannot delete record because dependent theses exist"
    assert u.present?
  end

  test 'can destroy a user without an associated thesis' do
    u = users(:bad)
    assert_not u.theses.any?
    assert_difference("User.count", -1) { u.destroy }
  end

  test 'can destroy a user once associated thesis has been destroyed' do
    u = users(:yo)
    assert u.theses.any?
    u.theses.destroy_all
    assert_not u.theses.any?
    assert_difference("User.count", -1) do
      u.destroy
    end
  end

  test 'editable_theses returns a set of thesis records' do
    u = users(:yo)
    assert_equal 3, u.editable_theses.count
  end

  test 'users with no theses have no editable_theses' do
    u = users(:admin)
    assert_equal 0, u.editable_theses.count
  end

  test 'setting metadata_complete makes a thesis not editable' do
    u = users(:yo)
    count = u.editable_theses.count
    t = u.editable_theses.first
    t.metadata_complete = true
    t.save
    u.reload
    assert_equal count - 1, u.editable_theses.count
  end
end
