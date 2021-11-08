require 'test_helper'

class ReportControllerTest < ActionDispatch::IntegrationTest
  def attach_files(tr, th)
    # Ideally our fixtures would have already-attached files, but they do not
    # yet. So we attach two files to a transfer and thesis record, to prepare
    # for tests with an accurate set of file attachments.
    f1 = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    f2 = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    tr.files.attach(io: File.open(f1), filename: 'a_pdf.pdf')
    tr.files.attach(io: File.open(f2), filename: 'a_pdf.pdf')
    tr.save
    tr.reload
    th.files.attach(tr.files.first.blob)
    th.files.attach(tr.files.second.blob)
    th.save
    th.reload
  end

  def attach_proquest_form(tr, th)
    f = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    tr.files.attach(io: File.open(f), filename: 'a_pdf.pdf')
    tr.save
    tr.reload
    th.files.attach(tr.files.first.blob)
    th.files.first.purpose = 'proquest_form'
    th.save
    th.reload
  end

  # ~~~~~~~~~~~~~~~~~~~~ Report dashboard ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'summary report exists' do
    sign_in users(:admin)
    get report_index_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by summary report' do
    # Note that nobody is signed in.
    get report_index_path
    assert_response :redirect
  end

  test 'basic users cannot see summary report' do
    sign_in users(:basic)
    get report_index_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see summary report' do
    sign_in users(:transfer_submitter)
    get report_index_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see summary report' do
    sign_in users(:processor)
    get report_index_path
    assert_response :success
  end

  test 'thesis_admins can see summary report' do
    sign_in users(:thesis_admin)
    get report_index_path
    assert_response :success
  end

  test 'admins can see summary report' do
    sign_in users(:admin)
    get report_index_path
    assert_response :success
  end

  # ~~~~ Dashboard features

  test 'summary report has links to term-specific pages for all terms' do
    sign_in users(:processor)
    get report_index_path
    assert_select 'table:first-of-type thead a', count: Thesis.pluck(:grad_date).uniq.count
  end

  # ~~~~~~~~~~~~~~~~~~~~ Report empty theses ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'empty theses report exists' do
    sign_in users(:admin)
    get report_empty_theses_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by empty theses report' do
    # Note that nobody is signed in.
    get report_empty_theses_path
    assert_response :redirect
  end

  test 'basic users cannot see empty theses report' do
    sign_in users(:basic)
    get report_empty_theses_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see empty theses report' do
    sign_in users(:transfer_submitter)
    get report_empty_theses_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see empty theses report' do
    sign_in users(:processor)
    get report_empty_theses_path
    assert_response :success
  end

  test 'thesis_admins can see empty theses report' do
    sign_in users(:thesis_admin)
    get report_empty_theses_path
    assert_response :success
  end

  test 'admins can see empty theses report' do
    sign_in users(:admin)
    get report_empty_theses_path
    assert_response :success
  end

  # ~~~~ Empty thesis features

  test 'empty theses report shows a card' do
    sign_in users(:processor)
    get report_empty_theses_path
    assert_select '.card-empty-theses span', text: '24 have no attached files', count: 1
  end

  test 'empty theses report has links to processing pages' do
    sign_in users(:processor)
    get report_empty_theses_path
    assert_select 'table tbody a', count: Thesis.all.without_files.count
  end

  test 'empty theses report allows filtering by term' do
    sign_in users(:processor)
    get report_empty_theses_path
    assert_select '.card-empty-theses span', text: '24 have no attached files', count: 1
    get report_empty_theses_path, params: { graduation: '2018-09-01' }
    assert_select '.card-empty-theses span', text: '2 have no attached files', count: 1
  end

  # ~~~~~~~~~~~~~~~~~~~~ Report term detail ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'term report exists' do
    sign_in users(:admin)
    get report_term_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by term report' do
    # Note that nobody is signed in.
    get report_term_path
    assert_response :redirect
  end

  test 'basic users cannot see term report' do
    sign_in users(:basic)
    get report_term_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see term report' do
    sign_in users(:transfer_submitter)
    get report_term_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see term report' do
    sign_in users(:processor)
    get report_term_path
    assert_response :success
  end

  test 'thesis_admins can see term report' do
    sign_in users(:thesis_admin)
    get report_term_path
    assert_response :success
  end

  test 'admins can see term report' do
    sign_in users(:admin)
    get report_term_path
    assert_response :success
  end

  # ~~~~ Term features

  test 'term report shows a few fields' do
    sign_in users(:processor)
    get report_term_path
    assert_select '.card-overall .message', text: '24 thesis records', count: 1
    assert_select '.card-files .message', text: '0 have files attached', count: 1
    assert_select '.card-issues span', text: '1 flagged with issues', count: 1
    assert_select '.card-multiple-authors span', text: '2 have multiple authors', count: 1
    assert_select '.card-multiple-degrees span', text: '1 has multiple degrees', count: 1
    assert_select '.card-multiple-departments span', text: '1 has multiple departments', count: 1
    assert_response :success
  end

  test 'term report allows filtering' do
    sign_in users(:processor)
    get report_term_path
    assert_select '.card-overall .message', text: '24 thesis records', count: 1
    get report_term_path, params: { graduation: '2018-09-01' }
    assert_select '.card-overall .message', text: '2 thesis records', count: 1
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~~~~~~ Files without purpose report ~~~~~~~~~~~~~~~~~~~~~~~~
  test 'files report exists' do
    sign_in users(:admin)
    get report_files_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by files report' do
    # Note that nobody is signed in.
    get report_files_path
    assert_response :redirect
  end

  test 'basic users cannot see files report' do
    sign_in users(:basic)
    get report_files_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see files report' do
    sign_in users(:transfer_submitter)
    get report_files_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see files report' do
    sign_in users(:processor)
    get report_files_path
    assert_response :success
  end

  test 'thesis_admins can see files report' do
    sign_in users(:thesis_admin)
    get report_files_path
    assert_response :success
  end

  test 'admins can see files report' do
    sign_in users(:admin)
    get report_files_path
    assert_response :success
  end

  # ~~~~ Files without purpose features

  test 'default files report is empty' do
    sign_in users(:processor)
    get report_files_path
    assert_select 'table tbody td', text: 'There are no files without an assigned purpose within the selected term.', count: 1
  end

  test 'files have no default purpose, and appear on the files report' do
    sign_in users(:processor)
    xfer = transfers(:valid)
    thesis = theses(:one)
    attach_files(xfer, thesis)
    get report_files_path
    assert_select 'table tbody td', text: 'a_pdf.pdf', count: 2
  end

  test 'files report can be filtered by term' do
    sign_in users(:processor)
    xfer = transfers(:valid)
    thesis = theses(:one)
    attach_files(xfer, thesis)
    get report_files_path
    assert_select 'table tbody td', text: 'a_pdf.pdf', count: 2
    get report_files_path, params: { graduation: '2018-09-01' }
    assert_select 'table tbody td', text: 'There are no files without an assigned purpose within the selected term.', count: 1
  end

  test 'files disappear from files report when a purpose is set' do
    sign_in users(:processor)
    xfer = transfers(:valid)
    thesis = theses(:one)
    attach_files(xfer, thesis)
    get report_files_path
    assert_select 'table tbody td', text: 'a_pdf.pdf', count: 2
    file = thesis.files.first
    file.purpose = 0
    file.save
    get report_files_path
    assert_select 'table tbody td', text: 'a_pdf.pdf', count: 1
  end

  # ~~~~~~~~~~~~~~~~~~~~ ProQuest forms report ~~~~~~~~~~~~~~~~~~~~~~~~
  test 'proquest files report exists' do
    sign_in users(:admin)
    get report_proquest_files_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by proquest files report' do
    # Note that nobody is signed in.
    get report_proquest_files_path
    assert_response :redirect
  end

  test 'basic users cannot see proquest files report' do
    sign_in users(:basic)
    get report_proquest_files_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see proquest files report' do
    sign_in users(:transfer_submitter)
    get report_proquest_files_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see proquest files report' do
    sign_in users(:processor)
    get report_proquest_files_path
    assert_response :success
  end

  test 'thesis_admins can see proquest files report' do
    sign_in users(:thesis_admin)
    get report_proquest_files_path
    assert_response :success
  end

  test 'admins can see proquest files report' do
    sign_in users(:admin)
    get report_proquest_files_path
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~~~~~~ ProQuest forms features ~~~~~~~~~~~~~~~~~~~~~~~~
  test 'default proquest files report is empty' do
    sign_in users(:processor)
    get report_proquest_files_path
    assert_select 'table tbody td', text: 'There are no ProQuest forms within the selected term.', count: 1
  end

  test 'files with proquest_form purpose appear on proquest files report' do
    sign_in users(:processor)
    xfer = transfers(:valid)
    thesis = theses(:one)
    attach_proquest_form(xfer, thesis)
    get report_proquest_files_path
    assert_select 'table tbody td', text: 'a_pdf.pdf', count: 1
  end

  test 'files without proquest_form purpose do not appear on proquest files report' do
    sign_in users(:processor)
    xfer = transfers(:valid)
    thesis = theses(:one)
    attach_files(xfer, thesis)
    get report_proquest_files_path
    assert_select 'table tbody td', text: 'a_pdf.pdf', count: 0
  end

  test 'proquest files report can be filtered by term' do
    sign_in users(:processor)
    xfer = transfers(:valid)
    thesis = theses(:one)
    attach_proquest_form(xfer, thesis)
    get report_proquest_files_path
    assert_select 'table tbody td', text: 'a_pdf.pdf', count: 1
    get report_proquest_files_path, params: { graduation: '2018-09-01' }
    assert_select 'table tbody td', text: 'There are no ProQuest forms within the selected term.', count: 1
  end
end
