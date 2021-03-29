require 'test_helper'

class AdminThesisTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'accessing theses panel works with admin rights' do
    mock_auth(users(:admin))
    get '/admin/theses'
    assert_response :success
    assert_equal('/admin/theses', path)
  end

  test 'accessing theses panel works with thesis_admin rights' do
    mock_auth(users(:thesis_admin))
    get '/admin/theses'
    assert_response :success
    assert_equal('/admin/theses', path)
  end

  test 'accessing theses panel works with processor rights' do
    mock_auth(users(:processor))
    get '/admin/theses'
    assert_response :success
  end

  test 'accessing theses panel does not work with basic rights' do
    mock_auth(users(:basic))
    get '/admin/theses'
    assert_response :redirect
  end

  test 'thesis admins can view an admin theses show page' do
    mock_auth(users(:thesis_admin))
    get admin_thesis_path(theses(:one))
    assert_response :success
  end

  test 'thesis admins can access the thesis edit form through admin panel' do
    mock_auth(users(:thesis_admin))
    get "/admin/theses/#{theses(:one).id}/edit"
    assert_response :success
  end

  test 'thesis admins can update theses through admin panel' do
    mock_auth(users(:thesis_admin))

    thesis = Thesis.first
    new_title = 'yoyos are cool'
    assert_not_equal thesis.title, new_title

    patch admin_thesis_path(thesis), 
      params: { thesis: { user_ids: [ User.first.id ], 
                          title: new_title
                        } 
              }

    thesis.reload
    assert_response :redirect
    assert_equal path, admin_thesis_path(thesis)
    assert_equal new_title, thesis.title
  end

  test 'thesis admins can create theses through admin panel' do
    user = users(:thesis_admin)
    mock_auth(user)

    orig_count = Thesis.count

    # Important! Enter the grad month and year, not the grad date. The Thesis
    # model does some before-creation logic to combine the month and year into
    # the grad_date attribute on the model instance.
    post admin_theses_path,
      params: { thesis: { user_ids: [ user.id ],
                          department_ids: [ Department.first.id ],
                          degree_ids: [ Degree.first.id ],
                          advisor_ids: [ Advisor.first.id ],
                          title: 'yoyos are cool',
                          abstract: 'We discovered it with science',
                          graduation_month: 'June',
                          graduation_year: Date.today.year
                        },
              }
    assert_equal orig_count + 1, Thesis.count
    assert_equal 'yoyos are cool', Thesis.last.title
    assert_equal 'We discovered it with science', Thesis.last.abstract
  end

  test 'thesis admins cannot destroy theses through admin panel' do
    mock_auth(users(:thesis_admin))

    thesis = Thesis.first
    # Cache this, because the thesis will stop existing if the delete goes
    # through.
    thesis_id = thesis.id
    assert Thesis.exists?(thesis_id)

    delete admin_thesis_path(thesis)
    assert Thesis.exists?(thesis_id)
  end

  test 'admins can destroy theses through admin panel' do
    mock_auth(users(:admin))

    thesis = Thesis.first
    # Cache this, because the thesis will stop existing if the delete goes
    # through.
    thesis_id = thesis.id
    assert Thesis.exists?(thesis_id)

    delete admin_thesis_path(thesis)
    assert !Thesis.exists?(thesis_id)
  end

  test 'basic users cannot destroy theses' do
    mock_auth(users(:basic))

    thesis = Thesis.first
    # Cache this, because the thesis will stop existing if the delete goes
    # through.
    thesis_id = thesis.id

    delete admin_thesis_path(thesis)
    assert Thesis.exists?(thesis_id)
  end

  test 'anonymous users cannot destroy theses' do
    thesis = Thesis.first
    # Cache this, because the thesis will stop existing if the delete goes
    # through.
    thesis_id = thesis.id

    delete admin_thesis_path(thesis)
    assert Thesis.exists?(thesis_id)
  end

  test 'thesis view includes a button to create a new hold for thesis' do
    mock_auth(users(:admin))
    t = theses(:one)
    get "/admin/theses/#{t.id}"
    assert_select "a[href=?]", "/admin/holds/new?thesis_id=#{t.id}"
  end

  test 'can assign advisors to theses via thesis panel' do
    needle = advisors(:second)
    user = users(:yo)
    mock_auth(users(:thesis_admin))
    thesis = Thesis.first
    assert_equal thesis.advisors.count, 0
    patch admin_thesis_path(thesis),
      params: { thesis: { user_ids: [user.id],
                          advisor_ids: [needle.id] } }
    thesis.reload
    assert_equal thesis.advisors.count, 1
    assert_equal needle.name, thesis.advisors.first.name
  end

  test 'can assign copyright to theses via thesis panel' do
    needle = copyrights(:mit)
    user = users(:yo)
    mock_auth(users(:thesis_admin))
    thesis = Thesis.first
    assert_not_equal needle.id, thesis.copyright_id

    patch admin_thesis_path(thesis),
      params: { thesis: { user_ids: [user.id],
                          copyright_id: needle.id } }
    thesis.reload
    assert_equal needle.id, thesis.copyright_id
  end

  test 'can assign license to theses via thesis panel' do
    needle = licenses(:nocc)
    user = users(:yo)
    mock_auth(users(:thesis_admin))
    thesis = Thesis.first
    assert_not_equal needle.id, thesis.license_id

    patch admin_thesis_path(thesis),
      params: { thesis: { user_ids: [user.id],
                          license_id: needle.id } }
    thesis.reload
    assert_equal needle.id, thesis.license_id
  end

  test 'updating theses through admin panel does not send emails' do
    mock_auth(users(:thesis_admin))

    thesis = Thesis.first

    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_emails 0 do
        patch admin_thesis_path(thesis),
          params: { thesis: { user_ids: [ User.first.id ],
                              title: 'new title'
                            }
                  }

      end
    end
  end
end
