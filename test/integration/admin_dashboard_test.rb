require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing admin panel unauthenticated redirects to root' do
    get '/admin'
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal('/', path)
  end

  test 'accessing admin panel without admin rights redirects to root' do
    mock_auth(users(:yo))
    get '/admin'
    assert_response :redirect
    follow_redirect!
    assert_equal('/', path)
  end

  test 'accessing admin panel with admin rights works' do
    mock_auth(users(:admin))
    get '/admin'
    assert_response :success
    assert_equal('/admin', path)
  end

  test 'accessing theses panel' do
    mock_auth(users(:admin))
    get '/admin/theses'
    assert_response :success
    assert_equal('/admin/theses', path)
  end

  test 'accessing users panel' do
    mock_auth(users(:admin))
    get '/admin/users'
    assert_response :success
    assert_equal('/admin/users', path)
  end

  test 'accessing rights panel' do
    mock_auth(users(:admin))
    get '/admin/rights'
    assert_response :success
    assert_equal('/admin/rights', path)
  end

  test 'accessing departments panel' do
    mock_auth(users(:admin))
    get '/admin/departments'
    assert_response :success
    assert_equal('/admin/departments', path)
  end

  test 'accessing degrees panel' do
    mock_auth(users(:admin))
    get '/admin/degrees'
    assert_response :success
    assert_equal('/admin/degrees', path)
  end

  test 'accessing advisors panel' do
    mock_auth(users(:admin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end
end
