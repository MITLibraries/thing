class ThesisController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource except: :create
  protect_from_forgery with: :exception

  def new
    @thesis = Thesis.new
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
    else
      flash[:error] = "#{@thesis.title} was unable to be edited."
    end
    redirect_to thesis_confirm_path
  end

  # Do not name this simply 'process' or you will shadow a built-in controller
  # function and then you will be sad.
  def process_theses
    @theses = Thesis.by_status(params[:status])
    filter_dates(params)
    sort_theses(params[:sort])
    warn_about_dates(params)

    @theses = @theses.page(params[:page]).per(25)
  end

  def mark_downloaded
    @thesis = Thesis.find(params[:id])
    if not @thesis.status == 'active'
      raise ActionController::BadRequest.new
    end

    @thesis.status = 'downloaded'
    if @thesis.save
      flash[:info] = "#{@thesis.title} has been marked downloaded."
    else
      flash[:error] = "#{@thesis.title} was unable to be marked downloaded."
    end
    redirect_back(fallback_location: process_path)
  end

  def mark_withdrawn
    @thesis = Thesis.find(params[:id])
    # No need to do status checks - people can mark already-downloaded theses
    # as withdrawn since we have no guarantees about business workflow here,
    # and there's no harm in marking withdrawn theses again as withdrawn.

    @thesis.status = 'withdrawn'
    if @thesis.save
      flash[:info] = "#{@thesis.title} has been marked withdrawn."
    else
      flash[:error] = "#{@thesis.title} was unable to be marked withdrawn."
    end
    redirect_back(fallback_location: process_path)
  end

  def annotate
    @thesis = Thesis.find(params[:id])
    key_name = "note_#{@thesis.id}"
    note = params[key_name]
    @thesis.processor_note = note
    if @thesis.save
      flash[:info] = "#{@thesis.title} processor note has been updated."
    else
      flash[:error] = "#{@thesis.title} processor note was unable to be updated."
    end
    redirect_back(fallback_location: process_path)
  end

  def stats
    @theses = Thesis.all
    filter_dates(params)
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
                                   advisors_attributes: [:id, :name])
  end

  def sorted_theses(queryset, sort)
    if sort == 'name'
      queryset.name_asc
    else
      queryset.date_asc
    end
  end

  def format_date_for_filter(month, year, inclusive)
    begin
      if month.present? && year.present?
        formatted_date = Date.new(year=year.to_i, month=month.to_i)
      elsif year.present?
        if inclusive
          formatted_date = Date.new(year=year.to_i, month=12, day=31)
        else
          formatted_date = Date.new(year=year.to_i)
        end
      else
        formatted_date = nil
      end
    rescue TypeError, ArgumentError
      formatted_date = nil
    end
    formatted_date
  end

  # This limits the theses to those within the date range specified by the
  # user, if present. We do this filtering INCLUSIVELY - asking for theses
  # from June 2017 to May 2018 will return June 2017 and May 2018 theses as
  # well as everything in between.
  def filter_dates(params)
    start_date = format_date_for_filter(params["start_month"], params["start_year"], false)
    end_date = format_date_for_filter(params["end_month"], params["end_year"], true)

    if start_date.present?
      @theses = @theses.where('grad_date >= ?', start_date)
    end

    if end_date.present?
      @theses = @theses.where('grad_date <= ?', end_date)
    end
  end

  def sort_theses(sort)
    if sort == 'name'
      @theses = @theses.name_asc
    else
      @theses = @theses.date_asc
    end
  end

  def warn_about_dates(params)
    if params["start_month"].present?
      # This doesn't work if you symbolize the hash key in `exclude?`.
      if params.keys.exclude?("start_year") || params["start_year"].empty?
        flash.now[:start] = 'Please specify a start year if you specify a start month. No start date filter has been applied.<br/>'
      end
    end
    if params["end_month"].present?
      if params.keys.exclude?("end_year") || params["end_year"].empty?
        flash.now[:end] = 'Please specify an end year if you specify an end month. No end date filter has been applied.'
      end
    end
  end
end
