require 'test_helper'

class AdminDepartmentThesisDashboardTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing department_thesis panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/department_theses'
    assert_response :redirect
  end

  test 'accessing department_thesis panel as a processor user works' do
    mock_auth(users(:processor))
    get '/admin/department_theses'
    assert_response :success
    assert_equal('/admin/department_theses', path)
  end

  test 'accessing department_thesis panel as an admin user works' do
    mock_auth(users(:admin))
    get '/admin/department_theses'
    assert_response :success
    assert_equal('/admin/department_theses', path)
  end

  test 'accessing department_thesis panel as a thesis_admin user works' do
    mock_auth(users(:thesis_admin))
    get '/admin/department_theses'
    assert_response :success
    assert_equal('/admin/department_theses', path)
  end

  test 'can edit department_thesis through admin dashboard' do
    skip('This test is failing in GitHub Actions and passing everywhere else. We are skipping it until we fix it in CI.')
    mock_auth(users(:thesis_admin))
    link = DepartmentThesis.first
    assert_not_equal false, link.primary
    patch admin_department_thesis_path(link),
          params: { department_thesis: { primary: false } }
    link.reload
    assert_equal false, link.primary
    patch admin_department_thesis_path(link),
          params: { department_thesis: { primary: true } }
    link.reload
    assert_not_equal false, link.primary
  end
end
