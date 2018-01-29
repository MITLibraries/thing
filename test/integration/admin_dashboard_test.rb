require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing admin panel unauthenticated redirects to root' do
    get '/admin'
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal('/', path)
  end

  test 'accessing admin panel as a basic user redirects to root' do
    mock_auth(users(:basic))
    get '/admin'
    assert_response :redirect
    follow_redirect!
    assert_equal('/', path)
  end

  test 'accessing admin panel as a processor user redirects to root' do
    mock_auth(users(:processor))
    get '/admin'
    assert_response :redirect
    follow_redirect!
    assert_equal('/', path)
  end

  test 'accessing admin panel as a thesis admin works' do
    mock_auth(users(:thesis_admin))
    get '/admin'
    assert_response :success
    assert_equal('/admin', path)
  end

  test 'accessing admin panel as a sysadmin works' do
    mock_auth(users(:sysadmin))
    get '/admin'
    assert_response :success
    assert_equal('/admin', path)
  end

  test 'accessing admin panel with admin rights works' do
    mock_auth(users(:admin))
    get '/admin'
    assert_response :success
    assert_equal('/admin', path)
  end

  test 'accessing theses panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/theses'
    assert_response :success
    assert_equal('/admin/theses', path)
  end

  test 'accessing theses panel works with sysadmin rights' do
    mock_auth(users(:sysadmin))
    get '/admin/theses'
    assert_response :success
    assert_equal('/admin/theses', path)
  end

  test 'accessing theses panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/theses'
    assert_response :success
    assert_equal('/admin/theses', path)
  end

  test 'accessing theses panel does not work with processor rights' do
    mock_auth(users(:processor))
    get '/admin/theses'
    assert_response :redirect
  end

  test 'accessing theses panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/theses'
    assert_response :redirect
  end

  test 'thesis admins can update theses through admin panel' do
    mock_auth(users(:thesis_admin))

    thesis = Thesis.first
    new_title = 'yoyos are cool'
    assert_not_equal thesis.title, new_title

    patch admin_thesis_path(thesis),
      params: { thesis: { title: new_title } }

    thesis.reload
    assert_response :redirect
    assert_equal path, admin_thesis_path(thesis)
    assert_equal new_title, thesis.title
  end

  test 'thesis admins can create theses through admin panel' do
    mock_auth(users(:thesis_admin))

    orig_count = Thesis.count

    # Important! Enter the grad month and year, not the grad date. The Thesis
    # model does some before-creation logic to combine the month and year into
    # the grad_date attribute on the model instance.
    post admin_theses_path,
      params: { thesis: { user_id: User.first.id,
                          right_id: Right.first.id,
                          department_ids: [ Department.first.id ],
                          degree_ids: [ Degree.first.id ],
                          advisor_ids: [ Advisor.first.id ],
                          title: 'yoyos are cool',
                          abstract: 'We discovered it with science',
                          graduation_month: 'May',
                          graduation_year: Date.today.year } }

    assert_equal orig_count + 1, Thesis.count
    assert_equal 'yoyos are cool', Thesis.last.title
    assert_equal 'We discovered it with science', Thesis.last.abstract
  end

  test 'thesis admins cannot destroy theses through admin panel' do
    mock_auth(users(:thesis_admin))

    thesis = Thesis.first
    # Cache this, because the thesis will stop existing if the delete goes
    # through.
    thesis_id = thesis.id

    delete admin_thesis_path(thesis)
    assert Thesis.exists?(thesis_id)
  end

  test 'sysadmins can destroy theses through admin panel' do
    mock_auth(users(:sysadmin))

    thesis = Thesis.first
    # Cache this, because the thesis will stop existing if the delete goes
    # through.
    thesis_id = thesis.id

    delete admin_thesis_path(thesis)
    assert !Thesis.exists?(thesis_id)
  end

  test 'accessing users panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/users'
    assert_response :success
    assert_equal('/admin/users', path)
  end

  test 'accessing users panel works with sysadmin rights' do
    mock_auth(users(:sysadmin))
    get '/admin/users'
    assert_response :success
    assert_equal('/admin/users', path)
  end

  test 'accessing users panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/users'
    assert_response :success
    assert_equal('/admin/users', path)
  end

  test 'accessing users panel does not work with processor rights' do
    mock_auth(users(:processor))
    get '/admin/users'
    assert_response :redirect
  end

  test 'accessing users panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/users'
    assert_response :redirect
  end

  test 'accessing rights panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/rights'
    assert_response :success
    assert_equal('/admin/rights', path)
  end

  test 'accessing rights panel works with sysadmin rights' do
    mock_auth(users(:sysadmin))
    get '/admin/rights'
    assert_response :success
    assert_equal('/admin/rights', path)
  end

  test 'accessing rights panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/rights'
    assert_response :success
    assert_equal('/admin/rights', path)
  end

  test 'accessing rights panel does not work with processor rights' do
    mock_auth(users(:processor))
    get '/admin/rights'
    assert_response :redirect
  end

  test 'accessing rights panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/rights'
    assert_response :redirect
  end

  test 'thesis admins can edit rights through admin dashboard' do
    mock_auth(users(:thesis_admin))
    right = Right.first
    patch admin_right_path(right),
      params: { right: { statement: 'GPL 4.0' } }
    right.reload
    assert_equal 'GPL 4.0', right.statement
  end

  test 'accessing departments panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/departments'
    assert_response :success
    assert_equal('/admin/departments', path)
  end

  test 'accessing departments panel works with sysadmin rights' do
    mock_auth(users(:sysadmin))
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

  test 'accessing departments panel does not work with processor rights' do
    mock_auth(users(:processor))
    get '/admin/departments'
    assert_response :redirect
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
      params: { department: { name: 'Course LII' } }
    department.reload
    assert_equal 'Course LII', department.name
  end

  test 'accessing degrees panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/degrees'
    assert_response :success
    assert_equal('/admin/degrees', path)
  end

  test 'accessing degrees panel works with sysadmin rights' do
    mock_auth(users(:sysadmin))
    get '/admin/degrees'
    assert_response :success
    assert_equal('/admin/degrees', path)
  end

  test 'accessing degrees panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/degrees'
    assert_response :success
    assert_equal('/admin/degrees', path)
  end

  test 'accessing degrees panel does not work with processor rights' do
    mock_auth(users(:processor))
    get '/admin/degrees'
    assert_response :redirect
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
      params: { degree: { name: 'Master of Fine Arts' } }
    degree.reload
    assert_equal 'Master of Fine Arts', degree.name
  end

  test 'accessing advisors panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  test 'accessing advisors panel works with sysadmin rights' do
    mock_auth(users(:sysadmin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  test 'accessing advisors panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  test 'accessing advisors panel does not work with processor rights' do
    mock_auth(users(:processor))
    get '/admin/advisors'
    assert_response :redirect
  end

  test 'accessing advisors panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/advisors'
    assert_response :redirect
  end

  test 'thesis admins can edit advisors through admin dashboard' do
    mock_auth(users(:thesis_admin))
    advisor = Advisor.first
    patch admin_advisor_path(advisor),
      params: { advisor: { name: 'Fabio Zoltán de Academe' } }
    advisor.reload
    assert_equal 'Fabio Zoltán de Academe', advisor.name
  end
end
