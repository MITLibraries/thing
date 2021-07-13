require 'test_helper'

class TransferIntegrationTest < ActionDispatch::IntegrationTest
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

  test 'posting valid transfer succeeds' do
    mock_auth(users(:transfer_submitter))
    orig_count = Transfer.count
    post transfer_index_path, params: { transfer: @transfer_params }
    assert_equal orig_count + 1, Transfer.count
    assert_equal @transfer_params[:department_id], Transfer.last.department.id
    assert_equal @transfer_params[:graduation_month], Transfer.last.graduation_month
    assert_equal @transfer_params[:graduation_year], Transfer.last.graduation_year
  end

  test 'including a note still success' do
    mock_auth(users(:transfer_submitter))
    orig_count = Transfer.count
    @transfer_params[:note] = "Let me pass you a note"
    post transfer_index_path, params: { transfer: @transfer_params }
    assert_equal orig_count + 1, Transfer.count
  end

  test 'missing department fails' do
    mock_auth(users(:transfer_submitter))
    @transfer_params.except!(:department_id)
    post transfer_index_path, params: { transfer: @transfer_params }
    assert_select 'span.error', text: Transfer::VALIDATION_MSGS[:generic]
  end

  test 'missing month fails' do
    mock_auth(users(:transfer_submitter))
    @transfer_params.except!(:graduation_month)
    post transfer_index_path, params: { transfer: @transfer_params }
    assert_select 'span.error', text: Transfer::VALIDATION_MSGS[:graduation_month]
  end

  test 'missing year fails' do
    mock_auth(users(:transfer_submitter))
    @transfer_params.except!(:graduation_year)
    post transfer_index_path, params: { transfer: @transfer_params }
    assert_select 'span.error', text: Transfer::VALIDATION_MSGS[:graduation_year]
  end

  test 'missing files fails (with generic message)' do
    skip("Something here is not working correctly")
    mock_auth(users(:transfer_submitter))
    @transfer_params.except!(:files)
    post transfer_index_path, params: { transfer: @transfer_params }
    assert_select 'span.error', text: Transfer::VALIDATION_MSGS[:generic]
  end

  test 'a confirmation email is sent when a transfer is created' do
    mock_auth(users(:transfer_submitter))
    ClimateControl.modify DISABLE_ALL_EMAIL: 'false' do
      assert_emails 1 do
        post transfer_index_path, params: {
          transfer: @transfer_params
        }
      end
    end
  end
end
