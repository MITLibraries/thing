require 'test_helper'

class JsonExporterTest < ActiveSupport::TestCase
  test 'includes correctly formatted title' do
    thesis = theses(:published)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    assert_equal thesis.title&.squish, json_hash[:title]
  end

  test 'includes abstract' do
    thesis = theses(:published)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    assert_equal thesis.abstract, json_hash[:abstract]
  end

  test 'includes grad year' do
    thesis = theses(:published)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    assert_equal thesis.graduation_year, json_hash[:graduation_year]
  end

  test 'includes correctly formatted dspace_url' do
    thesis = theses(:published)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    expected_url = "https://dspace.mit.edu/handle/#{thesis.dspace_handle}"
    assert_equal expected_url, json_hash[:dspace_url]
  end

  test 'includes authors with nested structure' do
    thesis = theses(:published)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    assert json_hash[:authors].is_a?(Array)
    assert json_hash[:authors].first.is_a?(Hash)
    assert json_hash[:authors].first[:name]
  end

  test 'includes degrees with nested structure' do
    thesis = theses(:published)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    assert json_hash[:degrees].is_a?(Array)
    assert json_hash[:degrees].first.is_a?(Hash)
    assert json_hash[:degrees].first[:abbreviation]
  end

  test 'includes advisors with nested structure' do
    thesis = theses(:published)
    thesis.advisors << advisors(:first)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    assert json_hash[:advisors].is_a?(Array)
    assert json_hash[:advisors].first.is_a?(Hash)
    assert json_hash[:advisors].first[:name]
  end

  test 'includes departments with nested structure' do
    thesis = theses(:published)
    exporter = JsonExporter.new(thesis)
    json_hash = exporter.to_hash
    assert json_hash[:departments].is_a?(Array)
    assert json_hash[:departments].first.is_a?(Hash)
    assert json_hash[:departments].first[:name]
  end
end
