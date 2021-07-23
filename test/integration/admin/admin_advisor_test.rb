require 'test_helper'

class AdminAdvisorTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
    @advisor_params = {
      name: 'Sample Advisor'
    }
  end

  def teardown
    auth_teardown
  end

  def create_advisor
    count = Advisor.count
    get new_admin_advisor_path
    assert_response :success

    post admin_advisors_path, params: { advisor: @advisor_params }
    follow_redirect!
    assert_equal count + 1, Advisor.count
  end

  def create_advisor_denied
    count = Advisor.count
    get new_admin_advisor_path
    assert_response :redirect

    post admin_advisors_path, params: { advisor: @advisor_params }
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'
    assert_equal count, Advisor.count
  end

  def edit_advisor_name
    needle = 'Another Advisor'
    advisor = Advisor.first
    assert_not_equal needle, advisor.name

    patch admin_advisor_path(advisor),
          params: { advisor: { name: needle } }
    advisor.reload
    assert_equal needle, advisor.name
  end

  def edit_advisor_name_denied
    needle = 'Another Advisor'
    advisor = Advisor.first
    assert_not_equal needle, advisor.name

    patch admin_advisor_path(advisor),
          params: { advisor: { name: needle } }
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'
    advisor.reload
    assert_not_equal needle, advisor.name
  end

  def assign_advisor_to_thesis
    needle = theses(:two)
    advisor = Advisor.first
    count = advisor.theses.count
    thesis_ids = advisor.theses.collect(&:id).append(needle.id)
    assert_not_equal needle.title, advisor.theses.first.title

    patch admin_advisor_path(advisor),
          params: { advisor: { thesis_ids: [thesis_ids] } }
    advisor.reload
    assert_equal needle.title, advisor.theses.first.title
    assert_equal count + 1, advisor.theses.count
  end

  def assign_advisor_to_thesis_denied
    needle = theses(:two)
    advisor = Advisor.first
    count = advisor.theses.count
    thesis_ids = advisor.theses.collect(&:id).append(needle.id)
    assert_not_equal needle.title, advisor.theses.first.title

    patch admin_advisor_path(advisor),
          params: { advisor: { thesis_ids: [thesis_ids] } }
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'
    advisor.reload
    assert_not_equal needle.title, advisor.theses.first.title
    assert_equal count, advisor.theses.count
  end

  def delete_advisor
    thesis_count = Thesis.count
    advisor_count = Advisor.count
    needle = advisors(:second)
    assert_equal 0, needle.theses.count

    delete admin_advisor_path(needle)
    assert_equal thesis_count, Thesis.count
    assert_equal advisor_count - 1, Advisor.count
  end

  def delete_advisor_denied
    needle = advisors(:second)
    thesis_count = Thesis.count
    advisor_count = Advisor.count

    delete admin_advisor_path(needle)
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'

    assert_equal thesis_count, Thesis.count
    assert_equal advisor_count, Advisor.count
  end

  # Access to dashboard
  test 'basic user CANNOT access advisors dashboard' do
    mock_auth(users(:basic))
    get '/admin/advisors'
    assert_response :redirect
  end

  test 'transfer_submitters CANNOT access advisors dashboard' do
    mock_auth(users(:transfer_submitter))
    get '/admin/advisors'
    assert_response :redirect
  end

  test 'processors can access advisors dashboard' do
    mock_auth(users(:processor))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  test 'thesis_admins can access advisors dashboard' do
    mock_auth(users(:thesis_admin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  test 'admins can access advisors dashboard' do
    mock_auth(users(:admin))
    get '/admin/advisors'
    assert_response :success
    assert_equal('/admin/advisors', path)
  end

  # Creation of advisors
  test 'basic users CANNOT create advisors via admin dashboard' do
    mock_auth(users(:basic))
    create_advisor_denied
  end

  test 'transfer_submitters CANNOT create advisors via admin dashboard' do
    mock_auth(users(:transfer_submitter))
    create_advisor_denied
  end

  test 'processors can create advisors via admin dashboard' do
    skip('Processors currently can not _use_ the admin dashboard, so this fails.')
    mock_auth(users(:processor))
    create_advisor
  end

  test 'thesis_admins can create advisors via admin dashboard' do
    mock_auth(users(:thesis_admin))
    create_advisor
  end

  test 'admins can create advisors via admin dashboard' do
    mock_auth(users(:admin))
    create_advisor
  end

  # Editing advisors
  test 'basic CANNOT edit advisors through admin dashboard' do
    mock_auth(users(:basic))
    edit_advisor_name_denied
  end

  test 'transfer_submitters CANNOT edit advisors through admin dashboard' do
    mock_auth(users(:transfer_submitter))
    edit_advisor_name_denied
  end

  test 'processors can edit advisors through admin dashboard' do
    skip('Processors currently can not _use_ the admin dashboard, so this fails.')
    mock_auth(users(:processor))
    edit_advisor_name
  end

  test 'thesis_admins can edit advisors through admin dashboard' do
    mock_auth(users(:thesis_admin))
    edit_advisor_name
  end

  test 'admins can edit advisors through admin dashboard' do
    mock_auth(users(:admin))
    edit_advisor_name
  end

  # Assigning advisors to theses
  test 'basic CANNOT assign theses to advisors via advisor form' do
    mock_auth(users(:basic))
    assign_advisor_to_thesis_denied
  end

  test 'transfer_submitters CANNOT assign theses to advisors via advisor form' do
    mock_auth(users(:transfer_submitter))
    assign_advisor_to_thesis_denied
  end

  test 'processors can assign theses to advisors via advisor form' do
    skip('Processors currently can not _use_ the admin dashboard, so this fails.')
    mock_auth(users(:processor))
    assign_advisor_to_thesis
  end

  test 'thesis_admins can assign theses to advisors via advisor form' do
    mock_auth(users(:thesis_admin))
    assign_advisor_to_thesis
  end

  test 'admins can assign theses to advisors via advisor form' do
    mock_auth(users(:admin))
    assign_advisor_to_thesis
  end

  # Deleting advisors
  test 'basic CANNOT delete an advisor' do
    mock_auth(users(:basic))
    delete_advisor_denied
  end

  test 'transfer_submitters CANNOT delete an advisor' do
    mock_auth(users(:transfer_submitter))
    delete_advisor_denied
  end

  test 'processors can delete an advisor' do
    skip('Processors currently can not _use_ the admin dashboard, so this fails.')
    mock_auth(users(:processor))
    delete_advisor
  end

  test 'thesis_admins can delete an advisor' do
    mock_auth(users(:thesis_admin))
    delete_advisor
  end

  test 'admins can delete an advisor' do
    mock_auth(users(:admin))
    delete_advisor
  end
end
