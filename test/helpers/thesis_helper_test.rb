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
end
