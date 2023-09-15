require 'test_helper'

class AdminArchivematicaAccessionTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  test 'anonymous users cannot access archivematica accession dashboard' do
    get '/admin/archivematica_accessions'
    assert_response :redirect
  end

  test 'basic users cannot access archivematica accession dashboard' do
    mock_auth(users(:basic))
    get '/admin/archivematica_accessions'
    assert_response :redirect
  end

  test 'transfer submitters cannot access archivematica accession dashboard' do
    mock_auth(users(:transfer_submitter))
    get '/admin/archivematica_accessions'
    assert_response :redirect
  end

  test 'thesis processors can access archivematica accession dashboard' do
    mock_auth(users(:processor))
    get '/admin/archivematica_accessions'
    assert_response :success
  end

  test 'thesis admins can access archivematica accession dashboard' do
    mock_auth(users(:thesis_admin))
    get '/admin/archivematica_accessions'
    assert_response :success
  end

  test 'thesis processors can view archivematica accession details through dashboard' do
    mock_auth(users(:processor))
    get "/admin/archivematica_accessions/#{ArchivematicaAccession.first.id}"
    assert_response :success
  end

  test 'thesis processors can create an archivematica_accession' do
    mock_auth(users(:processor))
    orig_count = ArchivematicaAccession.count
    new_archivematica_accession = {
      accession_number: '2010_001',
      degree_period_id: degree_periods(:no_archivematica_accessions).id
    }
    post admin_archivematica_accessions_path, params: { archivematica_accession: new_archivematica_accession }
    assert_equal orig_count + 1, ArchivematicaAccession.count
  end

  test 'thesis processors can update an archivematica accession' do
    mock_auth(users(:processor))
    archivematica_accession = ArchivematicaAccession.first
    new_accession_number = '2014_001'
    assert_not_equal new_accession_number, archivematica_accession.accession_number

    patch admin_archivematica_accession_path(archivematica_accession),
          params: { archivematica_accession: { accession_number: new_accession_number } }
    archivematica_accession.reload
    assert_equal new_accession_number, archivematica_accession.accession_number
  end

  test 'thesis processors can destroy an archivematica accession' do
    mock_auth(users(:processor))
    archivematica_accession = ArchivematicaAccession.first
    archivematica_accession_id = archivematica_accession.id
    assert ArchivematicaAccession.exists?(archivematica_accession_id)

    delete admin_archivematica_accession_path(archivematica_accession)
    assert_not ArchivematicaAccession.exists?(archivematica_accession_id)
  end

  test 'thesis admins can view archivematica accession details through dashboard' do
    mock_auth(users(:thesis_admin))
    get "/admin/archivematica_accessions/#{ArchivematicaAccession.first.id}"
    assert_response :success
  end

  test 'thesis admins can create an archivematica accession' do
    mock_auth(users(:thesis_admin))
    orig_count = ArchivematicaAccession.count
    new_archivematica_accession = {
      accession_number: '2010_001',
      degree_period_id: degree_periods(:no_archivematica_accessions).id
    }
    post admin_archivematica_accessions_path, params: { archivematica_accession: new_archivematica_accession }
    assert_equal orig_count + 1, ArchivematicaAccession.count
  end

  test 'thesis admins can update an archivematica accession' do
    mock_auth(users(:thesis_admin))
    archivematica_accession = ArchivematicaAccession.first
    new_accession_number = '2014_001'
    assert_not_equal new_accession_number, archivematica_accession.accession_number

    patch admin_archivematica_accession_path(archivematica_accession),
          params: { archivematica_accession: { accession_number: new_accession_number } }
    archivematica_accession.reload
    assert_equal new_accession_number, archivematica_accession.accession_number
  end

  test 'thesis admins can destroy an archivematica accession' do
    mock_auth(users(:thesis_admin))
    archivematica_accession = ArchivematicaAccession.first
    archivematica_accession_id = archivematica_accession.id
    assert ArchivematicaAccession.exists?(archivematica_accession_id)

    delete admin_archivematica_accession_path(archivematica_accession)
    assert_not ArchivematicaAccession.exists?(archivematica_accession_id)
  end

  test 'new form can be prefilled with degree period' do
    mock_auth users(:thesis_admin)
    get new_admin_archivematica_accession_path, params: { degree_period_id: degree_periods(:june_2023).id }
    assert_select 'select#archivematica_accession_degree_period_id', count: 1
    assert_select 'option', text: 'June 2023', count: 1
  end

  test 'new form can be loaded with no prefilled degree period' do
    mock_auth users(:thesis_admin)
    get new_admin_archivematica_accession_path
    assert_select 'select#archivematica_accession_degree_period_id', count: 1
    assert_select 'option', text: '', count: 1
  end
end
