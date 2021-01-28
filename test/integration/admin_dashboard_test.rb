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

  test 'thesis admins can view an admin theses show page' do
    mock_auth(users(:thesis_admin))
    get admin_thesis_path(theses(:one))
    assert_response :success
  end

  test 'thesis admins can access the thesis edit form through admin panel' do
    mock_auth(users(:thesis_admin))
    get "/admin/theses/#{theses(:one).id}/edit"
    assert_response :success
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
                          graduation_month: 'June',
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

  test 'admins can destroy theses through admin panel' do
    mock_auth(users(:admin))

    thesis = Thesis.first
    # Cache this, because the thesis will stop existing if the delete goes
    # through.
    thesis_id = thesis.id

    delete admin_thesis_path(thesis)
    assert !Thesis.exists?(thesis_id)
  end

  test 'can assign advisors to theses via thesis panel' do
    needle = advisors(:second)
    mock_auth(users(:thesis_admin))
    thesis = Thesis.first
    assert_equal thesis.advisors.count, 0
    patch admin_thesis_path(thesis),
      params: { thesis: { advisor_ids: [needle.id] } }
    thesis.reload
    assert_equal thesis.advisors.count, 1
    assert_equal needle.name, thesis.advisors.first.name
  end

  test 'accessing users panel works with admin rights' do
    mock_auth(users(:admin))
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

  test 'admins can edit roles through user dashboard' do
    mock_auth(users(:admin))
    user = users(:processor)
    patch admin_user_path(user),
      params: { user: { role: 'thesis_admin' } }
    user.reload
    assert_equal 'thesis_admin', user.role
  end

  test 'accessing rights panel works with admin rights' do
    mock_auth(users(:admin))
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

  test 'thesis admins can access transfer panel' do 
    mock_auth(users(:thesis_admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'users with admin rights can access transfer panel' do
    mock_auth(users(:admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'non-admin users cannot access transfer dashboard' do
    mock_auth(users(:basic))
    get "/admin/transfers"
    assert_response :redirect
    mock_auth(users(:processor))
    get "/admin/transfers"
    assert_response :redirect
    mock_auth(users(:transfer_submitter))
    get "/admin/transfers"
    assert_response :redirect
  end

  test 'transfer dashboard renders for admin users' do
    mock_auth(users(:admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'transfer dashboard renders for thesis admins' do
    mock_auth(users(:thesis_admin))
    get "/admin/transfers"
    assert_response :success
  end

  test 'thesis admins can view transfer details through dashboard' do
    mock_auth(users(:thesis_admin))
    get "/admin/transfers/#{transfers(:valid).id}"
    assert_response :success
  end

  test 'users with admin rights can view transfer details through dashboard' do
    mock_auth(users(:admin))
    get "/admin/transfers/#{transfers(:valid).id}"
    assert_response :success
  end

  # Advisors
  test 'accessing advisors panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/advisors'
    assert_response :redirect
    mock_auth(users(:processor))
    get '/admin/advisors'
    assert_response :redirect
  end

  test 'accessing advisors panel as an admin user works' do
    mock_auth(users(:admin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  test 'accessing advisors panel as a thesis_admin user works' do
    mock_auth(users(:thesis_admin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  test 'can edit advisors through admin dashboard' do
    needle = 'Another Advisor'
    mock_auth(users(:thesis_admin))
    advisor = Advisor.first
    assert_not_equal needle, advisor.name
    patch admin_advisor_path(advisor),
      params: { advisor: { name: needle } }
    advisor.reload
    assert_equal needle, advisor.name
  end

  test 'can assign theses to advisors via advisor form' do
    needle = theses(:two)
    mock_auth(users(:thesis_admin))
    advisor = Advisor.first
    assert_not_equal needle.title, advisor.theses.first.title
    patch admin_advisor_path(advisor),
      params: { advisor: { thesis_ids: [needle.id] } }
    advisor.reload
    assert_equal needle.title, advisor.theses.first.title
  end

  # Department_Theses
  test 'accessing department_thesis panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/department_theses'
    assert_response :redirect
    mock_auth(users(:processor))
    get '/admin/department_theses'
    assert_response :redirect
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
    needle = false
    mock_auth(users(:thesis_admin))
    link = DepartmentThesis.first
    assert_not_equal needle, link.primary
    patch admin_department_thesis_path(link),
      params: { department_thesis: { primary: needle } }
    link.reload
    assert_equal needle, link.primary
    patch admin_department_thesis_path(link),
      params: { department_thesis: { primary: !needle } }
    link.reload
    assert_not_equal needle, link.primary
  end

  # Holds
  test 'accessing holds panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/holds'
    assert_response :redirect
    mock_auth(users(:processor))
    get '/admin/holds'
    assert_response :redirect
  end

  test 'accessing holds panel as an admin user works' do
    mock_auth(users(:admin))
    get '/admin/holds'
    assert_response :success
    assert_equal('/admin/holds', path)
  end

  test 'accessing holds panel as a thesis_admin user works' do
    mock_auth(users(:thesis_admin))
    get '/admin/holds'
    assert_response :success
    assert_equal('/admin/holds', path)
  end

  test 'can edit holds through admin dashboard' do
    needle = 'Some specific test phrase that was not set in the fixtures...'
    mock_auth(users(:thesis_admin))
    hold = Hold.first
    assert_not_equal needle, hold.processing_notes
    patch admin_hold_path(hold),
      params: { hold: { processing_notes: needle } }
    hold.reload
    assert_equal needle, hold.processing_notes
  end

  test 'hold edit screen includes a dropdown for enumerated status values' do
    mock_auth(users(:thesis_admin))
    get "/admin/holds/#{holds(:valid).id}/edit"
    assert_select "select#hold_status", text: "active\nexpired\nreleased"
  end

  # Hold_sources
  test 'accessing hold_sources panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/hold_sources'
    assert_response :redirect
    mock_auth(users(:processor))
    get '/admin/hold_sources'
    assert_response :redirect
  end

  test 'accessing hold_sources panel as an admin user works' do
    mock_auth(users(:admin))
    get '/admin/hold_sources'
    assert_response :success
    assert_equal('/admin/hold_sources', path)
  end

  test 'accessing hold_sources panel as a thesis_admin user works' do
    mock_auth(users(:thesis_admin))
    get '/admin/hold_sources'
    assert_response :success
    assert_equal('/admin/hold_sources', path)
  end

  test 'can edit hold_sources through admin dashboard' do
    needle = 'Some specific test phrase that was not set in the fixtures...'
    mock_auth(users(:thesis_admin))
    hold_source = HoldSource.first
    assert_not_equal needle, hold_source.source
    patch admin_hold_source_path(hold_source),
      params: { hold_source: { source: needle } }
    hold_source.reload
    assert_equal needle, hold_source.source
  end

  test 'editing hold_sources lists which holds that source has requested' do
    mock_auth(users(:thesis_admin))
    get "/admin/hold_sources/#{hold_sources(:tlo).id}/edit"
    assert_select "div.field-unit__field", text: theses(:with_hold).title
  end
end
