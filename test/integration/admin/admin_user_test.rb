require 'test_helper'

class AdminUserTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing users panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/users'
    assert_response :success
    assert_equal('/admin/users', path)
  end

  test 'accessing users panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/users'
    assert_response :success
    assert_equal('/admin/users', path)
  end

  test 'accessing users panel works with processor rights' do
    mock_auth(users(:processor))
    get '/admin/users'
    assert_response :success
  end

  test 'accessing users panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/users'
    assert_response :redirect
  end

  test 'admins can edit roles through user dashboard' do
    mock_auth(users(:admin))
    user = users(:processor)
    patch admin_user_path(user),
      params: { user: { role: 'thesis_admin' } }
    user.reload
    assert_equal 'thesis_admin', user.role
  end
end
