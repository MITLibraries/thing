require 'test_helper'

class TransferControllerTest < ActionDispatch::IntegrationTest
  test 'new redirects to login if not logged in' do
    get '/transfer/new'
    assert_response :redirect
    assert_redirected_to '/users/auth/saml'
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ new transfer form ~~~~~~~~~~~~~~~~~~~~~
  test 'basic user cannot submit a transfer' do
    sign_in users(:basic)
    get "/transfer/new"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'transfer_submitter can submit a transfer' do
    sign_in users(:transfer_submitter)
    get '/transfer/new'
    assert_response :success
  end

  test 'thesis_processor cannot submit a transfer' do
    sign_in users(:processor)
    get "/transfer/new"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'thesis admins can submit a transfer' do
    sign_in users(:thesis_admin)
    get '/transfer/new'
    assert_response :success
  end

  test 'admins can submit a transfer' do
    sign_in users(:admin)
    get '/transfer/new'
    assert_response :success
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

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ transfer processing queue ~~~~~~~~~~~~~~~~~~~~~
  test 'transfer processing queue exists' do
    sign_in users(:admin)
    get transfer_select_path
    assert_response :success
  end

  test 'anonymous users cannot see transfer queue' do
    # Note that nobody signed in.
    get transfer_select_path
    assert_response :redirect
  end

  test 'basic users cannot see transfer queue' do
    sign_in users(:basic)
    get transfer_select_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'transfer submitters cannot see transfer queue' do
    sign_in users(:transfer_submitter)
    get transfer_select_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see transfer queue' do
    sign_in users(:processor)
    get transfer_select_path
    assert_response :success
  end

  test 'thesis admins can set transfer queue' do
    sign_in users(:thesis_admin)
    get transfer_select_path
    assert_response :success
  end

  test 'admins can see transfer queue' do
    sign_in users(:admin)
    get transfer_select_path
    assert_response :success
  end

  test 'transfer processing queue has links to transfer pages' do
    sign_in users(:thesis_admin)
    get transfer_select_path
    expected_transfers = Transfer.all
    expected_transfers.each do |t|
      assert @response.body.include? transfer_path(t)
    end
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ transfer processing form ~~~~~~~~~~~~~~~~~~~~~
  test 'transfer processing form exists' do
    sign_in users(:admin)
    get transfer_path(transfers(:valid))
    assert_response :success
  end

  test 'anonymous users are redirected to sign in when loading transfer processing form' do
    # Note that nobody signed in.
    get transfer_path(transfers(:valid))
    assert_response :redirect
    assert_redirected_to '/users/auth/saml'
  end

  test 'basic users cannot see a transfer processing form' do
    sign_in users(:basic)
    get transfer_path(transfers(:valid))
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'transfer_submitter users cannot see any transfer processing form' do
    sign_in users(:transfer_submitter)
    # transfer_submitter submitted the "valid" transfer fixture.
    get transfer_path(transfers(:valid))
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1

    # another user submitted the "alsovalid" transfer fixture.
    get transfer_path(transfers(:alsovalid))
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'thesis_processor users can see any transfer processing form' do
    sign_in users(:processor)
    get transfer_path(transfers(:valid))
    assert_response :success
    get transfer_path(transfers(:alsovalid))
    assert_response :success
  end

  test 'thesis_admin users can see any transfer processing form' do
    sign_in users(:thesis_admin)
    get transfer_path(transfers(:valid))
    assert_response :success
    get transfer_path(transfers(:alsovalid))
    assert_response :success
  end

  test 'admin users can see any transfer processing form' do
    sign_in users(:admin)
    get transfer_path(transfers(:valid))
    assert_response :success
    get transfer_path(transfers(:alsovalid))
    assert_response :success
  end

  test 'submitting transfer processing form provides feedback' do
    # Ideally our fixtures would have already-attached files, but they do not
    # yet. So we create a new Transfer here, with a file.
    sign_in users(:thesis_admin)
    post '/transfer',
      params: {
        transfer: {
          department_id: User.find_by(uid: "thesis_admin_id").submittable_departments.first.id.to_s,
          graduation_year: "2020",
          graduation_month: "February",
          user: User.find_by(uid: "thesis_admin_id"),
          files: fixture_file_upload('files/a_pdf.pdf', 'application/pdf')
        }
      }

    # Now we test the files method, for submitting a transfer processing form.
    post transfer_files_path,
      params: {
        id: Transfer.last.id,
        transfer: {
          file_ids: [Transfer.last.files.first.id]
        }
      }
    follow_redirect!
    assert_equal path, transfer_path(Transfer.last)
    assert_select 'div.alert.success', count: 1
    assert @response.body.include? Transfer.last.files.first.id.to_s
    assert @response.body.include? 'these 1 files would have been'
  end
end
