require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  test 'overall card uses search term if present' do
    r = Report.new
    result = r.card_overall Thesis.all, 'all'
    assert_equal result['link']['url'], '/admin/theses'
    result = r.card_overall Thesis.all, Thesis.first.grad_date
    assert_match Thesis.first.grad_date.to_s, result['link']['url']
  end

  # populate_category is a private method that gets called by a few data_category_* methods, so we look for its
  # influence there.
  test 'populate_category will add rows for each expected value in the specified category' do
    r = Report.new
    expected_rows = License.count
    # Not all licenses are represented in our fixtures, so the query in the data_category_license method will return
    # fewer values than License.count will.
    assert_not_equal expected_rows, Thesis.all.joins(:license).pluck(:display_description).uniq.count
    # ...but by the time the controller has compiled this section of the report, starting with calling
    # populate_category, all possible values will be reflected.
    returned_rows = r.index_data['license'].count
    assert_equal expected_rows, returned_rows
    # This includes a row of all zeros, which could only have been generated by populate_category
    assert(r.index_data['license'][3][:data].values.all? { |v| v == 0 })
    # Also check that a row with expected data is represented accurately
    assert_equal r.index_data['license'][1][:data].values, [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  end

  # pad_terms is a private method that gets called by each reporting row, to ensure that all rows have some value for
  # all expected terms. As a private method we have no direct access (easily), so we instead look for its influence
  # indirectly.
  test 'pad_terms will add zeros for undefined academic terms' do
    r = Report.new
    expected_terms = Thesis.pluck(:grad_date).uniq.count
    # Not all terms have theses with issues in our test fixtures...
    assert_not_equal expected_terms, Thesis.all.group(:grad_date).where('issues_found = ?', true).count.count
    # ...but by the time we get data for display back from a report, all columns are present.
    returned_columns = r.index_data['summary'][3][:data].count
    assert_equal expected_terms, returned_columns
    # Test for a row of expected values
    assert_equal r.index_data['summary'][3][:data].values, [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]
  end

  # ~~~~ Dashboard report
  test 'dashboard includes a table of departments' do
    r = Report.new
    result = r.index_data
    assert_equal Department.count, result['departments'].pluck(:label).length
    assert_includes result['departments'].pluck(:label), Department.first.name_dw
    assert_equal result['departments'][0][:data].values, [1, 2, 0, 0, 0, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0]
  end

  test 'index includes summary data of authors not graduated' do
    thesis = theses(:bachelor)
    another_thesis = theses(:published)
    assert_not_equal thesis.grad_date, another_thesis.grad_date
    assert thesis.files?
    assert another_thesis.files?

    a = thesis.authors.first
    a.graduation_confirmed = false
    a.save
    assert_not thesis.authors_graduated?

    a = another_thesis.authors.first
    a.graduation_confirmed = false
    a.save
    assert_not another_thesis.authors_graduated?

    r = Report.new
    result = r.index_data
    assert_equal result['summary'][5][:data].values, [1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
  end

  test 'authors not graduated summary data dedups theses with multiple files' do
    thesis = theses(:bachelor)
    a = thesis.authors.first
    a.graduation_confirmed = false
    a.save
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    transfer = transfers(:valid)
    transfer.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    transfer.save
    transfer.reload
    thesis.files.attach(transfer.files.first.blob)
    thesis.save
    thesis.reload
    assert thesis.files.count > 1
    assert_not thesis.authors_graduated?

    r = Report.new
    result = r.index_data
    assert_not_equal result['summary'][5][:data].values, [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    assert_equal result['summary'][5][:data].values, [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  end

  # ~~~~ Term detail report
  test 'term detail includes a breakdown of departments' do
    r = Report.new
    subset = Thesis.where('grad_date = ?', '2018-06-01')
    result = r.term_tables subset
    assert_equal Department.count, result['departments']['data'].length
    assert_includes result['departments']['data'].keys, Department.first.name_dw
    assert_equal [2, 1, 0, 0], result['departments']['data'].values
  end
end
