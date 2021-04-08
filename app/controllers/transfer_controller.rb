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
      redirect_to transfer_confirm_path
    else
      flash[:error] = "Error saving transfer: #{@transfer.errors.full_messages}"
      render 'new'
    end
  end

  def show
    @transfer = Transfer.find(params[:id])
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
                                     :department_id, :note)
  end
end
