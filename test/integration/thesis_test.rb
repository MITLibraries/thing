require 'test_helper'

class ThesisIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'posting valid thesis' do
    mock_auth(users(:basic))
    orig_count = Thesis.count
    post thesis_index_path,
         params: { thesis:
           { right_id: Right.first.id,
             department_ids: [Department.first.id],
             degree_ids: [Degree.first.id],
             title: 'yoyos are cool',
             abstract: 'We discovered it with science',
             graduation_month: 'June',
             graduation_year: Time.zone.today.year,
             files: fixture_file_upload('test/fixtures/files/a_pdf.pdf',
                                        'application/pdf') } }
    assert_equal orig_count + 1, Thesis.count
    assert_equal 'yoyos are cool', Thesis.last.title
    assert_equal 'We discovered it with science', Thesis.last.abstract
  end
end
