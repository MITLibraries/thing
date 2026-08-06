require 'test_helper'

class CatalogBatchTest < ActiveSupport::TestCase
  test 'builds a valid JSON file' do
    theses = [theses(:published)]
    batch = CatalogBatch.new(theses, 'test.json')
    catalog_file = batch.build

    json_content = File.read(catalog_file.path)
    json_data = JSON.parse(json_content)

    assert_not_nil(json_data)
    catalog_file.close
  end

  test 'wraps theses in a wrapper object with theses key' do
    theses = [theses(:published)]
    batch = CatalogBatch.new(theses, 'test.json')
    catalog_file = batch.build

    json_content = File.read(catalog_file.path)
    json_data = JSON.parse(json_content)

    assert(json_data.key?('theses'))
    assert(json_data['theses'].is_a?(Array))
    catalog_file.close
  end

  test 'includes all theses in the batch' do
    theses = [theses(:published), theses(:one)]
    batch = CatalogBatch.new(theses, 'test.json')
    catalog_file = batch.build

    json_content = File.read(catalog_file.path)
    json_data = JSON.parse(json_content)

    assert_equal(2, json_data['theses'].count)
    catalog_file.close
  end

  test 'includes all required fields' do
    theses = [theses(:published)]
    batch = CatalogBatch.new(theses, 'test.json')
    catalog_file = batch.build

    json_content = File.read(catalog_file.path)
    json_data = JSON.parse(json_content)

    thesis_data = json_data['theses'].first

    assert(thesis_data.key?('abstract'))
    assert(thesis_data.key?('advisors'))
    assert(thesis_data.key?('authors'))
    assert(thesis_data.key?('degrees'))
    assert(thesis_data.key?('departments'))
    assert(thesis_data.key?('dspace_url'))
    assert(thesis_data.key?('graduation_year'))
    assert(thesis_data.key?('title'))

    catalog_file.close
  end

  test 'empty theses array produces valid JSON' do
    batch = CatalogBatch.new([], 'test.json')
    catalog_file = batch.build

    json_content = File.read(catalog_file.path)
    json_data = JSON.parse(json_content)

    assert_equal(0, json_data['theses'].count)
    catalog_file.close
  end
end
