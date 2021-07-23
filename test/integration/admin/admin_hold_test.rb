require 'test_helper'

class AdminHoldDashboardTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing holds panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/holds'
    assert_response :redirect
  end

  test 'accessing holds panel as an admin user works' do
    mock_auth(users(:admin))
    get '/admin/holds'
    assert_response :success
    assert_equal('/admin/holds', path)
  end

  test 'accessing holds panel as a thesis_admin user works' do
    mock_auth(users(:thesis_admin))
    get '/admin/holds'
    assert_response :success
    assert_equal('/admin/holds', path)
  end

  test 'accessing holds panel as a processor user works' do
    mock_auth(users(:processor))
    get '/admin/holds'
    assert_response :success
    assert_equal('/admin/holds', path)
  end

  test 'can edit holds through admin dashboard' do
    needle = 'Some specific test phrase that was not set in the fixtures...'
    mock_auth(users(:thesis_admin))
    hold = Hold.first
    assert_not_equal needle, hold.processing_notes
    patch admin_hold_path(hold),
          params: { hold: { processing_notes: needle } }
    hold.reload
    assert_equal needle, hold.processing_notes
  end

  test 'hold edit screen includes a dropdown for enumerated status values' do
    mock_auth(users(:thesis_admin))
    get "/admin/holds/#{holds(:valid).id}/edit"
    assert_select 'select#hold_status', text: "active\nexpired\nreleased"
  end

  test 'audit trail includes the identity of the editor' do
    mock_auth(users(:thesis_admin))
    hold = Hold.first
    patch admin_hold_path(hold),
          params: { hold: { case_number: '2' } }
    hold.reload
    change = hold.versions.last
    assert_equal change.whodunnit, users(:thesis_admin).id.to_s
  end

  test 'audit trail updates when a hold is moved to another thesis' do
    mock_auth(users(:thesis_admin))
    h = holds(:valid)
    t = theses(:one)
    prev_thesis_id = h.thesis_id
    assert_not h.thesis == t
    patch admin_hold_path(h),
          params: { hold: { thesis_id: t.id.to_s } }
    h.reload
    assert_equal t, h.thesis
    assert_equal users(:thesis_admin).id.to_s, h.versions.last.whodunnit
    assert_equal [prev_thesis_id, h.thesis_id], h.versions.last.changeset[:thesis_id]
  end

  test 'can identify the user who created a hold' do
    creator = users(:thesis_admin)
    mock_auth(creator)

    orig_count = Hold.count

    post admin_holds_path,
         params: { hold: {
           thesis_id: Thesis.first.id,
           hold_source_id: HoldSource.first.id,
           date_requested: '2021-03-02',
           date_start: '2021-03-02',
           date_end: '2021-03-02',
           case_number: nil,
           status: 'active',
           processing_notes: nil
         } }
    assert_equal orig_count + 1, Hold.count

    hold = Hold.last
    hold_creator = User.find_by(id: hold.versions.first.whodunnit)
    assert_equal hold_creator.id, creator.id
    assert_equal hold_creator.kerberos_id, hold.created_by
  end

  test 'correctly handles a deleted user who created a hold' do
    creator = User.new(uid: 'death@mit.edu', email: 'thanatos@mit.edu',
                       kerberos_id: 'destroyerofworlds')
    creator.admin = true
    creator.save
    assert creator.valid?
    mock_auth(creator)

    post admin_holds_path,
         params: { hold: {
           thesis_id: Thesis.first.id,
           hold_source_id: HoldSource.first.id,
           date_requested: '2021-03-02',
           date_start: '2021-03-02',
           date_end: '2021-03-02',
           case_number: nil,
           status: 'active',
           processing_notes: nil
         } }
    hold = Hold.last

    mock_auth(users(:admin))
    delete admin_user_path(creator)
    assert_equal "User ID #{creator.id} no longer active.", hold.created_by
  end

  test 'can identify the date a hold was released' do
    mock_auth(users(:thesis_admin))

    hold = holds(:valid)
    assert_not_equal 'released', hold.status

    patch admin_hold_path(hold), params: { hold: { status: 'released' } }
    hold.reload
    assert_equal 'released', hold.status
    assert_equal Date.today.strftime('%Y-%m-%d'), hold.date_released.strftime('%Y-%m-%d')
  end

  test 'hold release date is the most recent released status change' do
    mock_auth(users(:thesis_admin))

    hold = holds(:valid)
    assert_not_equal 'released', hold.status

    patch admin_hold_path(hold), params: { hold: { status: 'released' } }
    hold.reload
    first_release_date = hold.date_released
    assert_equal 'released', hold.status

    patch admin_hold_path(hold), params: { hold: { status: 'expired' } }
    hold.reload
    assert_equal 'expired', hold.status
    assert_equal first_release_date, hold.date_released

    patch admin_hold_path(hold), params: { hold: { status: 'released' } }
    hold.reload
    last_release_date = hold.date_released
    assert_equal 'released', hold.status
    assert_not_equal first_release_date, hold.date_released
    assert_equal last_release_date, hold.date_released
  end

  test 'new hold form includes thesis info panel if thesis_id param is present' do
    mock_auth(users(:admin))
    t = theses(:one)
    get "/admin/holds/new?thesis_id=#{t.id}"
    assert_response :success
    assert_select 'div.panel-heading', text: 'Thesis info'
    assert_select 'div.panel-body', text: "Title: MyString
            Author(s): Yobot, Yo
            Degree(s): Master of Fine Arts
            Degree date: 2017-09-01"
    assert_select 'select[name=?]', 'hold[thesis_id]', false
  end

  test 'new hold form excludes thesis info panel if no thesis_id param is present' do
    mock_auth(users(:admin))
    get '/admin/holds/new'
    assert_response :success
    assert_select 'div.panel-heading', false
    assert_select 'div.panel-body', false
    assert_select 'select[name=?]', 'hold[thesis_id]'
  end

  test 'custom field displays link to hold history' do
    mock_auth(users(:thesis_admin))
    hold = holds(:valid)
    get "/admin/holds/#{hold.id}"
    assert_response :success
    assert_select "a[href='/hold_history/#{hold.id}']", 'View hold history'
  end

  test 'can filter active holds' do
    mock_auth users(:thesis_admin)
    get '/admin/holds?search=active%3A'
    assert_response :success
    assert_select 'a', 'active'
    assert_select 'a', { count: 0, text: 'expired' }
    assert_select 'a', { count: 0, text: 'released' }
  end

  test 'can filter expired holds' do
    mock_auth users(:thesis_admin)
    get '/admin/holds?search=expired%3A'
    assert_response :success
    assert_select 'a', 'expired'
    assert_select 'a', { count: 0, text: 'active' }
    assert_select 'a', { count: 0, text: 'released' }
  end

  test 'can filter released holds' do
    mock_auth users(:thesis_admin)
    get '/admin/holds?search=released%3A'
    assert_response :success
    assert_select 'a', 'released'
    assert_select 'a', { count: 0, text: 'active' }
    assert_select 'a', { count: 0, text: 'expired' }
  end
end
