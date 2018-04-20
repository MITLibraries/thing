require 'test_helper'

class ThesisIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
    @thesis_params = { right_id: Right.first.id,
      department_ids: Department.first.id,
      degree_ids: Degree.first.id,
      title: 'yoyos are cool',
      abstract: 'We discovered it with science',
      graduation_month: 'June',
      graduation_year: Time.zone.today.year,
      files: fixture_file_upload('test/fixtures/files/a_pdf.pdf',
                                 'application/pdf') }
  end

  def teardown
    auth_teardown
  end

  test 'posting valid thesis' do
    mock_auth(users(:basic))
    orig_count = Thesis.count
    post thesis_index_path, params: { thesis: @thesis_params }
    assert_equal orig_count + 1, Thesis.count
    assert_equal 'yoyos are cool', Thesis.last.title
    assert_equal 'We discovered it with science', Thesis.last.abstract
  end
  test 'invalid title message' do
    mock_auth(users(:basic))
    params = @thesis_params
    params[:title] = nil
    post thesis_index_path, params: { thesis: params }
    assert_select 'span.error', text: Thesis::VALIDATION_MSGS[:title]
  end

  test 'invalid abstract message' do
    mock_auth(users(:basic))
    params = @thesis_params
    params[:abstract] = nil
    post thesis_index_path, params: { thesis: params }
    assert_select 'span.error', text: Thesis::VALIDATION_MSGS[:abstract]
  end

  test 'invalid departments message' do
    mock_auth(users(:basic))
    params = @thesis_params
    params[:department_ids] = nil
    post thesis_index_path, params: { thesis: params }
    assert_select 'span.error', text: Thesis::VALIDATION_MSGS[:departments]
  end

  test 'invalid degrees message' do
    mock_auth(users(:basic))
    params = @thesis_params
    params[:degree_ids] = nil
    post thesis_index_path, params: { thesis: params }
    assert_select 'span.error', text: Thesis::VALIDATION_MSGS[:degrees]
  end

  test 'invalid right message' do
    mock_auth(users(:basic))
    params = @thesis_params
    params[:right_id] = nil
    post thesis_index_path, params: { thesis: params }
    assert_select "select.required[data-msg='#{Thesis::VALIDATION_MSGS[:right]}']"
  end

  test 'invalid files message' do
    mock_auth(users(:basic))
    params = @thesis_params
    params[:files] = nil
    post thesis_index_path, params: { thesis: params }
    assert_select "input.required[data-msg='#{Thesis::VALIDATION_MSGS[:files]}']"
  end

  test 'indicates active user' do
    mock_auth(users(:basic))
    msg = "You are logged in and submitting as #{users(:basic).display_name}."
    get new_thesis_path
    assert @response.body.include? msg
  end
end