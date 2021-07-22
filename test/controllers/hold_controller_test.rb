require 'test_helper'

class HoldControllerTest < ActionDispatch::IntegrationTest
  test 'thesis admins can view hold history' do
    sign_in users(:thesis_admin)
    @hold = Hold.first
    get hold_history_path(@hold)
    assert_response :success
  end

  test 'processors can view hold history' do
    sign_in users(:processor)
    @hold = Hold.first
    get hold_history_path(@hold)
    assert_response :success
  end

  test 'basic users cannot view hold history' do
    sign_in users(:basic)
    @hold = Hold.first
    get hold_history_path(@hold)
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'anonymous users cannot view hold history' do
    @hold = Hold.first
    get hold_history_path(@hold)
    assert_response :redirect
  end
end
