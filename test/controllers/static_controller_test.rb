require 'test_helper'

class StaticControllerTest < ActionDispatch::IntegrationTest
  test 'root url' do
    get '/'
    assert_response :success
  end
end
