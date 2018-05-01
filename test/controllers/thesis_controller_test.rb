require 'test_helper'

class ThesisControllerTest < ActionDispatch::IntegrationTest
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ the submission system ~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'new prompts for login' do
    get '/thesis/new'
    assert_response :redirect
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
             right_id: rights(:one).id.to_s,
             graduation_year: (Time.current.year + 1).to_s,
             graduation_month: 'September',
             files: fixture_file_upload('files/a_pdf.pdf', 'application/pdf')
           }
         }
    assert_response :redirect
    assert_redirected_to thesis_path(Thesis.last)

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
             right_id: rights(:one).id.to_s,
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
    assert_raises CanCan::AccessDenied do
      get "/thesis/#{theses(:one).id}"
    end
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

  test 'note field does not show on thesis submission page' do
    sign_in users(:yo)
    get new_thesis_path

    assert_select 'label', text: 'Note:', count: 0
    assert_select 'textarea.thesis_note', count: 0
  end

  test 'note does not show on thesis viewing page' do
    yo = users(:yo)
    sign_in yo

    thesis = Thesis.where(user: yo).first
    note_text = 'Yo dawg, I heard you like notes on your thesis'
    thesis.note = note_text
    thesis.save
    get thesis_path(thesis)

    assert_no_match note_text, response.body
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ the processing queue ~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'submissions processing page exists' do
    sign_in users(:admin)
    get process_path
    assert_response :success
  end

  test 'anon users cannot see submissions processing page' do
    # Note that nobody is signed in.
    get process_path
    assert_response :redirect
  end

  test 'basic users cannot see submissions processing page' do
    sign_in users(:basic)
    assert_raises(CanCan::AccessDenied) do
      get process_path
    end
  end

  test 'processor users can see submissions processing page' do
    sign_in users(:processor)
    get process_path
    assert_response :success
  end

  test 'thesis admin users can see submissions processing page' do
    sign_in users(:thesis_admin)
    get process_path
    assert_response :success
  end

  test 'sysadmin users can see submissions processing page' do
    sign_in users(:sysadmin)
    get process_path
    assert_response :success
  end

  test 'admin users can see submissions processing page' do
    sign_in users(:admin)
    get process_path
    assert_response :success
  end

  test 'submissions include submitter email' do
    sign_in users(:admin)
    get process_path
    # Limit to the first 25 theses since that's all that will show up on the
    # first page.
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      assert @response.body.include? t.user.email
    end
  end

  test 'submissions include grad date' do
    sign_in users(:admin)
    get process_path
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      friendly_date = "#{t.graduation_month} #{t.graduation_year}"
      assert @response.body.include? friendly_date
    end
  end

  test 'submissions include departments' do
    sign_in users(:admin)
    get process_path
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      assert t.departments.map {|d| @response.body.include? d.name}.all?
    end
  end

  test 'submissions include degrees' do
    sign_in users(:admin)
    get process_path
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      assert t.degrees.map {|d| @response.body.include? d.name}.all?
    end
  end

  test 'submissions ordered by grad date ascending' do
    sign_in users(:admin)
    get process_path
    theses = @controller.instance_variable_get(:@theses)
    theses.each_with_index do |t, i|
      assert t.grad_date <= theses[i + 1].grad_date if theses[i + 1].present?
    end
  end

  test 'note field visible' do
    sign_in users(:admin)
    get process_path

    # Expected number of theses on page (all of them or max # allowed by
    # the pagination, whichever is lower).
    count = Thesis.where(status: 'active').count
    num_theses = if count > 25
                   25
                 else
                   count
                 end

    assert_select 'label', text: 'Note:', count: num_theses
    assert_select 'textarea', count: num_theses
    assert_select 'input[value="Update note"]', count: num_theses
  end

  test 'link to submissions page visible to admin' do
    sign_in users(:admin)
    get '/'
    assert_select "a[href=?]", process_path
  end

  test 'link to submissions page visible to processors' do
    sign_in users(:processor)
    get '/'
    assert_select "a[href=?]", process_path
  end

  test 'link to submissions page visible to thesis admins' do
    sign_in users(:thesis_admin)
    get '/'
    assert_select "a[href=?]", process_path
  end

  test 'link to submissions page not visible to non-admin users' do
    sign_in users(:yo)
    get '/'
    assert_select "a[href=?]", process_path, count: 0
  end

  test 'link to submissions page not visible to anonymous users' do
    get '/'
    assert_select "a[href=?]", process_path, count: 0
  end

  test 'mark downloaded option available for active theses' do
    sign_in users(:admin)
    get process_path
    thesis = theses(:active)
    assert_select "form[action=?]", "/done/#{thesis.id}"
  end

  test 'mark downloaded option not available for downloaded theses' do
    sign_in users(:admin)
    get process_path
    thesis = theses(:downloaded)
    assert_select "form[action=?]", "/done/#{thesis.id}", count: 0
  end

  test 'mark downloaded option not available for withdrawn theses' do
    sign_in users(:admin)
    get process_path
    thesis = theses(:withdrawn)
    assert_select "div[data-id=thesis_#{thesis.id}] form", count: 0
  end

  # ~~~~~~~~~~~~~~~~~~~~ filters on the processing queue ~~~~~~~~~~~~~~~~~~~~~~
  test 'queryset when no status is given' do
    sign_in users(:admin)
    get process_path

    # We want to make sure that this queryset returned by the controller is the
    # same as the all-theses queryset. This is surprisingly irritating. So
    # we assert that they have the same number of elements, and that their
    # set difference is empty; this is mathematically the same as saying
    # they're equal.
    assert_equal(Thesis.where(status: 'active').count,
                 @controller.instance_variable_get(:@theses).count)
    assert_equal(0,
      (Thesis.where(status: 'active') -
        @controller.instance_variable_get(:@theses)
      ).count)
  end

  test 'queryset when status is active' do
    sign_in users(:admin)
    get process_path(status: 'active')
    active_theses = Thesis.where(status: 'active')

    assert active_theses.count > 0
    assert_equal(active_theses.count,
                 @controller.instance_variable_get(:@theses).count)
    assert_equal(0,
      (active_theses - @controller.instance_variable_get(:@theses)).count)
  end

  test 'queryset when status is withdrawn' do
    sign_in users(:admin)
    get process_path(status: 'withdrawn')
    withdrawn_theses = Thesis.where(status: 'withdrawn')

    assert withdrawn_theses.count > 0
    assert_equal(withdrawn_theses.count,
                 @controller.instance_variable_get(:@theses).count)
    assert_equal(0,
      (withdrawn_theses - @controller.instance_variable_get(:@theses)).count)
  end

  test 'queryset when status is downloaded' do
    sign_in users(:admin)
    get process_path(status: 'downloaded')
    downloaded_theses = Thesis.where(status: 'downloaded')

    assert downloaded_theses.count > 0
    assert_equal(downloaded_theses.count,
                 @controller.instance_variable_get(:@theses).count)
    assert_equal(0,
      (downloaded_theses - @controller.instance_variable_get(:@theses)).count)
  end

  test 'queryset when status is bogus' do
    sign_in users(:admin)
    get process_path(status: 'bogus')
    bogus_theses = Thesis.where(status: 'bogus')

    assert_not Thesis::STATUS_OPTIONS.include?('bogus')

    assert_equal 0, bogus_theses.count
    assert_equal(bogus_theses.count,
                 @controller.instance_variable_get(:@theses).count)
    assert_equal(0,
      (bogus_theses - @controller.instance_variable_get(:@theses)).count)
  end

  test 'only active theses visible on base page' do
    sign_in users(:admin)
    get process_path

    assert_select "a[href=?]", thesis_path(theses(:active))
    assert_select "a[href=?]", thesis_path(theses(:withdrawn)), count: 0
    assert_select "a[href=?]", thesis_path(theses(:downloaded)), count: 0
  end

  test 'theses of all statuses visible on all-theses page' do
    sign_in users(:admin)
    get process_path(status: 'any')

    assert_select "a[href=?]", thesis_path(theses(:active))
    assert_select "a[href=?]", thesis_path(theses(:withdrawn))
    assert_select "a[href=?]", thesis_path(theses(:downloaded))
  end

  test 'only active theses visible on active theses page' do
    sign_in users(:admin)
    get process_path(status: 'active')

    assert_select "a[href=?]", thesis_path(theses(:active))
    assert_select "a[href=?]", thesis_path(theses(:withdrawn)), count: 0
    assert_select "a[href=?]", thesis_path(theses(:downloaded)), count: 0
  end

  test 'only downloaded theses visible on downloaded theses page' do
    sign_in users(:admin)
    get process_path(status: 'downloaded')

    assert_select "a[href=?]", thesis_path(theses(:active)), count: 0
    assert_select "a[href=?]", thesis_path(theses(:withdrawn)), count: 0
    assert_select "a[href=?]", thesis_path(theses(:downloaded))
  end

  test 'only withdrawn theses visible on withdrawn theses page' do
    sign_in users(:admin)
    get process_path(status: 'withdrawn')

    assert_select "a[href=?]", thesis_path(theses(:active)), count: 0
    assert_select "a[href=?]", thesis_path(theses(:withdrawn))
    assert_select "a[href=?]", thesis_path(theses(:downloaded)), count: 0
  end

  test 'no theses visible on bogus-status theses page' do
    sign_in users(:admin)
    get process_path(status: 'pickled')

    assert_select "a[href=?]", thesis_path(theses(:active)), count: 0
    assert_select "a[href=?]", thesis_path(theses(:withdrawn)), count: 0
    assert_select "a[href=?]", thesis_path(theses(:downloaded)), count: 0
  end

  test 'default sort is by date' do
    sign_in users(:admin)
    get process_path
    theses = @controller.instance_variable_get(:@theses)
    assert theses.first.grad_date <= theses.second.grad_date
    assert theses.second.grad_date <= theses.third.grad_date
  end

  test 'can be sorted by date on purpose' do
    sign_in users(:admin)
    get process_path(sort: 'date')
    theses = @controller.instance_variable_get(:@theses)
    assert theses.first.grad_date <= theses.second.grad_date
    assert theses.second.grad_date <= theses.third.grad_date
  end

  test 'can be sorted by name' do
    sign_in users(:admin)
    get process_path(sort: 'name')
    theses = @controller.instance_variable_get(:@theses)
    assert theses.first.user.surname <= theses.second.user.surname
    assert theses.second.user.surname <= theses.third.user.surname
  end

  test 'can be filtered by start year' do
    sign_in users(:admin)
    get process_path(start_year: '2019')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_not view_theses.exists? theses(:june_2018).id
    assert_not view_theses.exists? theses(:september_2018).id
    assert view_theses.exists? theses(:june_2019).id
    assert view_theses.exists? theses(:september_2019).id
  end

  test 'start year filter is inclusive' do
    sign_in users(:admin)
    get process_path(start_year: '2019')
    view_theses = @controller.instance_variable_get(:@theses)
    assert view_theses.exists? theses(:february_2019).id
    assert view_theses.exists? theses(:june_2019).id
    assert view_theses.exists? theses(:september_2019).id
  end

  test 'filtering by start year does not flash errors' do
    sign_in users(:admin)
    get process_path(start_year: '2019')
    assert_not flash.key? :start
    assert_not flash.key? :end
  end

  test 'can be filtered by start year and month' do
    sign_in users(:admin)
    get process_path(start_year: '2019', start_month: '7')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_not view_theses.exists? theses(:june_2018).id
    assert_not view_theses.exists? theses(:september_2018).id
    assert_not view_theses.exists? theses(:june_2019).id
    assert view_theses.exists? theses(:september_2019).id
  end

  test 'start year and month filter is inclusive' do
    sign_in users(:admin)
    get process_path(start_year: '2019', start_month: '6')
    view_theses = @controller.instance_variable_get(:@theses)
    assert view_theses.exists? theses(:june_2019).id
  end

  test 'filtering by start year and month does not flash errors' do
    sign_in users(:admin)
    get process_path(start_year: '2019', start_month: '6')
    assert_not flash.key? :start
    assert_not flash.key? :end
  end

  test 'can be filtered by end year' do
    sign_in users(:admin)
    get process_path(end_year: '2018')
    view_theses = @controller.instance_variable_get(:@theses)
    assert view_theses.exists? theses(:june_2018).id
    assert view_theses.exists? theses(:september_2018).id
    assert_not view_theses.exists? theses(:june_2019).id
    assert_not view_theses.exists? theses(:september_2019).id
  end

  test 'end year filter is inclusive' do
    sign_in users(:admin)
    get process_path(end_year: '2019')
    view_theses = @controller.instance_variable_get(:@theses)
    assert view_theses.exists? theses(:june_2019).id
    assert view_theses.exists? theses(:september_2019).id
  end

  test 'filtering by end year does not flash errors' do
    sign_in users(:admin)
    get process_path(end_year: '2019')
    assert_not flash.key? :start
    assert_not flash.key? :end
  end

  test 'can be filtered by end year and month' do
    sign_in users(:admin)
    get process_path(end_year: '2019', end_month: '7')
    view_theses = @controller.instance_variable_get(:@theses)
    assert view_theses.exists? theses(:june_2018).id
    assert view_theses.exists? theses(:september_2018).id
    assert view_theses.exists? theses(:june_2019).id
    assert_not view_theses.exists? theses(:september_2019).id
  end

  test 'end year and month filter is inclusive' do
    sign_in users(:admin)
    get process_path(end_year: '2019', end_month: '6')
    view_theses = @controller.instance_variable_get(:@theses)
    assert view_theses.exists? theses(:june_2019).id
  end

  test 'filtering by end year and month does not flash errors' do
    sign_in users(:admin)
    get process_path(end_year: '2019', end_month: '6')
    assert_not flash.key? :start
    assert_not flash.key? :end
  end

  test 'can be filtered by both start and end dates' do
    sign_in users(:admin)
    get process_path(start_year: '2018', start_month: '7',
                     end_year: '2019', end_month: '6')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_not view_theses.exists? theses(:june_2018).id
    assert view_theses.exists? theses(:september_2018).id
    assert view_theses.exists? theses(:june_2019).id
    assert_not view_theses.exists? theses(:september_2019).id
  end

  test 'rejects start month without year' do
    sign_in users(:admin)
    get process_path(start_month: '6')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_equal view_theses.count, Thesis.where(status: 'active').count
    assert flash[:start].present?
  end

  test 'rejects start month with empty year' do
    sign_in users(:admin)
    get process_path(start_month: '6', start_year: '')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_equal view_theses.count, Thesis.where(status: 'active').count
    assert flash[:start].present?
  end

  test 'rejects end month without year' do
    sign_in users(:admin)
    get process_path(end_month: '6')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_equal view_theses.count, Thesis.where(status: 'active').count
    assert flash[:end].present?
  end

  test 'rejects end month with empty year' do
    sign_in users(:admin)
    get process_path(end_month: '6', end_year: '')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_equal view_theses.count, Thesis.where(status: 'active').count
    assert flash[:end].present?
  end

  test 'has a date filtering form' do
    sign_in users(:admin)
    get process_path
    assert_select 'form'
    assert_select 'select#start_year'
    assert_select 'select#start_month'
    assert_select 'select#end_year'
    assert_select 'select#end_month'
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ marking downloads ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'non-authenticated users cannot mark as downloaded' do
    thesis = theses(:active)
    post mark_downloaded_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'active', thesis.reload.status
  end

  test 'basic users cannot mark as downloaded' do
    sign_in users(:basic)
    thesis = theses(:active)
    assert_raises CanCan::AccessDenied do
      post mark_downloaded_url(thesis), xhr: true
    end
    assert_equal 'active', thesis.reload.status
  end

  test 'admins can mark as downloaded' do
    sign_in users(:admin)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_downloaded_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'downloaded', thesis.reload.status
  end

  test 'thesis admins can mark as downloaded' do
    sign_in users(:thesis_admin)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_downloaded_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'downloaded', thesis.reload.status
  end

  test 'processors can mark as downloaded' do
    sign_in users(:processor)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_downloaded_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'downloaded', thesis.reload.status
  end

  test 'cannot mark theses if already downloaded' do
    sign_in users(:admin)
    thesis = theses(:downloaded)
    assert_raises ActionController::BadRequest do
      post mark_downloaded_url(thesis), xhr: true
    end
  end

  test 'cannot mark theses as downloaded if withdrawn' do
    sign_in users(:admin)
    thesis = theses(:withdrawn)
    assert_raises ActionController::BadRequest do
      post mark_downloaded_url(thesis), xhr: true
    end
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ marking withdrawn ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'non-authenticated users cannot mark as withdrawn' do
    thesis = theses(:active)
    post mark_withdrawn_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'active', thesis.reload.status
  end

  test 'basic users cannot mark as withdrawn' do
    sign_in users(:basic)
    thesis = theses(:active)
    assert_raises CanCan::AccessDenied do
      post mark_withdrawn_url(thesis), xhr: true
    end
    assert_equal 'active', thesis.reload.status
  end

  test 'admins can mark as withdrawn' do
    sign_in users(:admin)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_withdrawn_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'withdrawn', thesis.reload.status
  end

  test 'thesis admins can mark as withdrawn' do
    sign_in users(:thesis_admin)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_withdrawn_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'withdrawn', thesis.reload.status
  end

  test 'processors can mark as withdrawn' do
    sign_in users(:processor)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_withdrawn_url(thesis), xhr: true
    assert_response :redirect
    assert_equal 'withdrawn', thesis.reload.status
  end

  test 'mark withdrawn option available for active theses' do
    sign_in users(:admin)
    get process_path
    thesis = theses(:active)
    assert_select "form[action=?]", "/withdrawn/#{thesis.id}"
  end

  test 'mark withdrawn option available for downloaded theses' do
    sign_in users(:admin)
    get process_path(status: 'downloaded')
    thesis = theses(:downloaded)
    assert_select "form[action=?]", "/withdrawn/#{thesis.id}"
  end

  test 'mark withdrawn option not available for withdrawn theses' do
    sign_in users(:admin)
    get process_path(status: 'withdrawn')
    thesis = theses(:withdrawn)
    assert_select "form[action=?]", "/withdrawn/#{thesis.id}",
      count: 0
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ adding notes  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'non-authenticated users cannot add notes' do
    thesis = theses(:with_note)
    orig_note = thesis.note
    target_note = 'Best consumed with scooby snacks'
    note_field_id = "note_#{thesis.id}"
    post annotate_url(thesis),
      params: Hash[note_field_id, target_note], xhr: true
    assert_response :redirect
    assert_equal orig_note, thesis.reload.note
  end

  test 'basic users cannot add notes' do
    sign_in users(:basic)
    thesis = theses(:with_note)
    orig_note = thesis.note
    target_note = 'Best consumed with scooby snacks'
    note_field_id = "note_#{thesis.id}"
    assert_raises CanCan::AccessDenied do
      post annotate_url(thesis),
        params: Hash[note_field_id, target_note], xhr: true
    end
    assert_equal orig_note, thesis.reload.note
  end

  test 'admins can add notes' do
    sign_in users(:admin)
    thesis = theses(:with_note)
    target_note = 'Best consumed with scooby snacks'
    note_field_id = "note_#{thesis.id}"
    post annotate_url(thesis),
      params: Hash[note_field_id, target_note], xhr: true
    assert_response :redirect
    assert_equal target_note, thesis.reload.note
  end

  test 'thesis admins can add notes' do
    sign_in users(:thesis_admin)
    thesis = theses(:with_note)
    target_note = 'Best consumed with scooby snacks'
    note_field_id = "note_#{thesis.id}"
    post annotate_url(thesis),
      params: Hash[note_field_id, target_note], xhr: true
    assert_response :redirect
    assert_equal target_note, thesis.reload.note
  end

  test 'processors can add notes' do
    sign_in users(:processor)
    thesis = theses(:with_note)
    target_note = 'Best consumed with scooby snacks'
    note_field_id = "note_#{thesis.id}"
    post annotate_url(thesis),
      params: Hash[note_field_id, target_note], xhr: true
    assert_response :redirect
    assert_equal target_note, thesis.reload.note
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ stats ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'non-authenticated users cannot see stats' do
    get stats_path
    assert_response :redirect
  end

  test 'basic users cannot see stats' do
    sign_in users(:basic)
    assert_raises CanCan::AccessDenied do
      get stats_path
    end
  end

  test 'thesis processors can see stats' do
    sign_in users(:processor)
    get stats_path
    assert_response :success
  end

  test 'thesis admins can see stats' do
    sign_in users(:thesis_admin)
    get stats_path
    assert_response :success
  end

  test 'admins can see stats' do
    sign_in users(:admin)
    get stats_path
    assert_response :success
  end

  test 'basic page content' do
    sign_in users(:processor)
    get stats_path
    assert_select 'h3', text: 'Statistics'
    assert_select 'table'
    assert @response.body.downcase.include? 'filter by graduation date'
  end

  # Just spot check the filtering here, as we tested the filters extensively
  # above for the processing queue.
  test 'stats can be filtered by both start and end dates' do
    sign_in users(:admin)
    get stats_path(start_year: '2018', start_month: '7',
                     end_year: '2019', end_month: '6')
    view_theses = @controller.instance_variable_get(:@theses)
    assert_not view_theses.exists? theses(:june_2018).id
    assert view_theses.exists? theses(:september_2018).id
    assert view_theses.exists? theses(:june_2019).id
    assert_not view_theses.exists? theses(:september_2019).id
  end
end
