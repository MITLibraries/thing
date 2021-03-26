require 'test_helper'

class AdminAdvisorTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing advisors panel does not work with basic rights' do
    mock_auth(users(:basic))
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

  test 'accessing advisors panel as a processor user works' do
    mock_auth(users(:processor))
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
end
