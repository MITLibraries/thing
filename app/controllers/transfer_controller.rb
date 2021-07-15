class TransferController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource
  protect_from_forgery with: :exception

  def new
    @transfer = Transfer.new
    @transfer.user = current_user
  end

  def create
    @transfer = Transfer.new(transfer_params)
    @transfer.user = current_user
    @transfer.files.attach(params[:transfer][:files])
    if params[:transfer][:department_id]
      @transfer.department = Department.find(params[:transfer][:department_id])
    end
    if @transfer.save
      flash[:success] = "<h3>Success!</h3><p>#{@transfer.files.count} files have been transferred. You will receive an email confirmation with a list of the files you transferred.</p>"
      ReceiptMailer.transfer_receipt_email(@transfer, current_user).deliver_later
      redirect_to transfer_confirm_path
    else
      flash[:error] = "Error saving transfer: #{@transfer.errors.full_messages}"
      render 'new'
    end

    # A virus detected prior to the Transfer being saved throws this error but
    # our application and the files in s3 are in a state where it is safe to
    # continue and investigate which file was problematic asynchronously
    rescue Aws::S3::Errors::AccessDenied
      flash[:error] = "We detected a potential problem with a file in your upload. Library staff will contact you with details when we have more details."
      ReceiptMailer.transfer_receipt_email(@transfer, current_user).deliver_later

      ReceiptMailer.virus_detected_email(@transfer).deliver_later
      redirect_to transfer_confirm_path
  end

  def files
    transfer = Transfer.find(params[:id])
    thesis = Thesis.find(params[:thesis])
    flash[:success] = ("The following files have been assigned to '" + thesis.title + "'<br><br>").html_safe
    filelist = params[:transfer][:file_ids]
    filelist.each do |file|
      file = transfer.files.find_by id: file
      thesis.files.attach(file.blob)
      flash[:success] += (file.filename.to_s + "<br>").html_safe
    end
    redirect_to transfer_path(transfer.id, view_all: params[:view_all] || 'false')
  end

  def select
    @transfer = Transfer.all
  end

  def show
    # Load the details of the requested Transfer record
    @transfer = Transfer.find(params[:id])

    # Load the Thesis records for the period covered by this Transfer (the
    # graduation month/year, and the department)
    @theses = Thesis.where('grad_date = ?', @transfer.grad_date)
    @theses = @theses.includes(:departments).where("departments.name_dw = ?", @transfer.department.name_dw).references(:departments)
  end

  private

  def require_user
    return if current_user
    # Do NOT use ENV['FAKE_AUTH_ENABLED'] directly! Use the config. It performs
    # an additional check to make sure we are not on the production server.
    if Rails.configuration.fake_auth_enabled
      redirect_to user_developer_omniauth_authorize_path
    else
      redirect_to user_saml_omniauth_authorize_path
    end
  end

  def transfer_params
    params.require(:transfer).permit(:graduation_month, :graduation_year, 
                                     :department_id, :note, :file_ids)
  end
end
