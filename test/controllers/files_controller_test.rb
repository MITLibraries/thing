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
end
