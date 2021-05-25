require 'test_helper'

class ThesisControllerTest < ActionDispatch::IntegrationTest
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ the submission system ~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'new prompts for login' do
    get '/thesis/new'
    assert_redirected_to '/users/auth/saml'
  end

  test 'new when logged in' do
    sign_in users(:yo)
    get '/thesis/new'
    assert_response :success
  end

  test 'redirect after successful submission' do
    sign_in users(:yo)
    title = 'Spacecraft avoidance: a short'
    post '/thesis',
         params: {
           thesis: {
             title: title,
             abstract: 'Frook.',
             department_ids: departments(:one).id.to_s,
             degree_ids: degrees(:one).id.to_s,
             graduation_year: (Time.current.year + 1).to_s,
             graduation_month: 'September',
             files: fixture_file_upload('files/a_pdf.pdf', 'application/pdf')
           }
         }
    assert_response :redirect
    assert_redirected_to thesis_confirm_path

    # Check assumption.
    assert_equal title, Thesis.last.title
  end

  test 'rerender after failed submission' do
    sign_in users(:yo)
    orig_thesis_count = Thesis.count
    title = 'Spacecraft avoidance: a short'
    post '/thesis',
         params: {
           thesis: {
             title: title,
             abstract: 'Frook.',
             # The missing department ids here should cause the form to fail.
             degree_ids: degrees(:one).id.to_s,
             graduation_year: (Time.current.year + 1).to_s,
             graduation_month: 'December',
             files: fixture_file_upload('files/a_pdf.pdf', 'application/pdf')
           }
         }
    # We expect a 200 OK for the http call, even though the form submission is
    # not a success.
    assert_response :success
    assert_equal('create', @controller.action_name)

    # No new theses have been created.
    assert_equal(orig_thesis_count, Thesis.count)
  end

  test 'user can view their own thesis' do
    sign_in users(:yo)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  test 'user cannot view another user thesis' do
    sign_in users(:bad)
    get "/thesis/#{theses(:one).id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'anonymous user cannot view another user thesis' do
    get "/thesis/#{theses(:one).id}"
    assert_response :redirect
  end

  test 'admin users can view another user thesis' do
    sign_in users(:admin)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  test 'thesis_admin users can view another user thesis' do
    sign_in users(:thesis_admin)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  test 'processor users can view another user thesis' do
    sign_in users(:processor)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  # Tests below this note are to protect us from our future selves.
  # Currently we have no routes for delete/update or controller actions to
  # handle this, but I'm adding these tests to remind us in the future that if
  # we do add those features we need to confirm the abilities match our
  # expectations as these tests will fail and we'll need to make decisions.
  test 'a user cannot delete their thesis' do
    sign_in users(:yo)
    assert_raises(ActionController::RoutingError) do
      delete "/thesis/#{theses(:one).id}"
    end
  end

  test 'an anonymous user cannot delete a thesis' do
    assert_raises(ActionController::RoutingError) do
      delete "/thesis/#{theses(:one).id}"
    end
  end

  # admin users _can_ do this in the admin interface
  test 'an admin user cannot delete a user thesis' do
    sign_in users(:admin)
    assert_raises(ActionController::RoutingError) do
      delete "/thesis/#{theses(:one).id}"
    end
  end

  test 'a user cannot update their thesis' do
    sign_in users(:yo)
    assert_raises(ActionController::RoutingError) do
      post "/thesis/#{theses(:one).id}",
           params: { thesis: { title: 'yoyos are cool' } }
    end
  end

  test 'an anonymous user cannot update a thesis' do
    assert_raises(ActionController::RoutingError) do
      post "/thesis/#{theses(:one).id}",
           params: { thesis: { title: 'yoyos are cool' } }
    end
  end

  # admin users _can_ do this in the admin interface
  test 'an admin user cannot update a user thesis' do
    sign_in users(:admin)
    assert_raises(ActionController::RoutingError) do
      post "/thesis/#{theses(:one).id}",
           params: { thesis: { title: 'yoyos are cool' } }
    end
  end

  test 'processor note field does not show on thesis submission page' do
    sign_in users(:yo)
    get new_thesis_path

    assert_select 'label', text: 'Note:', count: 0
    assert_select 'textarea.thesis_note', count: 0
  end

  test 'processor note does not show on thesis viewing page' do
    yo = users(:yo)
    sign_in yo

    thesis = yo.theses.first
    note_text = 'Yo dawg, I heard you like notes on your thesis'
    thesis.processor_note = note_text
    thesis.save
    get thesis_path(thesis)

    assert_no_match note_text, response.body
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~ thesis processing queue ~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'thesis processing queue exists' do
    sign_in users(:admin)
    get thesis_select_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by processing queue' do
    # Note that nobody is signed in.
    get thesis_select_path
    assert_response :redirect
  end

  test 'basic users cannot see processing queue' do
    sign_in users(:basic)
    get thesis_select_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see processing queue' do
    sign_in users(:transfer_submitter)
    get thesis_select_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see processing queue' do
    sign_in users(:processor)
    get thesis_select_path
    assert_response :success
  end

  test 'thesis_admins can see processing queue' do
    sign_in users(:thesis_admin)
    get thesis_select_path
    assert_response :success
  end

  test 'admins can see processing queue' do
    sign_in users(:admin)
    get thesis_select_path
    assert_response :success
  end

  test 'processing queue shows nothing without work done' do
    sign_in users(:processor)
    get thesis_select_path
    assert @response.body.include? "No theses found"
  end

  test 'processing queue shows a record with file attached' do
    # Attach a file to the thesis
    t = theses(:with_hold)
    f = Rails.root.join('test','fixtures','files','a_pdf.pdf')
    t.files.attach(io: File.open(f), filename: 'a_pdf.pdf')

    # Make sure each thesis' timestamp appears on the page
    sign_in users(:processor)
    get thesis_select_path
    expected_theses = Thesis.joins(:files_attachments).group(:id).where('publication_status != ?', "Published")
    expected_theses.each do |et|
      assert et.files.map {|item| @response.body.include? item.created_at.to_s}.all?
    end
  end

  test 'processing queue allows filtering by term' do
    # Attach files to two theses
    t1 = theses(:with_hold)
    t2 = theses(:active)
    f = Rails.root.join('test','fixtures','files','a_pdf.pdf')
    t1.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    t2.files.attach(io: File.open(f), filename: 'a_pdf.pdf')

    # Request the processing queue and note two records, with three filter
    # options (two specific terms, and the "all terms" option)
    sign_in users(:processor)
    get thesis_select_path
    assert_select 'table#thesisQueue tbody tr', count: 2
    assert_select 'select[name="graduation"] option', count: 3
    # Now request the queue with a filter applied, and see only one record
    get thesis_select_path, params: { graduation: '2018-09-01' }
    assert_select 'table#thesisQueue tbody tr', count: 1
  end
end
