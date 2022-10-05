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
    params[:graduation] = "2018-09-01"
    assert_not_equal 2, @theses.count
    assert_equal 2, filter_theses_by_term(@theses).count
  end

  test 'filter_theses_by_term does nothing when no graduation param is set' do
    @theses = Thesis.all
    assert_equal @theses.count, filter_theses_by_term(@theses).count
  end

  test 'filter_theses_by_term does nothing when graduation param is "all"' do
    @theses = Thesis.all
    params[:graduation] = "all"
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
end
