require 'test_helper'

class NavTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'home page nav' do
    get '/'
    assert_select('.current') do |value|
      assert(value.text.include?('Home'))
    end
  end

  test 'new thesis page nav' do
    mock_auth(users(:basic))
    get new_thesis_path
    assert_select('.current') do |value|
      assert(value.text.include?('Submit Thesis'))
    end
  end

  test 'processing page nav' do
    mock_auth(users(:admin))
    get process_path
    assert_select('.current') do |value|
      assert(value.text.include?('Process submissions'))
    end
  end

  test 'stats page nav' do
    mock_auth(users(:admin))
    get stats_path
    assert_select('.current') do |value|
      assert(value.text.include?('Stats'))
    end
  end
end
