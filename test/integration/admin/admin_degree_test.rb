require 'test_helper'

class AdminDegreeTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing degrees panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/degrees'
    assert_response :success
    assert_equal('/admin/degrees', path)
  end

  test 'accessing degrees panel works with processor rights' do
    mock_auth(users(:processor))
    get '/admin/degrees'
    assert_response :success
  end

  test 'accessing degrees panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/degrees'
    assert_response :redirect
  end

  test 'thesis admins can edit degrees through admin dashboard' do
    mock_auth(users(:thesis_admin))
    degree = Degree.first
    patch admin_degree_path(degree),
          params: { degree: { name_dspace: 'Master of Fine Arts' } }
    degree.reload
    assert_equal 'Master of Fine Arts', degree.name_dspace
  end

  test 'thesis admins can associate a degree type with a degree' do
    mock_auth users(:thesis_admin)
    degree = Degree.first
    degree_type = degree_types(:bachelor)
    patch admin_degree_path(degree),
          params: { degree: { degree_type_id: degree_type.id } }
    degree.reload
    assert_equal degree_type.id, degree.degree_type.id

    get "/admin/degrees/#{degree.id}"
    assert_select "a[href='/admin/degree_types/#{degree_type.id}']", text: 'Bachelor'
  end
end
