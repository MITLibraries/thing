require 'test_helper'

class ThesisControllerTest < ActionDispatch::IntegrationTest
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
end
