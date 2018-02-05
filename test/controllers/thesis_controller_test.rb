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
             department_ids: [departments(:one).id.to_s],
             degree_ids: [degrees(:one).id.to_s],
             right_id: rights(:one).id.to_s,
             graduation_year: (Time.current.year + 1).to_s,
             graduation_month: 'December'
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
             degree_ids: [degrees(:one).id.to_s],
             right_id: rights(:one).id.to_s,
             graduation_year: (Time.current.year + 1).to_s,
             graduation_month: 'December'
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

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ the processing queue ~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'submissions processing page exists' do
    sign_in users(:admin)
    get '/process'
    assert_response :success
  end

  test 'anon users cannot see submissions processing page' do
    # Note that nobody is signed in.
    get '/process'
    assert_response :redirect
  end

  test 'basic users cannot see submissions processing page' do
    sign_in users(:basic)
    assert_raises(CanCan::AccessDenied) do
      get '/process'
    end
  end

  test 'processor users can see submissions processing page' do
    sign_in users(:processor)
    get '/process'
    assert_response :success
  end

  test 'thesis admin users can see submissions processing page' do
    sign_in users(:thesis_admin)
    get '/process'
    assert_response :success
  end

  test 'sysadmin users can see submissions processing page' do
    sign_in users(:sysadmin)
    get '/process'
    assert_response :success
  end

  test 'admin users can see submissions processing page' do
    sign_in users(:admin)
    get '/process'
    assert_response :success
  end

  test 'submissions include submitter email' do
    sign_in users(:admin)
    get '/process'
    # Limit to the first 25 theses since that's all that will show up on the
    # first page.
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      assert @response.body.include? t.user.email
    end
  end

  test 'submissions include grad date' do
    sign_in users(:admin)
    get '/process'
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      friendly_date = "#{t.graduation_month} #{t.graduation_year}"
      assert @response.body.include? friendly_date
    end
  end

  test 'submissions include departments' do
    sign_in users(:admin)
    get '/process'
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      assert t.departments.map {|d| @response.body.include? d.name}.all?
    end
  end

  test 'submissions include degrees' do
    sign_in users(:admin)
    get '/process'
    expected_theses = Thesis.order('grad_date ASC').first(25)
    expected_theses.each do |t|
      assert t.degrees.map {|d| @response.body.include? d.name}.all?
    end
  end

  test 'submissions ordered by grad date ascending' do
    sign_in users(:admin)
    get '/process'
    theses = @controller.instance_variable_get(:@theses)
    theses.each_with_index do |t, i|
      assert t.grad_date <= theses[i + 1].grad_date if theses[i + 1].present?
    end
  end

  test 'link to submissions page visible to admin' do
    sign_in users(:admin)
    get '/'
    assert_select "a[href=?]", "/process"
  end

  test 'link to submissions page not visible to non-admin users' do
    sign_in users(:yo)
    get '/'
    assert_select "a[href=?]", "/process", count: 0
  end

  test 'link to submissions page not visible to anonymous users' do
    get '/'
    assert_select "a[href=?]", "/process", count: 0
  end

  test 'mark downloaded option available for active theses' do
    sign_in users(:admin)
    get '/process'
    thesis = theses(:active)
    assert_select "form[action=?]", "/done/#{thesis.id}"
  end

  test 'mark downloaded option not available for downloaded theses' do
    sign_in users(:admin)
    get '/process'
    thesis = theses(:downloaded)
    assert_select "form[action=?]", "/done/#{thesis.id}", count: 0
  end

  test 'mark downloaded option not available for withdrawn theses' do
    sign_in users(:admin)
    get '/process'
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
    assert_equal(Thesis.all.count,
                 @controller.instance_variable_get(:@theses).count)
    assert_equal(0,
      (Thesis.all - @controller.instance_variable_get(:@theses)).count)
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

  test 'theses of all statuses visible on all-theses page' do
    sign_in users(:admin)
    get process_path

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
    assert_response :success
    assert_equal 'downloaded', thesis.reload.status
  end

  test 'thesis admins can mark as downloaded' do
    sign_in users(:thesis_admin)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_downloaded_url(thesis), xhr: true
    assert_response :success
    assert_equal 'downloaded', thesis.reload.status
  end

  test 'processors can mark as downloaded' do
    sign_in users(:processor)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_downloaded_url(thesis), xhr: true
    assert_response :success
    assert_equal 'downloaded', thesis.reload.status
  end

  test 'mark thesis as downloaded - valid case' do
    sign_in users(:admin)
    thesis = theses(:active)
    post mark_downloaded_url(thesis), xhr: true

    assert_equal 'application/json', @response.content_type
    resp = JSON.parse(@response.body)
    assert resp.key? 'id'
    assert resp.key? 'saved'
    assert_equal thesis.id.to_s, resp['id']
    assert_equal true, resp['saved']
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
    assert_response :success
    assert_equal 'withdrawn', thesis.reload.status
  end

  test 'thesis admins can mark as withdrawn' do
    sign_in users(:thesis_admin)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_withdrawn_url(thesis), xhr: true
    assert_response :success
    assert_equal 'withdrawn', thesis.reload.status
  end

  test 'processors can mark as withdrawn' do
    sign_in users(:processor)
    thesis = theses(:active)
    assert_equal thesis.status, 'active'
    post mark_withdrawn_url(thesis), xhr: true
    assert_response :success
    assert_equal 'withdrawn', thesis.reload.status
  end

  test 'mark thesis as withdrawn - valid case' do
    sign_in users(:admin)
    thesis = theses(:active)
    post mark_withdrawn_url(thesis), xhr: true

    assert_equal 'application/json', @response.content_type
    resp = JSON.parse(@response.body)
    assert resp.key? 'id'
    assert resp.key? 'saved'
    assert_equal thesis.id.to_s, resp['id']
    assert_equal true, resp['saved']
  end

  test 'mark withdrawn option available for active theses' do
    sign_in users(:admin)
    get '/process'
    thesis = theses(:active)
    assert_select "form[action=?]", "/withdrawn/#{thesis.id}"
  end

  test 'mark withdrawn option available for downloaded theses' do
    sign_in users(:admin)
    get '/process'
    thesis = theses(:downloaded)
    assert_select "form[action=?]", "/withdrawn/#{thesis.id}"
  end

  test 'mark withdrawn option not available for withdrawn theses' do
    sign_in users(:admin)
    get '/process'
    thesis = theses(:withdrawn)
    assert_select "form[action=?]", "/withdrawn/#{thesis.id}",
      count: 0
  end
end
