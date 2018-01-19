require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'root path is splash controller for anonymous user' do
    get root_path
    assert @controller.instance_of? StaticController
    assert_equal 'index', @controller.action_name
  end

  test 'root path is new thesis controller for logged-in user' do
    mock_auth(users(:yo))
    get root_path
    assert @controller.instance_of? ThesisController
    assert_equal 'new', @controller.action_name
  end
end
