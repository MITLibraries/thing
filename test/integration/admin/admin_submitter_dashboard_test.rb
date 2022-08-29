require 'test_helper'

class AdminSubmitterDashboardTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing submitter dashboard as basic user redirects to root' do
    mock_auth(users(:basic))
    get '/admin/submitters/new'
    assert_response :redirect
  end

  test 'accessing submitter dashboard as transfer submitter redirects' do
    mock_auth(users(:transfer_submitter))
    get '/admin/submitters/new'
    assert_response :redirect
  end

  test 'accessing submitter index view as thesis_processor is allowed' do
    mock_auth(users(:processor))
    get '/admin/submitters'
    assert_response :success
  end

  test 'accessing submitter show view as thesis_processor is allowed' do
    mock_auth(users(:processor))
    submitter_id = Submitter.first.id
    get "/admin/submitters/#{submitter_id}"
    assert_response :success
  end

  test 'accessing new submitter form as thesis_processor is allowed' do
    mock_auth(users(:processor))
    get '/admin/submitters/new'
    assert_response :success
  end

  test 'accessing edit submitter form as thesis_processor is allowed' do
    mock_auth(users(:processor))
    submitter_id = Submitter.first.id
    get "/admin/submitters/#{submitter_id}/edit"
    assert_response :success
  end

  test 'thesis_processor can create a submitter' do
    mock_auth(users(:processor))
    orig_count = Submitter.count
    new_submitter = {
      user_id: User.first.id,
      department_id: Department.first.id
    }
    post admin_submitters_path, params: { submitter: new_submitter }
    assert_equal orig_count + 1, Submitter.count
  end

  test 'thesis_processor can update a submitter' do
    mock_auth(users(:processor))
    submitter = Submitter.first
    new_user_id = User.first.id
    assert_not_equal submitter.user_id, new_user_id

    patch admin_submitter_path(submitter), params: { submitter: { user_id: new_user_id } }
    submitter.reload
    assert_equal new_user_id, submitter.user_id
  end

  test 'thesis_processor can destroy a submitter' do
    mock_auth(users(:processor))
    submitter = Submitter.first
    submitter_id = submitter.id
    assert Submitter.exists?(submitter_id)

    delete admin_submitter_path(submitter)
    assert_not Submitter.exists?(submitter_id)
  end

  test 'new submitter form has no selection with no user_id param' do
    mock_auth(users(:processor))
    get '/admin/submitters/new'
    assert_response :success
    assert_select('select#submitter_user_id option[selected]', false)
  end

  test 'new submitter form pre-selects user when user_id param is present' do
    mock_auth(users(:processor))
    get "/admin/submitters/new?user_id=#{users(:basic).id}"
    assert_response :success

    assert_equal(
      assert_select('select#submitter_user_id option[selected]').first['value'],
      users(:basic).id.to_s
    )
  end
end
