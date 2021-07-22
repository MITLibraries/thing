require 'test_helper'

class AdminCopyrightTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing copyright panel with basic rights does not work' do
    mock_auth(users(:basic))
    get '/admin/copyrights'
    assert_response :redirect
  end

  test 'accessing copyright panel with processor rights works' do
    mock_auth(users(:processor))
    get '/admin/copyrights'
    assert_response :success
  end

  test 'accessing copyright panel with thesis_admin rights is successful' do
    mock_auth(users(:thesis_admin))
    get '/admin/copyrights'
    assert_response :success
  end

  test 'accessing copyright panel with admin flag is successful' do
    mock_auth(users(:admin))
    get '/admin/copyrights'
    assert_response :success
  end

  test 'can edit copyright record via admin dashboard' do
    mock_auth(users(:thesis_admin))
    newvalue = 'Cal Tech'
    record = Copyright.first
    assert_not_equal record.holder, newvalue

    patch admin_copyright_path(record),
          params: { copyright: { holder: newvalue } }
    record.reload
    assert_equal record.holder, newvalue
  end
end
