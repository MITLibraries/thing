require 'test_helper'

class RegistrarControllerTest < ActionDispatch::IntegrationTest
  test 'submit redirects to login' do
    get '/registrar/new'
    assert_response :redirect
    assert_redirected_to '/users/auth/saml'
  end

  test 'view redirects to login' do
    get "/registrar/#{registrar(:valid).id}"
    assert_response :redirect
    assert_redirected_to '/users/auth/saml'
  end

  test 'thesis_admins can submit and view registrar' do
    sign_in users(:thesis_admin)
    get '/registrar/new'
    assert_response :success
    get "/registrar/#{registrar(:valid).id}"
    assert_response :success
  end

  test 'admins can submit and view a registrar' do
    sign_in users(:admin)
    get '/registrar/new'
    assert_response :success
    get "/registrar/#{registrar(:valid).id}"
    assert_response :success
  end

  test 'confirmation of successful submission' do
    sign_in users(:thesis_admin)
    post '/registrar',
      params: {
        registrar: {
          graduation_list: fixture_file_upload('files/registrar.csv', 'text/csv')
        }
      }
    assert_response :redirect
    follow_redirect!
    assert_equal path, '/'
    assert_not @response.body.include? "Error"
    assert @response.body.include? "Thank you for submitting this Registrar file."
  end

  test 'flash message if invalid submission' do
    sign_in users(:thesis_admin)
    post '/registrar',
      params: {
        registrar: {
          graduation_list: nil
        }
      }
    assert_equal path, '/registrar'
    assert @response.body.include? "Error saving Registrar file:"
  end

  test 'basic user cannot submit or view a registrar' do
    sign_in users(:basic)
    assert_raises CanCan::AccessDenied do
      get "/registrar/new"
    end
    sign_in users(:basic)
    assert_raises CanCan::AccessDenied do
      get "/registrar/#{registrar(:valid).id}"
    end
  end

  test 'processors cannot submit or view a registrar' do
    sign_in users(:processor)
    assert_raises CanCan::AccessDenied do
      get "/registrar/new"
    end
    sign_in users(:processor)
    assert_raises CanCan::AccessDenied do
      get "/registrar/#{registrar(:valid).id}"
    end
  end

  test 'transfer_submitters cannot submit or view a registrar' do
    sign_in users(:transfer_submitter)
    assert_raises CanCan::AccessDenied do
      get "/registrar/new"
    end
    sign_in users(:transfer_submitter)
    assert_raises CanCan::AccessDenied do
      get "/registrar/#{registrar(:valid).id}"
    end
  end
end
