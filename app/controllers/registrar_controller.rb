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
      redirect_to harvest_path
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
    @jobs = Delayed::Job.where(queue: 'default')
  end

  # Do not name this simply 'process' or you will shadow a built-in controller
  # function and then you will be sad.
  def process_registrar
    @registrar = Registrar.find(params[:id])

    RegistrarImportJob.perform_later(@registrar)

    flash[:notice] = 'Job started...'
    redirect_to '/harvest'
  end

  private

  def registrar_params
    params.require(:registrar).permit(:graduation_list)
  end
end
