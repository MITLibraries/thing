require 'test_helper'

include ThesisHelper

class ThesisHelperTest < ActionView::TestCase
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ highlighting ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'highlight class if no status' do
    params[:status] = nil

    assert_equal 'button-primary', highlight_status('active')
    assert_equal 'button-secondary', highlight_status('downloaded')
    assert_equal 'button-secondary', highlight_status('withdrawn')
    assert_equal 'button-secondary', highlight_status('any')
  end

  test 'highlight class when status is active' do
    params[:status] = 'active'

    assert_equal 'button-primary', highlight_status('active')
    assert_equal 'button-secondary', highlight_status('downloaded')
    assert_equal 'button-secondary', highlight_status('withdrawn')
    assert_equal 'button-secondary', highlight_status('any')
  end

  test 'highlight class when status is downloaded' do
    params[:status] = 'downloaded'

    assert_equal 'button-secondary', highlight_status('active')
    assert_equal 'button-primary', highlight_status('downloaded')
    assert_equal 'button-secondary', highlight_status('withdrawn')
    assert_equal 'button-secondary', highlight_status('any')
  end

  test 'highlight class when status is withdrawn' do
    params[:status] = 'withdrawn'

    assert_equal 'button-secondary', highlight_status('active')
    assert_equal 'button-secondary', highlight_status('downloaded')
    assert_equal 'button-primary', highlight_status('withdrawn')
    assert_equal 'button-secondary', highlight_status('any')
  end

  test 'highlight class when status is any' do
    params[:status] = 'any'

    assert_equal 'button-secondary', highlight_status('active')
    assert_equal 'button-secondary', highlight_status('downloaded')
    assert_equal 'button-secondary', highlight_status('withdrawn')
    assert_equal 'button-primary', highlight_status('any')
  end

  test 'highlight class when status is bogus' do
    params[:status] = 'bogus'

    assert_equal 'button-secondary', highlight_status('active')
    assert_equal 'button-secondary', highlight_status('downloaded')
    assert_equal 'button-secondary', highlight_status('withdrawn')
    assert_equal 'button-secondary', highlight_status('any')
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ group_for_graph ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'status is active' do
    @theses = Thesis.all
    grouped_theses = group_for_graph('active')

    # Expects the following active theses in theses.yml:
    # one
    # two
    # active
    # with_note
    # with_hold
    # june_2018
    # september_2018
    # february_2019
    # june_2019
    # september_2019
    # multi_depts

    expected = { "Sep 2017"=>4, "Jun 2018"=>1, "Sep 2018"=>2,
                 "Feb 2019"=>2, "Jun 2019"=>1, "Sep 2019"=>1}
    assert_equal expected, grouped_theses
  end

  test 'status is downloaded' do
    @theses = Thesis.all
    grouped_theses = group_for_graph('downloaded')

    # Expects the following downloaded theses in theses.yml:
    # downloaded

    expected = { "Sep 2017"=>1 }
    assert_equal expected, grouped_theses
  end

  test 'status is withdrawn' do
    @theses = Thesis.all
    grouped_theses = group_for_graph('withdrawn')

    # Expects the following withdrawn theses in theses.yml:
    # withdrawn

    expected = { "Sep 2017"=>1 }
    assert_equal expected, grouped_theses
  end

  test 'status is any' do
    @theses = Thesis.all
    grouped_theses = group_for_graph('any')

    # Expects the theses as noted in the 3 tests above to exist.

    expected = { "Sep 2017"=>6, "Jun 2018"=>1, "Sep 2018"=>2,
                 "Feb 2019"=>2, "Jun 2019"=>1, "Sep 2019"=>1}
    assert_equal expected, grouped_theses
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ earliest_year ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'earliest year works as expected when no status' do
    params[:status] = nil

    assert_equal 2017, earliest_year
  end

  test 'earliest year works as expected with a status delimiter' do
    params[:status] = 'withdrawn'

    assert_equal 2017, earliest_year
  end

  test 'earliest year handles the empty set' do
    params[:status] = 'pink'

    assert_equal 2017, earliest_year
  end

  test 'earliest year handles an empty status param' do
    params[:status] = ''

    assert_equal 2017, earliest_year
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ earliest_year ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'latest year works as expected when no status' do
    params[:status] = nil

    assert_equal 2019, latest_year
  end

  test 'latest year works as expected with a status delimiter' do
    params[:status] = 'withdrawn'

    assert_equal 2017, latest_year
  end

  test 'latest year handles the empty set' do
    params[:status] = 'pink'

    assert_equal 2019, latest_year
  end

  test 'latest year handles an empty status param' do
    params[:status] = ''

    assert_equal 2019, latest_year
  end

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
