require 'test_helper'

include ThesisHelper

class ThesisHelperTest < ActionView::TestCase
  test 'title helper can handle nils' do
    @thesis = Thesis.new
    assert_equal 'Untitled thesis', title_helper(@thesis)
  end

  test 'title helper can empty titles' do
    @thesis = Thesis.new(title: '')
    assert_equal 'Untitled thesis', title_helper(@thesis)
  end

  test 'title helper passes title if populated' do
    @thesis = Thesis.new(title: 'yolo title!')
    assert_equal 'yolo title!', title_helper(@thesis)
  end

  test 'filter_theses_by_term returns a filtered set of theses' do
    @theses = Thesis.all
    params[:graduation] = '2018-09-01'
    assert_not_equal 2, @theses.count
    assert_equal 2, filter_theses_by_term(@theses).count
  end

  test 'filter_theses_by_term does nothing when no graduation param is set' do
    @theses = Thesis.all
    assert_equal @theses.count, filter_theses_by_term(@theses).count
  end

  test 'filter_theses_by_term does nothing when graduation param is "all"' do
    @theses = Thesis.all
    params[:graduation] = 'all'
    assert_equal @theses.count, filter_theses_by_term(@theses).count
  end

  test 'filter_theses_by_publication_status returns a filtered set of theses' do
    status_count = Thesis.where(publication_status: 'Not ready for publication').count
    assert_not_equal status_count, Thesis.count

    params[:status] = 'Not ready for publication'
    assert_equal status_count, filter_theses_by_publication_status(Thesis.all).count
  end

  test 'filter_theses_by_publication_status does nothing when no status param is set' do
    assert_equal Thesis.all.count, filter_theses_by_publication_status(Thesis.all).count
  end

  test 'filter_theses_by_publication_status does nothing when status param is "all"' do
    params[:status] = 'all'
    assert_equal Thesis.all.count, filter_theses_by_publication_status(Thesis.all).count
  end

  test 'satisfies_advanced_degree? returns true for graduate degree types' do
    doctoral_thesis = Thesis.new(degrees: [degrees(:two)])
    master_thesis = Thesis.new(degrees: [degrees(:three)])
    engineer_thesis = Thesis.new(degrees: [degrees(:four)])
    assert_equal true, satisfies_advanced_degree?(doctoral_thesis)
    assert_equal true, satisfies_advanced_degree?(master_thesis)
    assert_equal true, satisfies_advanced_degree?(engineer_thesis)
  end

  test 'satisfies_advanced_degree? returns false for undergraduate degree types' do
    undergrad_thesis = Thesis.new(degrees: [degrees(:one)])
    assert_equal false, satisfies_advanced_degree?(undergrad_thesis)
  end

  test 'satisfies_advanced_degree? returns true if a thesis satisfies multiple advanced degree types' do
    grad_thesis = Thesis.new(degrees: [degrees(:two), degrees(:three)])
    assert_equal true, satisfies_advanced_degree?(grad_thesis)
  end

  test 'satisfies_advanced_degree? returns true if a thesis satisfies both undergraduate and graduate degree types' do
    hybrid_thesis = Thesis.new(degrees: [degrees(:one), degrees(:two)])
    assert_equal true, satisfies_advanced_degree?(hybrid_thesis)
  end

  test 'filter_theses_by_department returns a filtered set of theses' do
    theses = Thesis.includes(:departments)
    params[:department] = 'Department of Aeronautics and Astronautics'
    assert_not_equal theses.count, filter_theses_by_department(theses).count
  end

  test 'filter_theses_by_department does nothing when no department param is set' do
    theses = Thesis.includes(:departments)
    assert_equal theses.count, filter_theses_by_department(theses).count
  end

  test 'filter_theses_by_department does nothing when department param is "all"' do
    theses = Thesis.includes(:departments)
    params[:department] = 'all'
    assert_equal theses.count, filter_theses_by_department(theses).count
  end

  test 'filter_theses_by_degree_type returns a filtered set of theses' do
    theses = Thesis.includes(degrees: :degree_type)
    params[:degree_type] = 'Doctoral'
    assert_not_equal theses.count, filter_theses_by_degree_type(theses).count
  end

  test 'filter_theses_by_degree_type does nothing when no degree param is set' do
    theses = Thesis.includes(degrees: :degree_type)
    assert_equal theses.count, filter_theses_by_degree_type(theses).count
  end

  test 'filter_theses_by_degree_type does nothing when degree param is "all"' do
    theses = Thesis.includes(degrees: :degree_type)
    params[:degree] = 'all'
    assert_equal theses.count, filter_theses_by_degree_type(theses).count
  end

  test 'filter_theses_by_multiple_authors returns a filtered set of theses' do
    theses = Thesis.all
    params[:multi_author] = 'true'
    assert_not_equal theses.count, filter_theses_by_multiple_authors(theses).length
  end

  test 'filter_theses_by_multiple_authors does nothing when multi_author param is set to false' do
    theses = Thesis.all
    params[:multi_author] = 'false'
    assert_equal theses.count, filter_theses_by_multiple_authors(theses).length
  end

  test 'filter_theses_by_multiple_authors does nothing when no multi_author param is set' do
    theses = Thesis.all
    assert_equal theses.count, filter_theses_by_multiple_authors(theses).length
  end

  test 'filter_theses_by_published returns a filtered set of theses' do
    theses = Thesis.all
    params[:published] = 'true'
    assert_not_equal theses.count, filter_theses_by_published(theses).count
  end

  test 'filter_theses_by_published does nothing when published param is set to false' do
    theses = Thesis.all
    params[:published] = 'false'
    assert_equal theses.count, filter_theses_by_published(theses).count
  end

  test 'filter_theses_by_published does nothing when no published param is set' do
    theses = Thesis.all
    assert_equal theses.count, filter_theses_by_published(theses).count
  end

  test 'filter_proquest_status applies all expected filters' do
    # Confirm expected conditions.
    thesis = theses(:doctor)
    assert_equal '2018-06-01', thesis.grad_date.to_s
    assert_equal 'Not ready for publication', thesis.publication_status
    assert_equal 'conflict', evaluate_proquest_status(thesis)
    assert_equal departments(:one), thesis.departments.first
    assert_equal degrees(:two), thesis.degrees.first
    assert_equal 2, thesis.authors.count

    # Set params to correspond with expected conditions.
    params[:graduation] = '2018-06-01'
    params[:published] = 'false'
    params[:department] = departments(:one).name_dw
    params[:degree] = degrees(:two).name_dw
    params[:multi_author] = 'true'

    # Ensure that any filters were applied.
    theses = Thesis.includes(:departments).includes(degrees: :degree_type)
    assert_not_equal theses.count, filter_proquest_status(theses).length

    # Ensure that thesis meeting all conditions is in the filtered array.
    assert filter_proquest_status(theses).include? thesis
  end

  test 'evaluate_proquest_status identifies opt-in conflicts' do
    conflict_thesis = theses(:two)
    assert conflict_thesis.authors.count > 1
    assert_not_equal conflict_thesis.authors.first.proquest_allowed, conflict_thesis.authors.second.proquest_allowed
    assert_equal 'conflict', evaluate_proquest_status(conflict_thesis)
  end

  test 'evaluate_proquest_status returns opt-in status if no conflict is present' do
    harmonious_thesis = theses(:with_hold)
    assert_equal 2, harmonious_thesis.authors.count
    assert_equal false, harmonious_thesis.authors.first.proquest_allowed
    assert_equal false, harmonious_thesis.authors.second.proquest_allowed
    assert_equal false, evaluate_proquest_status(harmonious_thesis)

    single_author_thesis = theses(:one)
    assert_equal 1, single_author_thesis.authors.count
    assert_equal true, single_author_thesis.authors.first.proquest_allowed
    assert_equal true, evaluate_proquest_status(single_author_thesis)
  end

  test 'render_proquest_status shows expected status' do
    true_thesis = theses(:one)
    false_thesis = theses(:with_hold)
    nil_thesis = theses(:coauthor)
    conflict_thesis = theses(:two)

    # Confirm proquest_allowed values.
    assert_equal true, evaluate_proquest_status(true_thesis)
    assert_equal false, evaluate_proquest_status(false_thesis)
    assert_nil evaluate_proquest_status(nil_thesis)
    assert_equal 'conflict', evaluate_proquest_status(conflict_thesis)

    # Confirm friendly versions.
    assert_equal 'Yes', render_proquest_status(true_thesis)
    assert_equal 'No', render_proquest_status(false_thesis)
    assert_equal 'No opt-in status selected', render_proquest_status(nil_thesis)
    assert_equal 'Opt-in status not reconciled', render_proquest_status(conflict_thesis)
  end

  test 'proquest_status_counts increments as expected' do
    true_thesis = theses(:one)
    false_thesis = theses(:with_hold)
    nil_thesis = theses(:coauthor)
    conflict_thesis = theses(:two)

    assert_equal({ opted_in: 1, opted_out: 0, no_decision: 0, conflict: 0 }, proquest_status_counts([true_thesis]))
    assert_equal({ opted_in: 0, opted_out: 1, no_decision: 0, conflict: 0 }, proquest_status_counts([false_thesis]))
    assert_equal({ opted_in: 0, opted_out: 0, no_decision: 1, conflict: 0 }, proquest_status_counts([nil_thesis]))
    assert_equal({ opted_in: 0, opted_out: 0, no_decision: 0, conflict: 1 }, proquest_status_counts([conflict_thesis]))
    assert_equal({ opted_in: 1, opted_out: 1, no_decision: 1, conflict: 1 },
                 proquest_status_counts([true_thesis, false_thesis, nil_thesis, conflict_thesis]))
  end
end
