require 'test_helper'

class RegistrarImportJobTest < ActiveJob::TestCase
  test 'process_csv opens and reads CSV rows' do
    registrar = Registrar.last
    registrar.graduation_list.attach(io: File.open('test/fixtures/files/registrar_data_small_sample.csv'),
                                     filename: 'registrar_data_small_sample.csv')
    results = RegistrarImportJob.perform_now(registrar)
    assert_equal 2, results[:read]
  end

  test 'skip CSV rows missing Kerb' do
    registrar = Registrar.last
    registrar.graduation_list.attach(io: File.open('test/fixtures/files/registrar_data_small_sample.csv'),
                                     filename: 'registrar_data_small_sample.csv')
    results = RegistrarImportJob.perform_now(registrar)
    assert_equal 1, results[:processed]
  end

  test 'job runs and returns expected results' do
    skip 'Slow test skipped due to env settings' if ENV.fetch('SKIP_SLOW', false)
    registrar = Registrar.last
    registrar.graduation_list.attach(io: File.open('test/fixtures/files/registrar_data_full_anonymized.csv'),
                                     filename: 'registrar_data_full_anonymized.csv')
    results = RegistrarImportJob.perform_now(registrar)
    assert_equal 434, results[:read]
    assert_equal 433, results[:processed]
    assert_equal 430, results[:new_theses]
    assert_equal 3, results[:updated_theses]
    assert_equal 430, results[:new_users]
    assert_equal 42, results[:new_degrees].length
    assert_equal 30, results[:new_depts].length
    assert_equal 3, results[:new_degree_periods].length
    assert_equal 1, results[:errors].length
    assert_includes results[:errors][0], 'Row #418 missing a Kerberos ID'

    results = RegistrarImportJob.perform_now(registrar)
    assert_equal 434, results[:read]
    assert_equal 433, results[:processed]
    assert_equal 0, results[:new_theses]
    assert_equal 433, results[:updated_theses]
    assert_equal 0, results[:new_users]
    assert_equal 0, results[:new_degrees].length
    assert_equal 0, results[:new_depts].length
    assert_equal 0, results[:new_degree_periods].length
    assert_equal 1, results[:errors].length
    assert_includes results[:errors][0], 'Row #418 missing a Kerberos ID'
  end

  test 'whodunnit is set as expected' do
    registrar = Registrar.last
    registrar.graduation_list.attach(io: File.open('test/fixtures/files/registrar_data_small_sample.csv'),
                                     filename: 'registrar_data_small_sample.csv')
    user_count = User.count
    thesis_count = Thesis.count
    RegistrarImportJob.perform_now(registrar)

    # Confirm that we have a new thesis and user from the import job.
    assert_equal Thesis.count, thesis_count + 1
    assert_equal User.count, user_count + 1

    # Confirm we're looking at the newly generated thesis and user records.
    assert_equal 'finleyjessica@mit.edu', User.first.uid
    assert_equal 'finleyjessica@mit.edu', Thesis.last.users.first.uid

    # Finally, confirm that the newly generated thesis and user records have the right whodunnit.
    assert_equal 'registrar', User.first.versions.first.whodunnit
    assert_equal 'registrar', Thesis.last.versions.first.whodunnit
  end
end
