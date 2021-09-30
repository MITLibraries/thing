require 'test_helper'

class ReportControllerTest < ActionDispatch::IntegrationTest
  test 'summary report exists' do
    sign_in users(:admin)
    get report_index_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by summary report' do
    # Note that nobody is signed in.
    get report_index_path
    assert_response :redirect
  end

  test 'basic users cannot see summary report' do
    sign_in users(:basic)
    get report_index_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see summary report' do
    sign_in users(:transfer_submitter)
    get report_index_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see summary report' do
    sign_in users(:processor)
    get report_index_path
    assert_response :success
  end

  test 'thesis_admins can see summary report' do
    sign_in users(:thesis_admin)
    get report_index_path
    assert_response :success
  end

  test 'admins can see summary report' do
    sign_in users(:admin)
    get report_index_path
    assert_response :success
  end

  test 'summary report has links to term-specific pages for all terms' do
    sign_in users(:processor)
    get report_index_path
    assert_select 'table:first-of-type thead a', count: Thesis.pluck(:grad_date).uniq.count
  end

  # ~~~~~~~~~~~~~~~~~~~~ Report term detail ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'term report exists' do
    sign_in users(:admin)
    get report_term_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by term report' do
    # Note that nobody is signed in.
    get report_term_path
    assert_response :redirect
  end

  test 'basic users cannot see term report' do
    sign_in users(:basic)
    get report_term_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see term report' do
    sign_in users(:transfer_submitter)
    get report_term_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see term report' do
    sign_in users(:processor)
    get report_term_path
    assert_response :success
  end

  test 'thesis_admins can see term report' do
    sign_in users(:thesis_admin)
    get report_term_path
    assert_response :success
  end

  test 'admins can see term report' do
    sign_in users(:admin)
    get report_term_path
    assert_response :success
  end

  test 'term report shows a few fields' do
    sign_in users(:processor)
    get report_term_path
    assert_select '.card-overall .message', text: '21 thesis records', count: 1
    assert_select '.card-files .message', text: '0 have files attached', count: 1
    assert_select '.card-issues span', text: '1 flagged with issues', count: 1
    assert_select '.card-multiple-authors span', text: '2 have multiple authors', count: 1
    assert_select '.card-multiple-degrees span', text: '1 has multiple degrees', count: 1
    assert_select '.card-multiple-departments span', text: '1 has multiple departments', count: 1
    assert_response :success
  end

  test 'term report allows filtering' do
    sign_in users(:processor)
    get report_term_path
    assert_select '.card-overall .message', text: '21 thesis records', count: 1
    get report_term_path, params: { graduation: '2018-09-01' }
    assert_select '.card-overall .message', text: '2 thesis records', count: 1
    assert_response :success
  end
end
