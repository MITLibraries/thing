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
      params: { thesis: { user_ids: [ User.first.id ], 
                          title: new_title 
                        } 
              }

    thesis.reload
    assert_response :redirect
    assert_equal path, admin_thesis_path(thesis)
    assert_equal new_title, thesis.title
  end

  test 'thesis admins can create theses through admin panel' do
    user = users(:thesis_admin)
    mock_auth(user)

    orig_count = Thesis.count

    # Important! Enter the grad month and year, not the grad date. The Thesis
    # model does some before-creation logic to combine the month and year into
    # the grad_date attribute on the model instance.
    post admin_theses_path,
      params: { thesis: { user_ids: [ user.id ],
                          right_id: Right.first.id,
                          department_ids: [ Department.first.id ],
                          degree_ids: [ Degree.first.id ],
                          advisor_ids: [ Advisor.first.id ],
                          title: 'yoyos are cool',
                          abstract: 'We discovered it with science',
                          graduation_month: 'June',
                          graduation_year: Date.today.year
                        },
              }
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

  test 'thesis view includes a button to create a new hold for thesis' do
    mock_auth(users(:admin))
    t = theses(:one)
    get "/admin/theses/#{t.id}"
    assert_select "a[href=?]", "/admin/holds/new?thesis_id=#{t.id}"
  end

  test 'can assign advisors to theses via thesis panel' do
    needle = advisors(:second)
    user = users(:yo)
    mock_auth(users(:thesis_admin))
    thesis = Thesis.first
    assert_equal thesis.advisors.count, 0
    patch admin_thesis_path(thesis),
      params: { thesis: { user_ids: [user.id],
                          advisor_ids: [needle.id] } }
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
    skip("This test is failing in GitHub Actions and passing everywhere else. We are skipping it until we fix it in CI.")
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

  test 'audit trail includes the identity of the editor' do
    mock_auth(users(:thesis_admin))
    hold = Hold.first
    patch admin_hold_path(hold),
      params: { hold: { case_number: "2" } }
    hold.reload
    change = hold.versions.last
    assert_equal change.whodunnit, users(:thesis_admin).id.to_s
  end

  test 'audit trail updates when a hold is moved to another thesis' do
    mock_auth(users(:thesis_admin))
    h = holds(:valid)
    t = theses(:one)
    prev_thesis_id = h.thesis_id
    assert_not h.thesis == t
    patch admin_hold_path(h),
      params: { hold: { thesis_id: t.id.to_s } }
    h.reload
    assert_equal t, h.thesis
    assert_equal users(:thesis_admin).id.to_s, h.versions.last.whodunnit
    assert_equal [prev_thesis_id, h.thesis_id], h.versions.last.changeset[:thesis_id]
  end

  test 'can identify the user who created a hold' do
    creator = users(:thesis_admin)
    mock_auth(creator)

    orig_count = Hold.count

    post admin_holds_path,
      params: { hold: {       
                        thesis_id: Thesis.first.id, 
                        hold_source_id: HoldSource.first.id,
                        date_requested: '2021-03-02',
                        date_start: '2021-03-02',
                        date_end:'2021-03-02',
                        case_number: nil,
                        status: 'active',
                        processing_notes: nil
                      },
              }
    assert_equal orig_count + 1, Hold.count

    hold = Hold.last
    hold_creator = User.find_by(id: hold.versions.first.whodunnit)
    assert_equal hold_creator.id, creator.id
    assert_equal hold_creator.kerberos_id, hold.created_by
  end

  test 'correctly handles a deleted user who created a hold' do
    creator = User.new(uid: 'death@mit.edu', email: 'thanatos@mit.edu', 
                       kerberos_id: 'destroyerofworlds')
    creator.admin = true
    creator.save
    assert creator.valid?
    mock_auth(creator)

    post admin_holds_path,
      params: { hold: {       
                        thesis_id: Thesis.first.id, 
                        hold_source_id: HoldSource.first.id,
                        date_requested: '2021-03-02',
                        date_start: '2021-03-02',
                        date_end:'2021-03-02',
                        case_number: nil,
                        status: 'active',
                        processing_notes: nil
                      },
              }
    hold = Hold.last

    mock_auth(users(:admin))
    delete admin_user_path(creator)
    assert_equal "User ID #{creator.id} no longer active.", hold.created_by
  end

  test 'can identify the date a hold was released' do
    mock_auth(users(:thesis_admin))

    hold = holds(:valid)
    assert_not_equal "released", hold.status

    patch admin_hold_path(hold), params: { hold: { status: "released" } }
    hold.reload
    assert_equal "released", hold.status
    assert_equal Date.today.strftime('%Y-%m-%d'), hold.date_released.strftime('%Y-%m-%d')
  end

  test 'hold release date is the most recent released status change' do
    mock_auth(users(:thesis_admin))

    hold = holds(:valid)
    assert_not_equal "released", hold.status

    patch admin_hold_path(hold), params: { hold: { status: "released" } }
    hold.reload
    first_release_date = hold.date_released
    assert_equal "released", hold.status

    patch admin_hold_path(hold), params: { hold: { status: "expired" } }
    hold.reload
    assert_equal "expired", hold.status
    assert_equal first_release_date, hold.date_released

    patch admin_hold_path(hold), params: { hold: { status: "released" } }
    hold.reload
    last_release_date = hold.date_released
    assert_equal "released", hold.status
    assert_not_equal first_release_date, hold.date_released
    assert_equal last_release_date, hold.date_released
  end

  test 'new hold form includes thesis info panel if thesis_id param is present' do
    mock_auth(users(:admin))
    t = theses(:one)
    get "/admin/holds/new?thesis_id=#{t.id}"
    assert_response :success
    assert_select "div.panel-heading", text: "Thesis info"
    assert_select "div.panel-body", text: "Title: MyString
            Author(s): Yobot, Yo
            Degree(s): MFA
            Degree date: 2017-09-13"
    assert_select "select[name=?]", "hold[thesis_id]", false
  end

  test 'new hold form excludes thesis info panel if no thesis_id param is present' do
    mock_auth(users(:admin))
    get "/admin/holds/new"
    assert_response :success
    assert_select "div.panel-heading", false
    assert_select "div.panel-body", false
    assert_select "select[name=?]", "hold[thesis_id]"
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

  # Authors
  test 'thesis admins can access author dashboard' do
    mock_auth(users(:thesis_admin))
    get "/admin/authors"
    assert_response :success
  end

  test 'admin users can access author dashboard' do 
    mock_auth(users(:admin))
    get "/admin/authors"
    assert_response :success
  end

  test 'accessing author dashboard as basic user redirects to root' do
    mock_auth(users(:basic))
    get "/admin/authors"
    assert_response :redirect
    follow_redirect!
    assert_equal('/', path)
  end
end
