require 'test_helper'

class FilesControllerTest < ActionDispatch::IntegrationTest
  test 'anonymous users are prompted to log in when accessing rename form' do
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    get "/file/rename/#{@thesis.id}/#{@attachment.id}"

    assert_response :redirect
    assert_redirected_to '/login'
  end

  test 'basic can not access file rename form' do
    sign_in users(:basic)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    get "/file/rename/#{@thesis.id}/#{@attachment.id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'transfer_submitter can not access file rename form' do
    sign_in users(:transfer_submitter)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    get "/file/rename/#{@thesis.id}/#{@attachment.id}"
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div.alert', text: 'Not authorized.', count: 1
  end

  test 'thesis processors can access file rename form' do
    sign_in users(:processor)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    get "/file/rename/#{@thesis.id}/#{@attachment.id}"
    assert_response :success
  end

  test 'thesis admins can access file rename form' do
    sign_in users(:thesis_admin)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    get "/file/rename/#{@thesis.id}/#{@attachment.id}"
    assert_response :success
  end

  test 'thesis admins can rename blob filename' do
    sign_in users(:thesis_admin)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)

    post rename_file_path(@thesis, @attachment),
         params: { attachment: { filename: 'renamed_a_pdf_too.pdf' } }
    follow_redirect!
    assert_equal thesis_process_path(theses(:publication_review)), path

    assert_select '.alert-banner.success',
                  text: 'MyReadyThesis file renamed_a_pdf_too.pdf been updated.', count: 1

    @attachment.reload

    assert_equal('renamed_a_pdf_too.pdf', @attachment.blob.filename.to_s)
  end

  test 'thesis processor can rename blob filename' do
    sign_in users(:processor)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)

    post rename_file_path(@thesis, @attachment),
         params: { attachment: { filename: 'renamed_a_pdf_too.pdf' } }
    follow_redirect!
    assert_equal thesis_process_path(theses(:publication_review)), path

    assert_select '.alert-banner.success',
                  text: 'MyReadyThesis file renamed_a_pdf_too.pdf been updated.', count: 1

    @attachment.reload

    assert_equal('renamed_a_pdf_too.pdf', @attachment.blob.filename.to_s)
  end

  test 'basic user can not rename blob filename' do
    sign_in users(:basic)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)

    post rename_file_path(@thesis, @attachment),
         params: { attachment: { filename: 'renamed_a_pdf_too.pdf' } }
    follow_redirect!
    assert_equal root_path, path

    assert_select 'div.alert', text: 'Not authorized.', count: 1

    @attachment.reload

    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)
  end

  test 'transfer_submitter user can not rename blob filename' do
    sign_in users(:transfer_submitter)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)

    post rename_file_path(@thesis, @attachment),
         params: { attachment: { filename: 'renamed_a_pdf_too.pdf' } }
    follow_redirect!
    assert_equal root_path, path

    assert_select 'div.alert', text: 'Not authorized.', count: 1

    @attachment.reload

    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)
  end

  test 'anonymous user can not rename blob filename' do
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)

    post rename_file_path(@thesis, @attachment),
         params: { attachment: { filename: 'renamed_a_pdf_too.pdf' } }
    assert_redirected_to '/login'

    @attachment.reload

    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)
  end

  test 'renaming a file does not change the file checksum' do
    sign_in users(:thesis_admin)
    @thesis = theses(:publication_review)
    @attachment = @thesis.files.first
    assert_equal('a_pdf.pdf', @attachment.blob.filename.to_s)
    assert_equal('KADsjJnGD1sVUgvqyZOaRg==', @attachment.checksum)

    post rename_file_path(@thesis, @attachment),
         params: { attachment: { filename: 'renamed_a_pdf_too.pdf' } }
    follow_redirect!
    assert_equal thesis_process_path(theses(:publication_review)), path

    assert_select '.alert-banner.success',
                  text: 'MyReadyThesis file renamed_a_pdf_too.pdf been updated.', count: 1

    @attachment.reload

    assert_equal('renamed_a_pdf_too.pdf', @attachment.blob.filename.to_s)
    assert_equal('KADsjJnGD1sVUgvqyZOaRg==', @attachment.checksum)
  end

  test 'creating a duplicate filename flashes a warning and does not rename file' do
    sign_in users(:thesis_admin)
    @thesis = theses(:rename_attachment_tests)
    assert_equal(2, @thesis.files.count)
    @attachment_one = @thesis.files.first
    @attachment_two = @thesis.files.last

    # unique filenames
    assert(@thesis.files.map { |f| f.filename.to_s }.uniq.count == 2)

    # rename one file to same as other
    post rename_file_path(@thesis, @attachment_one),
         params: { attachment: { filename: @attachment_two.filename.to_s } }
    follow_redirect!
    assert_equal thesis_process_path(theses(:rename_attachment_tests)), path

    assert_select '.alert-banner.error',
                  text: 'The new name you chose is the same as an existing name of a file attached to this thesis.', count: 1

    @attachment_one.reload
    @attachment_two.reload

    # unique filenames (still)
    assert(@thesis.files.map { |f| f.filename.to_s }.uniq.count == 2)
  end

  test 'renaming a file on a thesis with multiple files only renames the intended file' do
    sign_in users(:thesis_admin)
    @thesis = theses(:rename_attachment_tests)
    assert_equal(2, @thesis.files.count)
    @attachment_one = @thesis.files.first
    @attachment_two = @thesis.files.last

    # unique filenames
    assert(@thesis.files.map { |f| f.filename.to_s }.uniq.count == 2)

    # rename one file to same as other
    post rename_file_path(@thesis, @attachment_one),
         params: { attachment: { filename: 'hallo.pdf' } }
    follow_redirect!
    assert_equal thesis_process_path(theses(:rename_attachment_tests)), path

    assert_select '.alert-banner.success',
                  text: 'rename_my_attachments file hallo.pdf been updated.', count: 1

    @attachment_one.reload
    @attachment_two.reload

    # unique filenames (still)
    assert(@thesis.files.map { |f| f.filename.to_s }.uniq.count == 2)
  end

  test 'accessing rename form with non-matching thesis and attachment redirects to thesis page with warning' do
    sign_in users(:thesis_admin)
    @thesis = theses(:publication_review)
    @different_thesis = theses(:rename_attachment_tests)
    @attachment = @different_thesis.files.first
    get "/file/rename/#{@thesis.id}/#{@attachment.id}"
    assert_response :redirect

    follow_redirect!
    assert_equal thesis_process_path(theses(:publication_review)), path
    assert_select '.alert-banner.error',
                  text: 'The file to be renamed was not associated with the thesis being edited.', count: 1
  end

  test 'submitting rename form with non-matching thesis and attachment redirects to thesis page with warning' do
    sign_in users(:thesis_admin)
    @thesis = theses(:publication_review)
    @different_thesis = theses(:rename_attachment_tests)
    @attachment = @different_thesis.files.first

    assert_equal('b_pdf.pdf', @attachment.blob.filename.to_s)

    post rename_file_path(@thesis, @attachment),
         params: { attachment: { filename: 'renamed_a_pdf_too.pdf' } }
    follow_redirect!
    assert_equal thesis_process_path(theses(:publication_review)), path

    assert_select '.alert-banner.error',
                  text: 'The file to be renamed was not associated with the thesis being edited.', count: 1

    @attachment.reload

    refute_equal('renamed_a_pdf_too.pdf', @attachment.blob.filename.to_s)
    assert_equal('b_pdf.pdf', @attachment.blob.filename.to_s)
  end
end
