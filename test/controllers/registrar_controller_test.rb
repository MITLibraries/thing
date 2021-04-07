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
    @registrar = registrar(:valid)
    f = Rails.root.join('test','fixtures','files','registrar.csv')
    @registrar.graduation_list.attach(io: File.open(f), filename: 'registrar.csv')
    sign_in users(:thesis_admin)
    post '/registrar',
      params: {
        registrar: {
          graduation_list: fixture_file_upload('files/registrar.csv', 'text/csv')
        }
      }
    assert_response :redirect
    follow_redirect!
    assert_equal path, harvest_path
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
    get "/registrar/new"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1

    sign_in users(:basic)
    get "/registrar/#{registrar(:valid).id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors cannot submit or view a registrar' do
    sign_in users(:processor)
    get "/registrar/new"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1

    sign_in users(:processor)
    get "/registrar/#{registrar(:valid).id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'transfer_submitters cannot submit or view a registrar' do
    sign_in users(:transfer_submitter)
    get "/registrar/new"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1

    sign_in users(:transfer_submitter)
    get "/registrar/#{registrar(:valid).id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'Loading a request page initiates the import job' do
    sign_in users(:admin)
    registrar = Registrar.last
    registrar.graduation_list.attach(io: File.open('test/fixtures/files/registrar.csv'), filename: 'registrar.csv')
    assert_enqueued_with(job: RegistrarImportJob) do
      get "/harvest/" + registrar.id.to_s
    end
  end
end
