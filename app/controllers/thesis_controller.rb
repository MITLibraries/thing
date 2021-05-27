class ThesisController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource except: :create
  protect_from_forgery with: :exception

  def new
    @thesis = Thesis.new
    @thesis.association(:advisors).add_to_target(Advisor.new())
    @thesis.users = [current_user]
  end

  def create
    # First, build a minimum viable thesis from the provided parameters.
    @thesis = Thesis.new()
    @thesis.users = [current_user]
    @thesis.department_ids = thesis_params[:department_ids]
    @thesis.degree_ids = thesis_params[:degree_ids]
    @thesis.graduation_year = thesis_params[:graduation_year]
    @thesis.graduation_month = thesis_params[:graduation_month]
    @thesis.combine_graduation_date

    # Save this minimum viable thesis
    if @thesis.save
      # Now that we've saved something, the rest is handled via update.
      params[:id] = @thesis.id
      update
    else
      render 'new'
    end
  end

  def edit
    @thesis = Thesis.find(params[:id])
    if @thesis.advisors.count == 0
      @thesis.association(:advisors).add_to_target(Advisor.new())
    end
  end

  def select
    @graduation = params[:graduation]
    @thesis = Thesis.joins(:files_attachments).group(:id).where('publication_status != ?', "Published")
    if @graduation && @graduation != "all"
      @thesis = @thesis.where('grad_date = ?', @graduation)
    end
    @terms = Thesis.joins(:files_attachments).group(:id).where('publication_status != ?', "Published").select(:grad_date).map(&:grad_date).uniq.sort
  end

  def show
    @thesis = Thesis.find(params[:id])
  end

  def start
    editable_theses = current_user.editable_theses
    if 0 == editable_theses.count
      redirect_to new_thesis_path
    elsif 1 == editable_theses.count
      redirect_to edit_thesis_path(editable_theses.first.id)
    end
  end

  def update
    @thesis = Thesis.find(params[:id])
    if @thesis.update(thesis_params)
      flash[:success] = "#{@thesis.title} has been updated."
      ReceiptMailer.receipt_email(@thesis, current_user).deliver_later
    else
      flash[:error] = "#{@thesis.title} was unable to be edited."
    end
    redirect_to thesis_confirm_path
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
    params.require(:thesis).permit(:title, :abstract, :coauthors, :graduation_month,
                                   :graduation_year, :copyright_id, :author_note,
                                   :license_id, :department_ids, :degree_ids,
                                   users_attributes: [:id, :orcid, :preferred_name],
                                   advisors_attributes: [:id, :name, :_destroy])
  end

  def sorted_theses(queryset, sort)
    if sort == 'name'
      queryset.name_asc
    else
      queryset.date_asc
    end
  end
end
