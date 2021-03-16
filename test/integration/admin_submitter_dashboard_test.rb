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

  test 'accessing submitter dashboard as thesis_process is allowed' do
    mock_auth(users(:processor))
    get '/admin/submitters/new'
    assert_response :success
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
