require "test_helper"

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
end
