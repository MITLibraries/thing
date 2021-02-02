require 'test_helper'

class FilesIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
    @transfer_params = {
      department_id: departments(:one).id,
      graduation_year: (Time.current.year + 1).to_s,
      graduation_month: 'September',
      files: fixture_file_upload('test/fixtures/files/a_pdf.pdf', 'application/pdf')
    }
  end

  def teardown
    auth_teardown
  end

  test 'files default purpose and description to nil' do
    mock_auth(users(:transfer_submitter))
    orig_count = Transfer.count
    post transfer_index_path, params: { transfer: @transfer_params }
    transfer = Transfer.last
    assert_nil transfer.files.first.purpose
    assert_nil transfer.files.first.description
  end

  test 'files can have a purpose' do
    mock_auth(users(:transfer_submitter))
    orig_count = Transfer.count
    post transfer_index_path, params: { transfer: @transfer_params }
    transfer = Transfer.last

    f1 = transfer.files.first
    f1.purpose = 0
    f1.save
    refute_nil transfer.files.first.purpose
    assert_equal transfer.files.first.purpose, "thesis_pdf"
  end

  test 'files can have a description' do
    mock_auth(users(:transfer_submitter))
    orig_count = Transfer.count
    post transfer_index_path, params: { transfer: @transfer_params }
    transfer = Transfer.last

    f1 = transfer.files.first
    f1.description = "Hallo!"
    f1.save
    refute_nil transfer.files.first.description
    assert_equal transfer.files.first.description, "Hallo!"
  end
end
