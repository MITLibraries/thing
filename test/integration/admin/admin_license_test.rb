require 'test_helper'

class AdminLicenseDashboardTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing license panel with basic rights does not work' do
    mock_auth(users(:basic))
    get '/admin/licenses'
    assert_response :redirect
  end

  test 'accessing license panel with processor rights works' do
    mock_auth(users(:processor))
    get '/admin/licenses'
    assert_response :success
  end

  test 'accessing license panel with thesis_admin rights is successful' do
    mock_auth(users(:thesis_admin))
    get '/admin/licenses'
    assert_response :success
  end

  test 'accessing license panel with admin flag is successful' do
    mock_auth(users(:admin))
    get '/admin/licenses'
    assert_response :success
  end

  test 'can edit license record via admin dashboard' do
    mock_auth(users(:thesis_admin))
    newvalue = 'Public Domain'
    record = License.first
    assert_not_equal record.display_description, newvalue

    patch admin_license_path(record),
          params: { license: { display_description: newvalue } }
    record.reload
    assert_equal record.display_description, newvalue
  end
end
