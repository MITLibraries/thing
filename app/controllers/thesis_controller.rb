class ThesisController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource

  def new
    @thesis = Thesis.new
    @thesis.user = current_user
  end

  def create
    @thesis = Thesis.new(thesis_params)
    @thesis.user = current_user
    if @thesis.save
      flash.notice = 'Your thesis submission is now in progress'
      redirect_to thesis_path(@thesis)
    else
      render 'new'
    end
  end

  def show
    @thesis = Thesis.find(params[:id])
  end

  # Do not name this simply 'process' or you will shadow a built-in controller
  # function and then you will be sad.
  def process_theses
    @theses = Thesis.order('grad_date ASC').page(params[:page]).per(25)
  end

  def mark_downloaded
    @thesis = Thesis.find(params[:id])
    if not @thesis.status == 'active'
      raise ActionController::BadRequest.new
    end

    @thesis.status = 'downloaded'

    respond_to do |format|
      if @thesis.save
        format.js
        format.html { redirect_to process_path }
        render json: { id: params[:id], saved: true }
      else
        format.js
        format.html { redirect_to process_path }
        render json: { id: params[:id], saved: false }
      end
    end
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

  def thesis_params
    params.require(:thesis).permit(:title, :abstract, :graduation_month,
                                   :graduation_year, :right_id,
                                   department_ids: [], degree_ids: [])
  end
end
