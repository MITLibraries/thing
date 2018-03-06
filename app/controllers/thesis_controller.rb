class ThesisController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource
  protect_from_forgery with: :exception

  def new
    @thesis = Thesis.new
    @thesis.user = current_user
  end

  def create
    @thesis = Thesis.new(thesis_params)
    @thesis.user = current_user
    @thesis.files.attach(params[:thesis][:files])
    if @thesis.save
      flash.notice = 'Your thesis submission is now in progress'
      ReceiptMailer.receipt_email(@thesis).deliver_later
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
    status = params[:status]
    sort = params[:sort]

    if status == 'any'
      queryset = Thesis.all
    elsif status.present?
      # We could also test that Thesis::STATUS_OPTIONS.include? status,
      # but we aren't, because:
      # 1) if some URL hacker enters status=purple, they'll get 200 OK, not
      #    500;
      # 2) also they deserve the blank page they get.
      queryset = Thesis.where(status: status)
    else
      queryset = Thesis.where(status: 'active')
    end
    @theses = sorted_theses(queryset, sort).page(params[:page]).per(25)
  end

  def mark_downloaded
    @thesis = Thesis.find(params[:id])
    if not @thesis.status == 'active'
      raise ActionController::BadRequest.new
    end

    @thesis.status = 'downloaded'
    handle_thesis_ajax('status')
  end

  def mark_withdrawn
    @thesis = Thesis.find(params[:id])
    # No need to do status checks - people can mark already-downloaded theses
    # as withdrawn since we have no guarantees about business workflow here,
    # and there's no harm in marking withdrawn theses again as withdrawn.

    @thesis.status = 'withdrawn'
    handle_thesis_ajax('status')
  end

  def annotate
    @thesis = Thesis.find(params[:id])
    key_name = "note_#{@thesis.id}"
    note = params[key_name]
    @thesis.note = note
    handle_thesis_ajax('note')
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

  def handle_thesis_ajax(handler)
    respond_to do |format|
      if @thesis.save
        format.js
        format.html { redirect_to process_path }
        render json: { id: params[:id], saved: true, handler: handler }
      else
        format.js
        format.html { redirect_to process_path }
        render json: { id: params[:id], saved: false, handler: handler }
      end
    end
  end

  def sorted_theses(queryset, sort)
    if sort == 'name'
      queryset.name_asc
    else
      queryset.date_asc
    end
  end
end
