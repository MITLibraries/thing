require 'test_helper'

class AdminDegreePeriodTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'anonymous users cannot access degree period dashboard' do
    get '/admin/degree_periods'
    assert_response :redirect
  end

  test 'basic users cannot access degree period dashboard' do
    mock_auth(users(:basic))
    get '/admin/degree_periods'
    assert_response :redirect
  end

  test 'transfer submitters cannot access degree period dashboard' do
    mock_auth(users(:transfer_submitter))
    get '/admin/degree_periods'
    assert_response :redirect
  end

  test 'thesis processors can access degree period dashboard' do
    mock_auth(users(:processor))
    get '/admin/degree_periods'
    assert_response :success
  end

  test 'thesis admins can access degree period dashboard' do
    mock_auth(users(:thesis_admin))
    get '/admin/degree_periods'
    assert_response :success
  end

  test 'thesis processors can view degree period details through dashboard' do
    mock_auth(users(:processor))
    get "/admin/degree_periods/#{DegreePeriod.first.id}"
    assert_response :success
  end

  test 'thesis processors can create a degree period' do
    mock_auth(users(:processor))
    orig_count = DegreePeriod.count
    new_degree_period = {
      grad_month: 'February',
      grad_year: '2023'
    }
    post admin_degree_periods_path, params: { degree_period: new_degree_period }
    assert_equal orig_count + 1, DegreePeriod.count
  end

  test 'thesis processors can update a degree period' do
    mock_auth(users(:processor))
    degree_period = DegreePeriod.first
    assert_not_equal 'February', degree_period.grad_month

    patch admin_degree_period_path(degree_period), params: { degree_period: { grad_month: 'February' } }
    degree_period.reload
    assert_equal degree_period.grad_month, 'February'
  end

  test 'thesis processors can destroy a degree period' do
    mock_auth(users(:processor))
    degree_period = DegreePeriod.first
    degree_period_id = degree_period.id
    assert DegreePeriod.exists?(degree_period_id)

    delete admin_degree_period_path(degree_period)
    assert_not DegreePeriod.exists?(degree_period_id)
  end

  test 'thesis admins can view degree period details through dashboard' do
    mock_auth(users(:thesis_admin))
    get "/admin/degree_periods/#{DegreePeriod.first.id}"
    assert_response :success
  end

  test 'thesis admins can create a degree period' do
    mock_auth(users(:thesis_admin))
    orig_count = DegreePeriod.count
    new_degree_period = {
      grad_month: 'February',
      grad_year: '2023'
    }
    post admin_degree_periods_path, params: { degree_period: new_degree_period }
    assert_equal orig_count + 1, DegreePeriod.count
  end

  test 'thesis admins can update a degree period' do
    mock_auth(users(:thesis_admin))
    degree_period = DegreePeriod.first
    assert_not_equal 'February', degree_period.grad_month

    patch admin_degree_period_path(degree_period), params: { degree_period: { grad_month: 'February' } }
    degree_period.reload
    assert_equal degree_period.grad_month, 'February'
  end

  test 'thesis admins can destroy a degree period' do
    mock_auth(users(:thesis_admin))
    degree_period = degree_periods(:no_archivematica_accessions)
    degree_period_id = degree_period.id
    assert DegreePeriod.exists?(degree_period_id)

    delete admin_degree_period_path(degree_period)
    assert_not DegreePeriod.exists?(degree_period_id)
  end
end
