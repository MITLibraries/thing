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
end
