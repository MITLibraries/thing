require 'test_helper'

class AdminTransferTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'thesis admins can access transfer panel' do 
    mock_auth(users(:thesis_admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'users with admin rights can access transfer panel' do
    mock_auth(users(:admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'non-admin users cannot access transfer dashboard' do
    mock_auth(users(:basic))
    get "/admin/transfers"
    assert_response :redirect

    mock_auth(users(:transfer_submitter))
    get "/admin/transfers"
    assert_response :redirect
  end

  test 'transfer dashboard renders for processors' do
    mock_auth(users(:processor))
    get "/admin/transfers"
    assert_response :success
  end

  test 'transfer dashboard renders for admin users' do
    mock_auth(users(:admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'transfer dashboard renders for thesis admins' do
    mock_auth(users(:thesis_admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'thesis admins can view transfer details through dashboard' do
    mock_auth(users(:thesis_admin))
    get "/admin/transfers/#{transfers(:valid).id}"
    assert_response :success
  end

  test 'users with admin rights can view transfer details through dashboard' do
    mock_auth(users(:admin))
    get "/admin/transfers/#{transfers(:valid).id}"
    assert_response :success
  end
end
