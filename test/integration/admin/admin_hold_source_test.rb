require 'test_helper'

class AdminHoldSourceDashboardTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing hold_sources panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/hold_sources'
    assert_response :redirect
  end

  test 'accessing hold_sources panel as processor user works' do
    mock_auth(users(:processor))
    get '/admin/hold_sources'
    assert_response :success
    assert_equal('/admin/hold_sources', path)
  end

  test 'accessing hold_sources panel as an admin user works' do
    mock_auth(users(:admin))
    get '/admin/hold_sources'
    assert_response :success
    assert_equal('/admin/hold_sources', path)
  end

  test 'accessing hold_sources panel as a thesis_admin user works' do
    mock_auth(users(:thesis_admin))
    get '/admin/hold_sources'
    assert_response :success
    assert_equal('/admin/hold_sources', path)
  end

  test 'can edit hold_sources through admin dashboard' do
    needle = 'Some specific test phrase that was not set in the fixtures...'
    mock_auth(users(:thesis_admin))
    hold_source = HoldSource.first
    assert_not_equal needle, hold_source.source
    patch admin_hold_source_path(hold_source),
          params: { hold_source: { source: needle } }
    hold_source.reload
    assert_equal needle, hold_source.source
  end
end
