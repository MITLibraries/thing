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
end
