require 'test_helper'

class MarcBatchTest < ActiveSupport::TestCase
  test 'builds zip file' do
    zip_file = MarcBatch.new([theses(:one)], 'marc.xml', 'marc.zip').build
    assert File.exists?(zip_file)
  end

  test 'zip file contains only marcxml file' do
    zip_file = MarcBatch.new([theses(:one)], 'marc.xml', 'marc.zip').build
    Zip::File.open(zip_file) do |file|
      assert_nil file.find_entry("not_marc.xml")
      assert_equal 'marc.xml', file.find_entry('marc.xml').to_s
    end
    zip_file.close
  end

  test 'marc file is explicitly closed after zip file is built' do
    batch = MarcBatch.new([theses(:one)], 'marc.xml', 'marc.zip')
    zip_file = batch.build
    marc_tempfile_path = batch.instance_variable_get(:@marc_filename)    
    assert_not File.exists?(marc_tempfile_path)
  end
end
