class RegistrarController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource
  protect_from_forgery with: :exception

  def new
    @registrar = Registrar.new
    @registrar.user = current_user
  end

  def create
    @registrar = Registrar.new(registrar_params)
    @registrar.user = current_user
    @registrar.graduation_list.attach(params[:registrar][:graduation_list])
    if @registrar.save
      flash.notice = 'Thank you for submitting this Registrar file.'
      redirect_to root_path()
    else
      flash[:error] = "Error saving Registrar file: #{@registrar.errors.full_messages}"
      render 'new'
    end
  end

  def show
    @registrar = Registrar.find(params[:id])
  end

  def list_registrar
    @registrars = Registrar.all
    @jobs = Delayed::Job.all
  end

  # Do not name this simply 'process' or you will shadow a built-in controller
  # function and then you will be sad.
  def process_registrar
    @registrar = Registrar.find(params[:id])

    Delayed::Job.enqueue RegistrarImportJob.new("Does this appear?")

    flash[:notice] = "Job started..."
    redirect_to '/harvest'
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

  def registrar_params
    params.require(:registrar).permit(:graduation_list)
  end
end
