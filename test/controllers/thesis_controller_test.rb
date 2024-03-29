require 'test_helper'

class ThesisControllerTest < ActionDispatch::IntegrationTest
  def attach_files_to_records(tr, th)
    # Ideally our fixtures would have already-attached files, but they do not
    # yet. So we attach two files to a transfer and thesis record, to prepare
    # for tests involving the thesis processing workflow.
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

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~ the submission system ~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'new prompts for login' do
    get '/thesis/new'
    assert_redirected_to '/login'
  end

  test 'new when logged in' do
    sign_in users(:yo)
    get '/thesis/new'
    assert_response :success
  end

  test 'redirect after successful submission' do
    sign_in users(:yo)
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
    assert_response :redirect
    assert_redirected_to thesis_confirm_path

    # Check assumption.
    assert_equal title, Thesis.last.title
  end

  test 'rerender after failed submission' do
    sign_in users(:yo)
    orig_thesis_count = Thesis.count
    title = 'Spacecraft avoidance: a short'
    post '/thesis',
         params: {
           thesis: {
             title: title,
             abstract: 'Frook.',
             # The missing department ids here should cause the form to fail.
             degree_ids: degrees(:one).id.to_s,
             graduation_year: (Time.current.year + 1).to_s,
             graduation_month: 'December',
             files: fixture_file_upload('a_pdf.pdf', 'application/pdf')
           }
         }
    # We expect a 200 OK for the http call, even though the form submission is
    # not a success.
    assert_response :success
    assert_equal('create', @controller.action_name)

    # No new theses have been created.
    assert_equal(orig_thesis_count, Thesis.count)
  end

  test 'user can view their own thesis' do
    sign_in users(:yo)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  test 'user cannot view another user thesis' do
    sign_in users(:bad)
    get "/thesis/#{theses(:one).id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'anonymous user cannot view another user thesis' do
    get "/thesis/#{theses(:one).id}"
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'admin users can view another user thesis' do
    sign_in users(:admin)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  test 'thesis_admin users can view another user thesis' do
    sign_in users(:thesis_admin)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  test 'processor users can view another user thesis' do
    sign_in users(:processor)
    get "/thesis/#{theses(:one).id}"
    assert_response :success
  end

  # Tests below this note are to protect us from our future selves.
  # Currently we have no routes for delete/update or controller actions to
  # handle this, but I'm adding these tests to remind us in the future that if
  # we do add those features we need to confirm the abilities match our
  # expectations as these tests will fail and we'll need to make decisions.
  test 'a user cannot delete their thesis' do
    sign_in users(:yo)
    assert_raises(ActionController::RoutingError) do
      delete "/thesis/#{theses(:one).id}"
    end
  end

  test 'an anonymous user cannot delete a thesis' do
    assert_raises(ActionController::RoutingError) do
      delete "/thesis/#{theses(:one).id}"
    end
  end

  # admin users _can_ do this in the admin interface
  test 'an admin user cannot delete a user thesis' do
    sign_in users(:admin)
    assert_raises(ActionController::RoutingError) do
      delete "/thesis/#{theses(:one).id}"
    end
  end

  test 'a user cannot update their thesis' do
    sign_in users(:yo)
    assert_raises(ActionController::RoutingError) do
      post "/thesis/#{theses(:one).id}",
           params: { thesis: { title: 'yoyos are cool' } }
    end
  end

  test 'an anonymous user cannot update a thesis' do
    assert_raises(ActionController::RoutingError) do
      post "/thesis/#{theses(:one).id}",
           params: { thesis: { title: 'yoyos are cool' } }
    end
  end

  # admin users _can_ do this in the admin interface
  test 'an admin user cannot update a user thesis' do
    sign_in users(:admin)
    assert_raises(ActionController::RoutingError) do
      post "/thesis/#{theses(:one).id}",
           params: { thesis: { title: 'yoyos are cool' } }
    end
  end

  test 'processor note field does not show on thesis submission page' do
    sign_in users(:yo)
    get new_thesis_path

    assert_select 'label', text: 'Note:', count: 0
    assert_select 'textarea.thesis_note', count: 0
  end

  test 'processor note does not show on thesis viewing page' do
    yo = users(:yo)
    sign_in yo

    thesis = yo.theses.first
    note_text = 'Yo dawg, I heard you like notes on your thesis'
    thesis.processor_note = note_text
    thesis.save
    get thesis_path(thesis)

    assert_no_match note_text, response.body
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~ thesis processing queue ~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'thesis processing queue exists' do
    sign_in users(:admin)
    get thesis_select_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by processing queue' do
    # Note that nobody is signed in.
    get thesis_select_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see processing queue' do
    sign_in users(:basic)
    get thesis_select_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see processing queue' do
    sign_in users(:transfer_submitter)
    get thesis_select_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see processing queue' do
    sign_in users(:processor)
    get thesis_select_path
    assert_response :success
  end

  test 'thesis_admins can see processing queue' do
    sign_in users(:thesis_admin)
    get thesis_select_path
    assert_response :success
  end

  test 'admins can see processing queue' do
    sign_in users(:admin)
    get thesis_select_path
    assert_response :success
  end

  test 'processing queue shows nothing without files attached' do
    sign_in users(:processor)
    Thesis.all.map { |t| t.files.delete_all }
    get thesis_select_path
    assert @response.body.include? 'No theses found'
  end

  test 'processing queue shows records with files attached' do
    sign_in users(:processor)
    get thesis_select_path
    expected_theses = Thesis.joins(:files_attachments).group(:id).where('publication_status != ?', 'Published')
    expected_theses.each do |et|
      assert @response.body.include? thesis_process_path(et.id).to_s
    end
  end

  test 'processing queue allows filtering by term' do
    # Request the processing queue and note six records, with three filter
    # options (two specific terms, and the "all terms" option)
    sign_in users(:processor)
    get thesis_select_path
    assert_select 'table#thesisQueue tbody tr', count: 7
    assert_select 'select[name="graduation"] option', count: 4
    # Now request the queue with a term filter applied, and see three records
    get thesis_select_path, params: { graduation: '2018-06-01' }
    assert_select 'table#thesisQueue tbody tr', count: 3
    # Now request the queue with an invalid filter applied, and see the no records message
    get thesis_select_path, params: { graduation: '2018-09-01' }
    assert @response.body.include? 'No theses found'
  end

  # ~~~~~~~~~~~~~~~ duplicate theses / multiple authors report ~~~~~~~~~~~~~~~~
  test 'duplicate report exists' do
    sign_in users(:admin)
    get thesis_deduplicate_path
    assert_response :success
  end

  test 'anonymous users are prompted to log in by duplicates report' do
    # Note that nobody is signed in.
    get thesis_deduplicate_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see duplicates report' do
    sign_in users(:basic)
    get thesis_deduplicate_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see duplicates report' do
    sign_in users(:transfer_submitter)
    get thesis_deduplicate_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see duplicates report' do
    sign_in users(:processor)
    get thesis_deduplicate_path
    assert_response :success
  end

  test 'thesis_admins can see duplicates report' do
    sign_in users(:thesis_admin)
    get thesis_deduplicate_path
    assert_response :success
  end

  test 'admins can see duplicates report' do
    sign_in users(:admin)
    get thesis_deduplicate_path
    assert_response :success
  end

  test 'duplicates report shows duplicate records' do
    sign_in users(:processor)
    get thesis_deduplicate_path
    assert_select 'td', text: 'MyString', count: 2
  end

  test 'duplicates report allows filtering by term' do
    # Request the duplicates report and note N records, with three filter
    # options (two specific terms, and the "all terms" option)
    sign_in users(:processor)
    get thesis_deduplicate_path
    assert_select 'table#thesisQueue tbody tr', count: 3
    assert_select 'select[name="graduation"] option', count: 3
    # Now request the queue with a filter applied, and see only one record
    get thesis_deduplicate_path, params: { graduation: '2018-09-01' }
    assert_select 'table#thesisQueue tbody tr', count: 1
  end

  # ~~~~~~~~~~~~~~~ publication status report ~~~~~~~~~~~~~~~~
  test 'anonymous users cannot see publication status report' do
    # Note that nobody is signed in.
    get thesis_publication_statuses_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see publication status report' do
    sign_in users(:basic)
    get thesis_publication_statuses_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see publication status report' do
    sign_in users(:transfer_submitter)
    get thesis_publication_statuses_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see publication status report' do
    sign_in users(:processor)
    get thesis_publication_statuses_path
    assert_response :success
  end

  test 'thesis_admins can see publication status report' do
    sign_in users(:thesis_admin)
    get thesis_publication_statuses_path
    assert_response :success
  end

  test 'admins can see publication status report' do
    sign_in users(:admin)
    get thesis_publication_statuses_path
    assert_response :success
  end

  test 'publication status report shows theses with any status by default' do
    # Calculate counts based on current test db, since these numbers will change as the fixtures do
    thesis_count = Thesis.all.count

    sign_in users(:processor)
    get thesis_publication_statuses_path
    assert_select 'table#thesisQueue tbody tr', count: thesis_count
  end

  test 'publication status report allows filtering by term' do
    # Calculate counts based on current test db, since these numbers will change as the fixtures do
    thesis_count = Thesis.all.count
    term_count = Thesis.where(grad_date: '2018-09-01').count

    # Make sure term_count is not equal to thesis_count, or else this test is meaningless
    assert_not_equal thesis_count, term_count

    # Add 1 to the select counts for the 'All terms'/'All statuses' options
    term_select_count = Thesis.pluck(:grad_date).uniq.count + 1

    sign_in users(:processor)
    get thesis_publication_statuses_path
    assert_select 'table#thesisQueue tbody tr', count: thesis_count
    assert_select 'select[name="graduation"] option', count: term_select_count

    # Now request the queue with a filter applied, and see the correct record count
    get thesis_publication_statuses_path, params: { graduation: '2018-09-01' }
    assert_select 'table#thesisQueue tbody tr', count: term_count
  end

  test 'publication status report allows filtering by publication status' do
    # Calculate counts based on current test db, since these numbers will change as the fixtures do
    thesis_count = Thesis.all.count
    status_count = Thesis.where(publication_status: 'Not ready for publication').count

    # Add 1 to the select counts for the 'All terms'/'All statuses' options
    status_select_count = Thesis.pluck(:publication_status).uniq.count + 1

    sign_in users(:processor)
    get thesis_publication_statuses_path
    assert_select 'table#thesisQueue tbody tr', count: thesis_count
    assert_select 'select[name="status"] option', count: status_select_count

    # Now request the queue with a filter applied, and the correct record count
    get thesis_publication_statuses_path, params: { status: 'Not ready for publication' }
    assert_select 'table#thesisQueue tbody tr', count: status_count
  end

  test 'publication status report allows filtering by both term and publication status' do
    # Calculate counts based on current test db, since these numbers will change as the fixtures do
    thesis_count = Thesis.all.count
    status_count = Thesis.where(publication_status: 'Not ready for publication', grad_date: '2021-06-01').count

    # Add 1 to the select counts for the 'All terms'/'All statuses' options
    term_select_count = Thesis.pluck(:grad_date).uniq.count + 1
    status_select_count = Thesis.pluck(:publication_status).uniq.count + 1

    sign_in users(:processor)
    get thesis_publication_statuses_path
    assert_select 'table#thesisQueue tbody tr', count: thesis_count
    assert_select 'select[name="graduation"] option', count: term_select_count
    assert_select 'select[name="status"] option', count: status_select_count

    # Now request the queue with both filters applied, and see the correct record count
    get thesis_publication_statuses_path, params: { graduation: '2021-06-01', status: 'Not ready for publication' }
    assert_select 'table#thesisQueue tbody tr', count: status_count
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~ thesis processing form ~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'thesis processing form exists' do
    sign_in users(:admin)
    get thesis_process_path(theses(:one))
    assert_response :success
  end

  test 'anonymous users are prompted to log in by processing form' do
    # Note that nobody is signed in.
    get thesis_process_path(theses(:one))
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot see processing form' do
    sign_in users(:basic)
    get thesis_process_path(theses(:one))
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot see processing form' do
    sign_in users(:transfer_submitter)
    get thesis_process_path(theses(:one))
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can see processing form' do
    sign_in users(:processor)
    get thesis_process_path(theses(:one))
    assert_response :success
  end

  test 'thesis_admins can see processing form' do
    sign_in users(:thesis_admin)
    get thesis_process_path(theses(:one))
    assert_response :success
  end

  test 'admins can see processing form' do
    sign_in users(:admin)
    get thesis_process_path(theses(:one))
    assert_response :success
  end

  # ~~~~~~~~~~~~~~~~~~~ submitting thesis processing form ~~~~~~~~~~~~~~~~~~~~~
  test 'anonymous users cannot submit thesis processing form' do
    patch thesis_process_update_path(theses(:one)),
          params: { thesis: { title: 'Something nonsensical' } }
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot submit thesis processing form' do
    sign_in users(:basic)
    patch thesis_process_update_path(theses(:one)),
          params: { thesis: { title: 'Any value' } }
    assert_response :redirect
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'transfer_submitters cannot submit thesis processing form' do
    sign_in users(:transfer_submitter)
    patch thesis_process_update_path(theses(:one)),
          params: { thesis: { title: 'Any value' } }
    assert_response :redirect
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'thesis_processors can submit thesis processing form' do
    sign_in users(:processor)
    patch thesis_process_update_path(theses(:one)),
          params: { thesis: { title: 'Any value' } }
    follow_redirect!
    assert_equal path, thesis_process_path(theses(:one))
  end

  test 'thesis_admins can submit thesis processing form' do
    sign_in users(:thesis_admin)
    patch thesis_process_update_path(theses(:one)),
          params: { thesis: { title: 'Any value' } }
    follow_redirect!
    assert_equal path, thesis_process_path(theses(:one))
  end

  test 'admins can submit thesis processing form' do
    sign_in users(:admin)
    patch thesis_process_update_path(theses(:one)),
          params: {
            thesis: { title: 'Something nonsensical' }
          }
    follow_redirect!
    assert_equal path, thesis_process_path(theses(:one))
  end

  test 'submitting the thesis processing form without deleting a file does not affect file counts' do
    sign_in users(:processor)
    tr = transfers(:valid)
    th = theses(:publication_review_except_hold)
    attach_files_to_records(tr, th)
    transfer_file_count = tr.files.count
    thesis_file_count = th.files.count
    attachment_count = ActiveStorage::Attachment.count
    blob_count = ActiveStorage::Blob.count
    patch thesis_process_update_path(theses(:publication_review_except_hold)),
          params: {
            thesis: {
              title: 'My Almost-Ready Thesis',
              issues_found: 'true',
              files_attachments_attributes: {
                '0': {
                  id: th.files.first.id,
                  description: 'A phrase to describe the file'
                }
              }
            }
          }
    follow_redirect!
    # Unlinking does not reduce the number of blobs, nor how many are attached to the transfer.
    # However, the number of files on the thesis does decrease (as does the total number of attachments).
    tr.reload
    th.reload
    assert_equal transfer_file_count, tr.files.count
    assert_equal thesis_file_count, th.files.count
    assert_equal attachment_count, ActiveStorage::Attachment.count
    assert_equal blob_count, ActiveStorage::Blob.count
  end

  test 'removing one of two files from a thesis will adjust counts appropriately' do
    sign_in users(:processor)
    tr = transfers(:valid)
    th = theses(:publication_review_except_hold)
    transfer_file_count = tr.files.count
    thesis_file_count = th.files.count
    attachment_count = ActiveStorage::Attachment.count
    blob_count = ActiveStorage::Blob.count
    patch thesis_process_update_path(theses(:publication_review_except_hold)),
          params: {
            thesis: {
              title: 'My Almost-Ready Thesis',
              issues_found: 'true',
              files_attachments_attributes: {
                '0': {
                  id: th.files.first.id,
                  _destroy: 1
                }
              }
            }
          }
    follow_redirect!
    # Unlinking does not reduce the number of blobs, nor how many are attached to the transfer.
    # However, the number of files on the thesis does decrease (as does the total number of attachments).
    tr.reload
    th.reload
    assert_equal transfer_file_count, tr.files.count
    assert_equal thesis_file_count - 1, th.files.count
    assert_equal attachment_count - 1, ActiveStorage::Attachment.count
    assert_equal blob_count, ActiveStorage::Blob.count
  end

  test 'removing a file from a thesis will be reflected with a link to its transfer in the flash message' do
    sign_in users(:processor)
    tr = transfers(:valid)
    th = theses(:publication_review_except_hold)
    attach_files_to_records(tr, th)
    patch thesis_process_update_path(theses(:publication_review_except_hold)),
          params: {
            thesis: {
              title: 'My Almost-Ready Thesis',
              issues_found: 'true',
              files_attachments_attributes: {
                '0': {
                  id: th.files.first.id,
                  _destroy: 1
                }
              }
            }
          }
    follow_redirect!
    # The flash message has a link back to the transfer with the file.
    assert_select 'div.alert ul li a', text: 'a_pdf.pdf', href: transfer_path(th), count: 1
  end

  test 'removing a file from a thesis will reset files_complete flag' do
    sign_in users(:processor)
    tr = transfers(:valid)
    th = theses(:publication_review_except_hold)
    th.files_complete = true
    th.save
    assert(th.files_complete)
    attach_files_to_records(tr, th)
    patch thesis_process_update_path(theses(:publication_review_except_hold)),
          params: {
            thesis: {
              title: 'My Almost-Ready Thesis',
              issues_found: 'true',
              files_attachments_attributes: {
                '0': {
                  id: th.files.first.id,
                  _destroy: 1
                }
              }
            }
          }
    th.reload
    refute(th.files_complete)
  end

  # ~~~~~~~~~~~~~~~~~~~ publication preview ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'anonymous users get redirected if they load the publication preview list' do
    get thesis_publish_preview_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users get redirected if they load the publication preview list' do
    sign_in users(:basic)
    get thesis_publish_preview_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters get redirected if they load the publication preview list' do
    sign_in users(:transfer_submitter)
    get thesis_publish_preview_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can load the publication preview list' do
    sign_in users(:processor)
    get thesis_publish_preview_path
    assert_response :success
  end

  test 'thesis admins can load the publication preview list' do
    sign_in users(:thesis_admin)
    get thesis_publish_preview_path
    assert_response :success
  end

  test 'admins can load the publication preview list' do
    sign_in users(:admin)
    get thesis_publish_preview_path
    assert_response :success
  end

  test 'publication preview, without a term specified, does not link to the publish step' do
    sign_in users(:processor)
    get thesis_publish_preview_path
    assert_select 'div#publish-to-dspace', count: 1
    assert_select 'div#publish-to-dspace a[href=?]', thesis_publish_to_dspace_path,
                  text: 'Publish theses to DSpace@MIT', count: 0
  end

  test 'publication preview, with a term specified, includes a button to actually publish that includes the term parameter' do
    sign_in users(:processor)
    needle = '2018-09-01'
    get thesis_publish_preview_path, params: { graduation: needle }
    assert_select 'div#publish-to-dspace', count: 1
    assert_select 'div#publish-to-dspace a[href=?]', thesis_publish_to_dspace_path(graduation: needle)
  end

  # ~~~~~~~~~~~~~~~~~~~ publishing theses to dspace ~~~~~~~~~~~~~~~~~~~~~
  test 'anonymous users get redirected if they request publication to dspace' do
    get thesis_publish_to_dspace_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot publish to dspace' do
    sign_in users(:basic)
    get thesis_publish_to_dspace_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot publish to dspace' do
    sign_in users(:transfer_submitter)
    get thesis_publish_to_dspace_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can publish to dspace' do
    sign_in users(:processor)
    get thesis_publish_to_dspace_path
    assert_redirected_to thesis_select_path
  end

  test 'thesis_admins can publish to dspace' do
    sign_in users(:thesis_admin)
    get thesis_publish_to_dspace_path
    assert_redirected_to thesis_select_path
  end

  test 'admins can publish to dspace' do
    sign_in users(:admin)
    get thesis_publish_to_dspace_path
    assert_redirected_to thesis_select_path
  end

  test 'publishing to dspace without a term specified will generate a flash warning' do
    sign_in users(:processor)
    get thesis_publish_to_dspace_path
    assert_redirected_to thesis_select_path
    follow_redirect!
    assert_select '.alert-banner.warning',
                  text: 'Please select a term before attempting to publish theses to DSpace@MIT.', count: 1
    get thesis_publish_to_dspace_path, params: { graduation: 'all' }
    assert_redirected_to thesis_select_path(params: { graduation: 'all' })
    follow_redirect!
    assert_select '.alert-banner.warning',
                  text: 'Please select a term before attempting to publish theses to DSpace@MIT.', count: 1
  end

  test 'publishing a specific term to dspace ends back at the processing queue with a flash success' do
    sign_in users(:processor)
    get thesis_publish_to_dspace_path, params: { graduation: '2018-09-01' }
    assert_redirected_to thesis_select_path(params: { graduation: '2018-09-01' })
    follow_redirect!
    assert_select '.alert-banner.success',
                  text: 'The theses you selected have been added to the publication queue. Status updates are not immediate.', count: 1
  end

  # ~~~~~~~~~~~~~~~~~~~~~ proquest export preview ~~~~~~~~~~~~~~~~~~~~~
  test 'anonymous users get redirected if they load the proquest export preview list' do
    get thesis_proquest_export_preview_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users get redirected if they load the proquest export preview list' do
    sign_in users(:basic)
    get thesis_proquest_export_preview_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters get redirected if they load the proquest export preview list' do
    sign_in users(:transfer_submitter)
    get thesis_proquest_export_preview_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can load the proquest export preview list' do
    sign_in users(:processor)
    get thesis_proquest_export_preview_path
    assert_response :success
  end

  test 'thesis admins can load the proquest export preview list' do
    sign_in users(:thesis_admin)
    get thesis_proquest_export_preview_path
    assert_response :success
  end

  test 'admins can load the proquest export preview list' do
    sign_in users(:admin)
    get thesis_proquest_export_preview_path
    assert_response :success
  end

  test 'proquest export cannot be initiated with no eligible theses' do
    sign_in users(:processor)
    Thesis.destroy_all
    get thesis_proquest_export_preview_path
    assert_select 'div#export-action', count: 1
    assert_select 'div#export-action a[href=?]', thesis_proquest_export_path, count: 0
  end

  test 'proquest export preview, with eligible theses, includes a button to export' do
    sign_in users(:processor)
    get thesis_proquest_export_preview_path
    assert_select 'div#export-action', count: 1
    assert_select 'div#export-action a[href=?]', thesis_proquest_export_path
  end

  # ~~~~~~~~~~~~~~~~~~~~~ exporting theses to proquest ~~~~~~~~~~~~~~~~~~~~~
  test 'anonymous users get redirected if they request export to proquest' do
    get thesis_proquest_export_path
    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic users cannot export export_to_proquest proquest' do
    sign_in users(:basic)
    get thesis_proquest_export_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'submitters cannot export to proquest' do
    sign_in users(:transfer_submitter)
    get thesis_proquest_export_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'processors can export to proquest' do
    sign_in users(:processor)
    get thesis_proquest_export_path
    assert_redirected_to thesis_proquest_export_preview_path
  end

  test 'thesis_admins can export to proquest' do
    sign_in users(:thesis_admin)
    get thesis_proquest_export_path
    assert_redirected_to thesis_proquest_export_preview_path
  end

  test 'admins can export_to_proquest' do
    sign_in users(:admin)
    get thesis_proquest_export_path
    assert_redirected_to thesis_proquest_export_preview_path
  end

  test 'exporting to proquest redirects to proquest export preview path with a flash message' do
    sign_in users(:processor)
    clear_enqueued_jobs
    assert_enqueued_jobs 0

    get thesis_proquest_export_path
    assert_enqueued_jobs 1
    assert_redirected_to thesis_proquest_export_preview_path
    follow_redirect!
    assert_select '.alert-banner.success',
                  text: 'The theses you selected will be exported. Status updates are not immediate.', count: 1
  end

  test 'exporting to proquest with no eligible theses redirects to proquest export preview path with a flash message' do
    sign_in users(:processor)
    Thesis.destroy_all
    get thesis_proquest_export_path
    assert_redirected_to thesis_proquest_export_preview_path
    follow_redirect!
    assert_select '.alert-banner.warning', text: 'No theses are available to export.', count: 1
  end

  # ~~~~~~~~~~~~~~~~~~~~~ resetting publishing error status ~~~~~~~~~~~~~~~~~~~~~
  test 'anonymous users get redirected if they try to reset publishing errors' do
    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0

    get reset_all_publication_errors_path
    assert_response :redirect
    assert_redirected_to '/login'

    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0
  end

  test 'basic users cannot reset publishing errors' do
    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0

    sign_in users(:basic)
    get reset_all_publication_errors_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1

    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0
  end

  test 'submitters cannot reset publishing errors' do
    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0

    sign_in users(:transfer_submitter)
    get reset_all_publication_errors_path
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1

    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0
  end

  test 'processors can reset publishing errors' do
    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0

    sign_in users(:processor)
    get reset_all_publication_errors_path
    assert_redirected_to thesis_select_path

    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count == 0
  end

  test 'thesis_admins can reset publishing errors' do
    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0

    sign_in users(:thesis_admin)
    get reset_all_publication_errors_path
    assert_redirected_to thesis_select_path

    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count == 0
  end

  test 'admins can reset publishing errors' do
    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count > 0

    sign_in users(:admin)
    get reset_all_publication_errors_path
    assert_redirected_to thesis_select_path

    error_count = Thesis.where(publication_status: 'Publication error').count
    assert error_count == 0
  end
end
