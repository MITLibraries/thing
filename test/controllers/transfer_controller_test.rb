require 'test_helper'

class TransferControllerTest < ActionDispatch::IntegrationTest
  test 'new redirects to login' do
    get '/transfer/new'
    assert_response :redirect
    assert_redirected_to '/users/auth/saml'
  end

  test 'transfer submitters can submit a transfer' do
    sign_in users(:transfer_submitter)
    get '/transfer/new'
    assert_response :success
  end

  test 'thesis admins can submit a transfer' do
    sign_in users(:thesis_admin)
    get '/transfer/new'
    assert_response :success
  end

  test 'login redirect when anonymous user tries to submit or view a transfer' do
    get '/transfer/new'
    assert_redirected_to '/users/auth/saml'
    get "/transfer/#{transfers(:valid).id}"
    assert_redirected_to '/users/auth/saml'
  end

  test 'basic user cannot submit or view a transfer' do
    sign_in users(:basic)
    assert_raises CanCan::AccessDenied do
      get "/transfer/new"
    end
    sign_in users(:basic)
    assert_raises CanCan::AccessDenied do
      get "/transfer/#{transfers(:valid).id}"
    end
  end

  test 'processor cannot submit a transfer' do
    sign_in users(:processor)
    assert_raises CanCan::AccessDenied do
      get "/transfer/new"
    end
  end

  test 'transfer submitter can view their own transfer' do
    sign_in users(:transfer_submitter)
    get "/transfer/#{transfers(:valid).id}"
    assert_response :success
  end

  test 'transfer submitter cannot view transfers they did not submit' do
    sign_in users(:transfer_submitter)
    assert_raises CanCan::AccessDenied do
      get "/transfer/#{transfers(:alsovalid).id}"
    end
  end

  test 'thesis admin can view any transfer' do
    sign_in users(:thesis_admin)
    get "/transfer/#{transfers(:valid).id}"
    assert_response(:success)
    get "/transfer/#{transfers(:alsovalid).id}"
    assert_response(:success)
  end

  test 'processor can view any transfer' do
    sign_in users(:processor)
    get "/transfer/#{transfers(:valid).id}"
    assert_response(:success)
    get "/transfer/#{transfers(:alsovalid).id}"
    assert_response(:success)
  end
end
