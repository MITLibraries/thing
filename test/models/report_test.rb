require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  test 'overall card uses search term if present' do
    r = Report.new
    result = r.card_overall Thesis.all, 'all'
    assert_equal result['link']['url'], '/admin/theses'
    result = r.card_overall Thesis.all, Thesis.first.grad_date
    assert_match Thesis.first.grad_date.to_s, result['link']['url']
  end
end
