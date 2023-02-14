require 'test_helper'
require 'csv'

class ProquestExportBatchTest < ActiveSupport::TestCase
  test 'builds JSON with expected values' do
    theses = [theses(:proquest_export_partial), theses(:proquest_export_full)]
    assert_equal 'Partial harvest', theses(:proquest_export_partial).proquest_exported
    assert_equal 'Full harvest', theses(:proquest_export_full).proquest_exported

    json_hash = JSON.parse(ProquestExportBatch.new.build_json(theses))
    assert_equal theses(:proquest_export_partial).dspace_handle, json_hash['records'].first['dspace_handle']
    assert_equal theses(:proquest_export_full).dspace_handle, json_hash['records'].second['dspace_handle']
    assert_equal false, json_hash['records'].first['full_harvest']
    assert json_hash['records'].second['full_harvest']
  end

  test 'builds CSV with expected headers' do
    csv = CSV.parse(ProquestExportBatch.new.build_budget_report([theses(:ready_for_partial_export)]))
    assert_equal ['author name(s)', 'department(s)', 'degree type(s)', 'degree period', 'handle', 'export date'], csv[0]
  end

  test 'CSV has expected values in the correct positions (single values)' do
    thesis = theses(:ready_for_partial_export)
    csv = CSV.parse(ProquestExportBatch.new.build_budget_report([thesis]))
    assert_equal thesis.users.first.name, csv[1][0]
    assert_equal thesis.departments.first.name_dw, csv[1][1]
    assert_equal thesis.degrees.first.degree_type.name, csv[1][2]
    assert_equal thesis.grad_date.to_s, csv[1][3]
    assert_equal thesis.dspace_handle, csv[1][4]
    assert_equal Date.today.strftime("%m-%d-%Y"), csv[1][5]
  end

  test 'CSV has expected values in the correct positions (multiple values)' do
    thesis = theses(:budget_report_multiple)
    csv = CSV.parse(ProquestExportBatch.new.build_budget_report([thesis]))
    assert_equal thesis.users.map { |user| user.name }.join('; '), csv[1][0]
    assert_equal thesis.departments.map { |dept| dept.name_dw }.join('; '), csv[1][1]
    assert_equal thesis.degrees.map { |degree| degree.degree_type.name }.join('; '), csv[1][2]
    assert_equal thesis.grad_date.to_s, csv[1][3]
    assert_equal thesis.dspace_handle, csv[1][4]
    assert_equal Date.today.strftime("%m-%d-%Y"), csv[1][5]
  end
end
