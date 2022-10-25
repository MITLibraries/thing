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

  # This is needed because preexisting theses (i.e., fixtures) will have a whodunnit of nil, and we use whodunnit
  # to identify theses that were created/modified by students.
  def create_thesis_with_whodunnit(user)
    sign_in user
    title = 'Spacecraft avoidance: a short'
    post '/thesis',
         params: {
           thesis: {
             title: title,
             abstract: 'Frook.',
             department_ids: departments(:one).id.to_s,
             degree_ids: degrees(:one).id.to_s,
             graduation_year: (Time.current.year + 1).to_s,
             graduation_month: 'September',
             files: fixture_file_upload('a_pdf.pdf', 'application/pdf')
           }
         }
    sign_out user
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
    assert_redirected_to '/login'
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
    assert_redirected_to '/login'
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
    assert_select '.card-empty-theses span', text: '19 have no attached files', count: 1
  end

  test 'empty theses report has links to processing pages' do
    sign_in users(:processor)
    get report_empty_theses_path
    assert_select 'table tbody a', count: Thesis.all.without_files.count
  end

  test 'empty theses report allows filtering by term' do
    sign_in users(:processor)
    get report_empty_theses_path
    assert_select '.card-empty-theses span', text: '19 have no attached files', count: 1
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
    assert_redirected_to '/login'
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
    assert_select '.card-overall .message', text: '27 thesis records', count: 1
    assert_select '.card-files .message', text: '8 have files attached', count: 1
    assert_select '.card-issues span', text: '1 flagged with issues', count: 1
    assert_select '.card-students-contributing span', text: '0 have had metadata contributed by students', count: 1
    assert_select '.card-multiple-authors span', text: '4 have multiple authors', count: 1
    assert_select '.card-multiple-degrees span', text: '1 has multiple degrees', count: 1
    assert_select '.card-multiple-departments span', text: '1 has multiple departments', count: 1
    assert_response :success
  end

  test 'term report allows filtering' do
    sign_in users(:processor)
    get report_term_path
    assert_select '.card-overall .message', text: '27 thesis records', count: 1
    get report_term_path, params: { graduation: '2018-09-01' }
    assert_select '.card-overall .message', text: '2 thesis records', count: 1
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~~~~~~ Expired holds report ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'expired holds report exists' do
    sign_in users(:admin)
    get report_expired_holds_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by expired holds report' do
    # Note that nobody is signed in.
    get report_expired_holds_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see expired holds report' do
    sign_in users(:basic)
    get report_expired_holds_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see expired holds report' do
    sign_in users(:transfer_submitter)
    get report_expired_holds_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see expired holds report' do
    sign_in users(:processor)
    get report_expired_holds_path
    assert_response :success
  end

  test 'thesis_admins can see expired holds report' do
    sign_in users(:thesis_admin)
    get report_expired_holds_path
    assert_response :success
  end

  test 'admins can see expired holds report' do
    sign_in users(:admin)
    get report_expired_holds_path
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
    assert_redirected_to '/login'
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
    assert_select 'table tbody td', text: 'There are no files without an assigned purpose within the selected term.',
                                    count: 1
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
    assert_select 'table tbody td', text: 'There are no files without an assigned purpose within the selected term.',
                                    count: 1
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
    assert_redirected_to '/login'
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

  # ~~~~~~~~~~~~~~~~~ Student-submitted theses report ~~~~~~~~~~~~~~~~~~~~~~
  test 'student-submitted theses report exists' do
    sign_in users(:admin)
    get report_student_submitted_theses_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by student-submitted theses report' do
    # Note that nobody is signed in.
    get report_student_submitted_theses_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see student-submitted theses report' do
    sign_in users(:basic)
    get report_student_submitted_theses_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see student-submitted theses report' do
    sign_in users(:transfer_submitter)
    get report_student_submitted_theses_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see student-submitted theses report' do
    sign_in users(:processor)
    get report_student_submitted_theses_path
    assert_response :success
  end

  test 'thesis_admins can see student-submitted theses report' do
    sign_in users(:thesis_admin)
    get report_student_submitted_theses_path
    assert_response :success
  end

  test 'admins can see student-submitted theses report' do
    sign_in users(:admin)
    get report_student_submitted_theses_path
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~~~ Student-submitted theses features ~~~~~~~~~~~~~~~~~~~~
  test 'default student-submitted theses report is empty' do
    sign_in users(:processor)
    get report_student_submitted_theses_path
    assert_select 'table tbody td', text: 'There are no student-submitted theses for the given term.', count: 1
  end

  test 'theses not created by students do not appear on student-submitted theses report' do
    create_thesis_with_whodunnit(users(:processor))
    sign_in users(:processor)
    get report_student_submitted_theses_path
    assert_select 'table tbody td', text: 'processor', count: 0
  end

  test 'theses created by students appear on student-submitted theses report' do
    create_thesis_with_whodunnit(users(:basic))
    sign_in users(:processor)
    get report_student_submitted_theses_path
    assert_select 'table tbody td', text: 'basic', count: 1
  end

  test 'theses without whodunnit do not appear on student-submitted theses report' do
    sign_in users(:processor)

    # Make sure theses exist, but none have whodunnit. (Whodunnit will be nil for fixtures.)
    assert Thesis.count.positive?

    get report_student_submitted_theses_path
    assert_select 'table tbody td', text: 'There are no student-submitted theses for the given term.', count: 1
  end

  test 'theses generated by registrar data import do not appear on student-submitted thesis report' do
    registrar = Registrar.last
    registrar.graduation_list.attach(io: File.open('test/fixtures/files/registrar_data_small_sample.csv'),
                                     filename: 'registrar_data_small_sample.csv')
    RegistrarImportJob.perform_now(registrar)
    assert_equal 'registrar', Thesis.last.versions.first.whodunnit

    sign_in users(:processor)
    get report_student_submitted_theses_path
    assert_select 'table tbody td', text: 'There are no student-submitted theses for the given term.', count: 1
  end

  test 'student-submitted theses report can be filtered by term' do
    create_thesis_with_whodunnit(users(:basic))
    sign_in users(:processor)
    get report_student_submitted_theses_path
    assert_select 'table tbody td', text: 'basic', count: 1

    get report_student_submitted_theses_path, params: { graduation: '2018-09-01' }
    assert_select 'table tbody td', text: 'There are no student-submitted theses for the given term.', count: 1
  end

  # ~~~~~~~~~~~~~~~ Holds by source report ~~~~~~~~~~~~~~~~
  test 'anonymous users cannot see holds by source report' do
    # Note that nobody is signed in.
    get report_holds_by_source_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see holds by source report' do
    sign_in users(:basic)
    get report_holds_by_source_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see holds by source report' do
    sign_in users(:transfer_submitter)
    get report_holds_by_source_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see holds by source report' do
    sign_in users(:processor)
    get report_holds_by_source_path
    assert_response :success
  end

  test 'thesis_admins can see holds by source report' do
    sign_in users(:thesis_admin)
    get report_holds_by_source_path
    assert_response :success
  end

  test 'admins can see holds by source report' do
    sign_in users(:admin)
    get report_holds_by_source_path
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~ Holds by source report features ~~~~~~~~~~~~~~~~
  test 'holds by source report shows holds with any source by default' do
    hold_count = Hold.all.count

    sign_in users(:processor)
    get report_holds_by_source_path
    assert_select 'table tbody tr', count: hold_count
  end

  test 'holds by source report allows filtering by term' do
    hold_count = Hold.all.count
    term_count = Hold.joins(:thesis).where('theses.grad_date = ?', '2017-09-01').count
    assert_not_equal hold_count, term_count

    # Add 1 to the select counts for the 'All terms'/'All sources' options
    term_select_count = Report.new.extract_terms(Hold.all).count + 1

    sign_in users(:processor)
    get report_holds_by_source_path
    assert_select 'table tbody tr', count: hold_count
    assert_select 'select[name="graduation"] option', count: term_select_count

    # Now request the queue with a filter applied, and see the correct record count
    get report_holds_by_source_path, params: { graduation: '2017-09-01' }
    assert_select 'table tbody tr', count: term_count
  end

  test 'holds by source report allows filtering by hold source' do
    hold_count = Hold.all.count
    source_count = Hold.where(hold_source_id: "#{hold_sources(:tlo).id}").count

    # Add 1 to the select counts for the 'All terms'/'All sources' options
    source_select_count = HoldSource.pluck(:source).uniq.count + 1

    sign_in users(:processor)
    get report_holds_by_source_path
    assert_select 'table tbody tr', count: hold_count
    assert_select 'select[name="hold_source"] option', count: source_select_count

    # Now request the queue with a filter applied, and the correct record count
    get report_holds_by_source_path, params: { hold_source: 'technology licensing office' }
    assert_select 'table tbody tr', count: source_count
  end

  test 'holds by source report allows filtering by both term and publication status' do
    hold_count = Hold.all.count
    source_count = Hold.joins(:thesis).where('theses.grad_date = ?', '2017-09-01')
                       .where(hold_source_id: "#{hold_sources(:tlo).id}").count

    # Add 1 to the select counts for the 'All terms'/'All sources' options
    term_select_count = Report.new.extract_terms(Hold.all).count + 1
    source_select_count = HoldSource.pluck(:source).uniq.count + 1

    sign_in users(:processor)
    get report_holds_by_source_path
    assert_select 'table tbody tr', count: hold_count
    assert_select 'select[name="graduation"] option', count: term_select_count
    assert_select 'select[name="hold_source"] option', count: source_select_count

    # Now request the queue with both filters applied, and see the correct record count
    get report_holds_by_source_path, params: { graduation: '2017-09-01', hold_source: 'technology licensing office' }
    assert_select 'table tbody tr', count: source_count
  end

  # ~~~~~~~~~~~~~~~~~ Authors not graduated report ~~~~~~~~~~~~~~~~~~~~~~
  test 'authors not graduated report exists' do
    sign_in users(:admin)
    get report_authors_not_graduated_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by authors not graduated report' do
    # Note that nobody is signed in.
    get report_authors_not_graduated_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see authors not graduated report' do
    sign_in users(:basic)
    get report_authors_not_graduated_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see authors not graduated report' do
    sign_in users(:transfer_submitter)
    get report_authors_not_graduated_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see authors not graduated report' do
    sign_in users(:processor)
    get report_authors_not_graduated_path
    assert_response :success
  end

  test 'thesis_admins can see authors not graduated report' do
    sign_in users(:thesis_admin)
    get report_authors_not_graduated_path
    assert_response :success
  end

  test 'admins can see authors not graduated report' do
    sign_in users(:admin)
    get report_authors_not_graduated_path
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~~~ Authors not graduated features ~~~~~~~~~~~~~~~~~~~~
  test 'empty authors not graduated report shows useful text' do
    sign_in users(:processor)

    # Picking an outlandish grad date to ensure we won't have theses
    get report_authors_not_graduated_path, params: { graduation: '1100-09-01' }
    assert_select 'table tbody td', text: 'All thesis authors for the given term have confirmed graduation.', count: 1
  end

  test 'theses with no files do not appear on authors-not-graduated report' do
    thesis = theses(:two)
    assert_not thesis.authors_graduated?
    assert_not thesis.files?

    sign_in users(:processor)
    get report_authors_not_graduated_path
    assert_select 'table tbody td', text: thesis.title, count: 0
  end

  test 'theses with files and at least one unconfirmed graduation appear on authors not graduated report' do
    transfer = transfers(:valid)
    thesis = theses(:two)
    attach_files(transfer, thesis)
    assert_not thesis.authors_graduated?
    assert thesis.files?

    sign_in users(:processor)
    get report_authors_not_graduated_path
    assert_select 'table tbody td', text: thesis.title, count: 1
  end

  test 'thesis with all graduated authors do not appear on authors not graduated report' do
    thesis = theses(:published)
    assert thesis.authors_graduated?
    assert thesis.files?

    sign_in users(:processor)
    get report_authors_not_graduated_path
    assert_select 'table tbody td', text: thesis.title, count: 0
  end

  test 'authors not graduated report can be filtered by term' do
    transfer = transfers(:valid)
    thesis = theses(:two)
    attach_files(transfer, thesis)

    sign_in users(:processor)
    get report_authors_not_graduated_path
    assert_select 'table tbody td', text: thesis.title, count: 1

    get report_authors_not_graduated_path, params: { graduation: '2018-09-01' }
    assert_select 'table tbody td', text: 'All thesis authors for the given term have confirmed graduation.', count: 1
  end

  # ~~~~~~~~~~~~~~~~~ ProQuest status report ~~~~~~~~~~~~~~~~~~~~~~
  test 'anonymous users cannot see ProQuest status report' do
    # Note that nobody is signed in.
    get report_proquest_status_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see ProQuest status report' do
    sign_in users(:basic)
    get report_proquest_status_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see ProQuest status report' do
    sign_in users(:transfer_submitter)
    get report_proquest_status_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see ProQuest status report' do
    sign_in users(:processor)
    get report_proquest_status_path
    assert_response :success
  end

  test 'thesis_admins can see ProQuest status report' do
    sign_in users(:thesis_admin)
    get report_proquest_status_path
    assert_response :success
  end

  test 'admins can see ProQuest status report' do
    sign_in users(:admin)
    get report_proquest_status_path
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~~~ ProQuest status report features ~~~~~~~~~~~~~
  test 'ProQuest status report shows all theses with files by default' do
    thesis_count = Thesis.with_files.advanced_degree.count

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count
  end

  test 'ProQuest status report allows filtering by term' do
    thesis_count = Thesis.with_files.advanced_degree.count
    term_count = Thesis.with_files.advanced_degree.where('theses.grad_date = ?', '2018-06-01').count
    assert_not_equal thesis_count, term_count
    assert term_count > 0

    # Add 1 to the select counts to account for default 'all' option
    term_select_count = Report.new.extract_terms(Thesis.with_files.advanced_degree).count + 1

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count
    assert_select 'select[name="graduation"] option', count: term_select_count

    get report_proquest_status_path, params: { graduation: '2018-06-01' }
    assert_select 'table tbody tr', count: term_count
  end

  test 'ProQuest status report allows filtering by department' do
    thesis_count = Thesis.with_files.advanced_degree.count
    dept_count = Thesis.with_files.advanced_degree.includes(:departments).where(departments: { id: departments(:one).id }).count
    assert_not_equal thesis_count, dept_count
    assert dept_count > 0

    # Add 1 to the select counts to account for default 'all' option
    dept_select_count = Department.pluck(:name_dw).uniq.count + 1

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count
    assert_select 'select[name="department"] option', count: dept_select_count

    get report_proquest_status_path, params: { department: 'Department of Aeronautics and Astronautics' }
    assert_select 'table tbody tr', count: dept_count
  end

  test 'ProQuest status report allows filtering by degree type' do
    thesis_count = Thesis.with_files.advanced_degree.count
    degree_type_count = Thesis.with_files.advanced_degree.includes(degrees: :degree_type).where(degree_type: { id: degree_types(:doctoral).id }).count
    assert degree_type_count < thesis_count

    # Add 1 to the select counts to account for default 'all' option
    degree_type_select_count = DegreeType.pluck(:name).reject { |type| type == 'Bachelor' }.count + 1

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count
    assert_select 'select[name="degree_type"] option', count: degree_type_select_count

    get report_proquest_status_path, params: { degree_type: 'Doctoral' }
    assert_select 'table tbody tr', count: degree_type_count
  end

  test 'ProQuest status report allows filtering by theses with multiple authors' do
    thesis_count = Thesis.with_files.advanced_degree.count
    multi_author_count = Thesis.with_files.advanced_degree.multiple_authors.count
    assert multi_author_count < thesis_count

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count

    get report_proquest_status_path, params: { multi_author: 'true' }
    assert_select 'table tbody tr', count: multi_author_count
  end

  test 'ProQuest status report allows filtering by theses with any number of authors' do
    thesis_count = Thesis.with_files.advanced_degree.count
    multi_author_count = Thesis.with_files.advanced_degree.multiple_authors.count
    assert multi_author_count < thesis_count

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count

    get report_proquest_status_path, params: { multi_author: 'false' }
    assert_select 'table tbody tr', count: thesis_count
  end

  test 'ProQuest status report allows filtering by published theses' do
    thesis_count = Thesis.with_files.advanced_degree.count
    published_count = Thesis.with_files.advanced_degree.where(publication_status: 'Published').count
    assert published_count < thesis_count

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count

    get report_proquest_status_path, params: { published: 'true' }
    assert_select 'table tbody tr', count: published_count
  end

  test 'ProQuest status report shows all theses if published is false' do
    thesis_count = Thesis.with_files.advanced_degree.count
    published_count = Thesis.with_files.advanced_degree.where(publication_status: 'Published').count
    assert published_count < thesis_count

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count

    get report_proquest_status_path, params: { published: 'false' }
    assert_select 'table tbody tr', count: thesis_count
  end

  test 'ProQuest status report allows multiple filters to be applied simultaneously' do
    thesis_count = Thesis.with_files.advanced_degree.count
    filtered_count = Thesis.with_files.advanced_degree.includes(degrees: :degree_type)
                           .where('theses.grad_date = ?', '2022-06-01')
                           .where(degree_type: { id: degree_types(:engineer).id })
                           .where(publication_status: 'Published').count
    assert filtered_count < thesis_count
    assert filtered_count > 0

    sign_in users(:processor)
    get report_proquest_status_path
    assert_select 'table tbody tr', count: thesis_count

    get report_proquest_status_path,
        params: { graduation: '2018-06-01', degree_type: 'Engineer', published: 'true' }
    assert_select 'table tbody tr', count: filtered_count
  end

  # Note that we are merely testing for the presence of the cards and not their contents. Testing the display of cards
  # would make the test suite more brittle, as the numbers will change when the fixtures do.
  test 'ProQuest status report cards appear when expected' do
    sign_in users(:processor)

    # Confirm that any cards should display.
    assert Thesis.with_files.advanced_degree.count > 0

    get report_proquest_status_path
    assert_select '.card-proquest-status'
  end

  # The only condition we are testing is no results. Cards of a given status only display when there is a result
  # matching the given status, but testing every condition would assume that the status of fixtures do not change.
  test 'ProQuest cards do not appear when not expected' do
    sign_in users(:processor)

    # Confirm that no cards should display.
    assert_equal 0,
                 Thesis.with_files.advanced_degree.includes(:departments).where(departments: { name_dw: 'Program in Extreme Metallurgy' }).count

    get report_proquest_status_path, params: { department: 'Program in Extreme Metallurgy' }
    assert_select '.card-proquest-status', count: 0
  end
end
