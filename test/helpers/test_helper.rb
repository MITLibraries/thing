require 'test_helper'

include ThesisHelper

class ThesisHelperTest < ActionView::TestCase
  test 'highlight class if no status' do
    params[:status] = nil

    assert_equal 'button-primary', highlight_class('active')
    assert_equal 'button-secondary', highlight_class('downloaded')
    assert_equal 'button-secondary', highlight_class('withdrawn')
    assert_equal 'button-secondary', highlight_class('any')
  end

  test 'highlight class when status is active' do
    params[:status] = 'active'

    assert_equal 'button-primary', highlight_class('active')
    assert_equal 'button-secondary', highlight_class('downloaded')
    assert_equal 'button-secondary', highlight_class('withdrawn')
    assert_equal 'button-secondary', highlight_class('any')
  end

  test 'highlight class when status is downloaded' do
    params[:status] = 'downloaded'

    assert_equal 'button-secondary', highlight_class('active')
    assert_equal 'button-primary', highlight_class('downloaded')
    assert_equal 'button-secondary', highlight_class('withdrawn')
    assert_equal 'button-secondary', highlight_class('any')
  end

  test 'highlight class when status is withdrawn' do
    params[:status] = 'withdrawn'

    assert_equal 'button-secondary', highlight_class('active')
    assert_equal 'button-secondary', highlight_class('downloaded')
    assert_equal 'button-primary', highlight_class('withdrawn')
    assert_equal 'button-secondary', highlight_class('any')
  end

  test 'highlight class when status is any' do
    params[:status] = 'any'

    assert_equal 'button-secondary', highlight_class('active')
    assert_equal 'button-secondary', highlight_class('downloaded')
    assert_equal 'button-secondary', highlight_class('withdrawn')
    assert_equal 'button-primary', highlight_class('any')
  end

  test 'highlight class when status is bogus' do
    params[:status] = 'bogus'

    assert_equal 'button-secondary', highlight_class('active')
    assert_equal 'button-secondary', highlight_class('downloaded')
    assert_equal 'button-secondary', highlight_class('withdrawn')
    assert_equal 'button-secondary', highlight_class('any')
  end
end
