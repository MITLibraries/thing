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
    get "/transfer/new"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1

    sign_in users(:basic)
    get "/transfer/#{transfers(:valid).id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processor cannot submit a transfer' do
    sign_in users(:processor)
    get "/transfer/new"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'transfer submitter can view their own transfer' do
    sign_in users(:transfer_submitter)
    get "/transfer/#{transfers(:valid).id}"
    assert_response :success
  end

  test 'transfer submitter cannot view transfers they did not submit' do
    sign_in users(:transfer_submitter)
    get "/transfer/#{transfers(:alsovalid).id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
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

  test 'redirect after successful submission' do
    sign_in users(:transfer_submitter)
    post '/transfer',
      params: {
        transfer: {
          department_id: User.find_by(uid: "transfer_submitter_id").submittable_departments.first.id.to_s,
          graduation_year: "2020",
          graduation_month: "February",
          user: User.find_by(uid: "transfer_submitter_id"),
          files: fixture_file_upload('files/a_pdf.pdf', 'application/pdf')
        }
      }
    assert_response :redirect
    assert_redirected_to transfer_confirm_path
    follow_redirect!
    assert_select 'div.alert.success', count: 1
  end

  test 'rerender after failed submission' do
    original_count = Transfer.count
    sign_in users(:transfer_submitter)
    post '/transfer',
      params: {
        transfer: {
          user: User.find_by(uid: "transfer_submitter_id")
        }
      }
    assert_response :success
    assert_equal 'create', @controller.action_name
    assert_match "Error saving transfer", response.body
    assert_equal original_count, Transfer.count
  end
end
