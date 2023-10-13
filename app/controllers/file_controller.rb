class FileController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource
  protect_from_forgery with: :exception

  def rename_form
    @thesis = Thesis.find(params[:thesis_id])
    @attachment = ActiveStorage::Attachment.find(params[:attachment_id])
  end

  def rename
    thesis = Thesis.find(params[:thesis_id])
    attachment = ActiveStorage::Attachment.find(params[:attachment_id])

    attachment.blob.filename = params[:attachment][:filename]

    if attachment.blob.save
      flash[:success] = "#{thesis.title} file #{attachment.filename} been updated."
    else
      flash[:error] = "#{thesis.title} file was unable to be updated"
    end

    redirect_to thesis_process_path(thesis)
  end
end
