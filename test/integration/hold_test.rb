require 'test_helper'

class HoldIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
    @hold_params = {
      thesis_id: theses(:two).id,
      date_requested: '2021-03-15',
      date_start: '2021-03-15',
      date_end: '2021-03-15',
      hold_source_id: hold_sources(:tlo).id,
      case_number: '',
      status: 'active',
      processing_notes: ''
    }
  end

  def teardown
    auth_teardown
  end

  test 'returns the kerb of the user who modified the record version' do
    user = users(:thesis_admin)
    mock_auth user
    orig_count = Hold.count
    post admin_holds_path, params: { hold: @hold_params }
    hold = Hold.last
    assert_equal orig_count + 1, Hold.count
    assert_equal 1, hold.versions.length

    get hold_history_path(hold)
    assert_select 'li', 'Modified by: thesis_admin'
    assert_select "a[href='/admin/users/#{user.id}/edit']", 'thesis_admin'
  end

  test 'returns useful text if user who modified no longer exists' do
    user = User.new(uid: 'expendable@mit.edu', email: 'expendable@mit.edu',
                    kerberos_id: 'expendable', admin: true)
    user.save
    mock_auth user
    orig_hold_count = Hold.count
    post admin_holds_path, params: { hold: @hold_params }
    hold = Hold.last
    assert_equal orig_hold_count + 1, Hold.count
    assert_equal 1, hold.versions.length

    orig_user_count = User.count
    user.destroy
    assert_equal orig_user_count - 1, User.count

    mock_auth users(:thesis_admin)
    get hold_history_path(hold)
    assert_select 'li', "Modified by: ID #{user.id} is not an active user."
  end

  test 'nil fields are converted to n/a' do
    mock_auth users(:thesis_admin)
    orig_hold_count = Hold.count
    post admin_holds_path, params: { hold: @hold_params }
    hold = Hold.last
    assert_equal orig_hold_count + 1, Hold.count
    assert_equal 1, hold.versions.length

    get hold_history_path(hold)
    assert_equal true, hold.versions.first.changeset { |_k, v| v[0].nil? }.any?
    assert_select 'td', 'n/a'
  end

  test 'thesis_id field is rendered as a link to the thesis' do
    mock_auth users(:thesis_admin)
    orig_hold_count = Hold.count
    post admin_holds_path, params: { hold: @hold_params }
    hold = Hold.last
    assert_equal orig_hold_count + 1, Hold.count
    assert_equal 1, hold.versions.length

    get hold_history_path(hold)
    assert_select "a[href='/admin/theses/#{hold.thesis_id}']", hold.thesis.title
  end

  test 'hold_source_id field is rendered as a link to the hold source' do
    mock_auth users(:thesis_admin)
    orig_hold_count = Hold.count
    post admin_holds_path, params: { hold: @hold_params }
    hold = Hold.last
    assert_equal orig_hold_count + 1, Hold.count
    assert_equal 1, hold.versions.length

    get hold_history_path(hold)
    assert_select "a[href='/admin/hold_sources/#{hold.hold_source_id}']", hold.hold_source.source
  end

  # Due to a bug in PaperTrail, data we migrated from YAML to JSON incorrectly stored enums as integers instead of
  # their mapped values. This caused the hold_history view to render integers for statuses. This test confirms a
  # patch for how this data is rendered, and may be removed if we decide to remediate this problem with a data migration.
  test 'status field renders translated enum, not integer' do
    mock_auth users(:thesis_admin)
    post admin_holds_path, params: { hold: @hold_params }
    hold = Hold.last
    version = hold.versions.last
    version.object_changes['status'] = [nil, 0]
    version.save

    get hold_history_path(hold)
    assert_select 'td', text: '0', count: 0
    assert_select 'td', text: 'active', count: 1

    version.object_changes['status'] = [nil, 1]
    version.save
    get hold_history_path(hold)
    assert_select 'td', text: '1', count: 0
    assert_select 'td', text: 'expired', count: 1 

    version.object_changes['status'] = [nil, 2]
    version.save
    get hold_history_path(hold)
    assert_select 'td', text: '2', count: 0
    assert_select 'td', text: 'released', count: 1 
  end
end
