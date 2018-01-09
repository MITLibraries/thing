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
    bernanke_title = "Long-term commitments, dynamic optimization, and the business cycle"
    post '/thesis',
      params: { thesis: {
        title: bernanke_title,
        abstract: "This thesis paper consists of three loosely connected essays. Each paper is a theoretical study of some form of long-term commitment made by economic agents.",
        department_ids: [departments(:one).id.to_s],
        degree_ids: [degrees(:one).id.to_s],
        right_id: rights(:one).id.to_s,
        graduation_year: (Time.current.year + 1).to_s,
        graduation_month: 'December' } }
    assert_response :redirect
    assert_redirected_to thesis_path(Thesis.last)

    # Check assumption.
    assert_equal bernanke_title, Thesis.last.title
  end
end
