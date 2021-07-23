require 'test_helper'

class AdminAuthorDashboardTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'thesis admins can access author dashboard' do
    mock_auth(users(:thesis_admin))
    get '/admin/authors'
    assert_response :success
  end

  test 'admin users can access author dashboard' do
    mock_auth(users(:admin))
    get '/admin/authors'
    assert_response :success
  end

  test 'accessing author dashboard as basic user redirects to root' do
    mock_auth(users(:basic))
    get '/admin/authors'
    assert_response :redirect
    follow_redirect!
    assert_equal('/', path)
  end
end
