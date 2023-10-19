class FileController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  before_action :load_thesis_and_attachment
  load_and_authorize_resource
  protect_from_forgery with: :exception

  def rename_form
    return if appropriate_attachment_for_thesis?

    error_nonmatching_thesis_message
    redirect_to thesis_process_path(@thesis)
  end

  def rename
    prerename_validations
    rename_attachment unless flash.key?(:error)

    redirect_to thesis_process_path(@thesis)
  end

  private

  def prerename_validations
    error_nonmatching_thesis_message unless appropriate_attachment_for_thesis?
    error_duplicate_name_message if new_duplicate?
  end

  def new_duplicate?
    return false if @thesis.files.count == 1
    return true if attachment_names_except_current.include?(params[:attachment][:filename])

    false
  end

  def attachment_names_except_current
    @thesis.files.map { |x| x.filename if x != @attachment }.compact
  end

  def rename_attachment
    @attachment.blob.filename = params[:attachment][:filename]

    if @attachment.blob.save
      flash[:success] = success_message
    else
      flash[:error] = error_rename_failed_message
    end
  end

  def appropriate_attachment_for_thesis?
    @thesis.files.include?(@attachment)
  end

  def load_thesis_and_attachment
    @thesis = Thesis.find(params[:thesis_id])
    @attachment = ActiveStorage::Attachment.find(params[:attachment_id])
  end

  def error_duplicate_name_message
    flash[:error] = 'The new name you chose is the same as an existing name of a file attached to this thesis.'
  end

  def success_message
    "#{@thesis.title} file #{@attachment.filename} been updated."
  end

  def error_rename_failed_message
    "#{@thesis.title} file was unable to be updated"
  end

  def error_nonmatching_thesis_message
    flash[:error] = 'The file to be renamed was not associated with the thesis being edited.'
  end
end
