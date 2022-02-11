require 'test_helper'

class AdminSubmissionInformationPackageTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'non-admin users cannot access sip dashboard' do
    mock_auth(users(:basic))
    get '/admin/submission_information_packages'
    assert_response :redirect

    mock_auth(users(:transfer_submitter))
    get '/admin/submission_information_packages'
    assert_response :redirect
  end

  test 'thesis admins can access sip dashboard' do
    mock_auth(users(:thesis_admin))
    get '/admin/submission_information_packages'
    assert_response :success
  end

  test 'users with admin rights can access sip dashboard' do
    mock_auth(users(:admin))
    get '/admin/submission_information_packages'
    assert_response :success
  end

  test 'processors can access sip dashboard' do
    mock_auth(users(:processor))
    get '/admin/submission_information_packages'
    assert_response :success
  end

  test 'thesis admins can view sip details through dashboard' do
    mock_auth(users(:thesis_admin))
    get "/admin/submission_information_packages/#{submission_information_packages(:sip_one).id}"
    assert_response :success
  end

  test 'processors can view sip details through dashboard' do
    mock_auth(users(:processor))
    get "/admin/submission_information_packages/#{submission_information_packages(:sip_one).id}"
    assert_response :success
  end

  test 'non-admin users cannot view sip details through dashboard' do
    mock_auth(users(:basic))
    get "/admin/submission_information_packages/#{submission_information_packages(:sip_one).id}"
    assert_response :redirect

    mock_auth(users(:transfer_submitter))
    get "/admin/submission_information_packages/#{submission_information_packages(:sip_one).id}"
    assert_response :redirect
  end

  test 'thesis admins cannot delete sips' do
    sip = submission_information_packages(:sip_one)
    mock_auth(users(:thesis_admin))
    delete admin_submission_information_package_path(sip)
    assert_response :redirect
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'
  end

  test 'processors cannot delete sips' do
    sip = submission_information_packages(:sip_one)
    mock_auth(users(:processor))
    delete admin_submission_information_package_path(sip)
    assert_response :redirect
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'
  end

  test 'thesis admins cannot edit sips' do
    sip = submission_information_packages(:sip_one)
    mock_auth(users(:thesis_admin))

    patch admin_submission_information_package_path(sip),
      params: { submission_information_package: { bag_name: "hallo" } }
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'
  end

  test 'processors cannot edit sips' do
    sip = submission_information_packages(:sip_one)
    mock_auth(users(:processor))

    patch admin_submission_information_package_path(sip),
      params: { submission_information_package: { bag_name: "hallo" } }
    follow_redirect!
    assert_equal '/', path
    assert @response.body.include? 'Not authorized.'
  end
end
