require 'test_helper'

class AdminDepartmentTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing departments panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/departments'
    assert_response :success
    assert_equal('/admin/departments', path)
  end

  test 'accessing departments panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/departments'
    assert_response :success
    assert_equal('/admin/departments', path)
  end

  test 'accessing departments panel works with processor rights' do
    mock_auth(users(:processor))
    get '/admin/departments'
    assert_response :success
    assert_equal('/admin/departments', path)
  end

  test 'accessing departments panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/departments'
    assert_response :redirect
  end

  test 'thesis admins can edit departments through admin dashboard' do
    mock_auth(users(:thesis_admin))
    department = Department.first
    patch admin_department_path(department),
          params: { department: { name_dw: 'Course LII' } }
    department.reload
    assert_equal 'Course LII', department.name_dw
  end
end
