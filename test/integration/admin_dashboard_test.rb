require 'test_helper'

class AdminDashboardTest < ActionDispatch::IntegrationTest
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

  test 'accessing admin panel as a basic user redirects to root' do
    mock_auth(users(:basic))
    get '/admin'
    assert_response :redirect
    follow_redirect!
    assert_equal('/', path)
  end

  test 'accessing admin panel as a processor user works' do
    mock_auth(users(:processor))
    get '/admin'
    assert_response :success
    assert_equal('/admin', path)
  end

  test 'accessing admin panel as a thesis admin works' do
    mock_auth(users(:thesis_admin))
    get '/admin'
    assert_response :success
    assert_equal('/admin', path)
  end

  test 'accessing admin panel with admin rights works' do
    mock_auth(users(:admin))
    get '/admin'
    assert_response :success
    assert_equal('/admin', path)
  end
end
