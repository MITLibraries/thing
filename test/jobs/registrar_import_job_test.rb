require 'test_helper'

class RegistrarImportJobTest < ActiveJob::TestCase
  test "process_csv opens and reads CSV rows" do
    filepath = 'test/fixtures/files/registrar_data_small_sample.csv'
    results = RegistrarImportJob.perform_now(filepath)
    assert_equal 2, results[:read]
  end

  test "skip CSV rows missing Kerb" do
    filepath = 'test/fixtures/files/registrar_data_small_sample.csv'
    results = RegistrarImportJob.perform_now(filepath)
    assert_equal 1, results[:processed]
  end

  test "job runs and returns expected results" do
    filepath = 'test/fixtures/files/registrar_data_full_anonymized.csv'
    results = RegistrarImportJob.perform_now(filepath)
    assert_equal 434, results[:read]
    assert_equal 433, results[:processed]
    assert_equal 1, results[:errors]
  end

end
