class ReportController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource except: :create
  protect_from_forgery with: :exception

  include ThesisHelper

  require 'CSV'

  def empty_theses
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    @this_term = 'all terms'
    @this_term = term.in_time_zone('Eastern Time (US & Canada)').strftime('%b %Y') if term != 'all'
    report = Report.new
    theses = Thesis.without_files.includes(:authors).includes(authors: :user).includes(:departments).all
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @data = report.empty_theses_data subset
    @record = report.empty_theses_record subset
  end

  def expired_holds
    @list = Hold.active_or_expired.ends_today_or_before.order(:date_end)
  end

  def files
    report = Report.new
    theses = Thesis.all
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @list = report.list_unattached_files subset
  end

  def proquest_files
    report = Report.new
    theses = Thesis.all
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @list = report.list_proquest_files subset
  end

  def student_submitted_theses
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    @this_term = 'all terms'
    @this_term = term.in_time_zone('Eastern Time (US & Canada)').strftime('%b %Y') if term != 'all'
    report = Report.new
    theses = Thesis.all
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @list = report.list_student_submitted_metadata subset
  end

  def index
    report = Report.new
    @terms = Thesis.pluck(:grad_date).uniq.sort
    @data = report.index_data
  end

  def term
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    @this_term = 'all terms'
    @this_term = term.in_time_zone('Eastern Time (US & Canada)').strftime('%b %Y') if term != 'all'
    report = Report.new
    theses = Thesis.all
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @data = report.term_data subset, term
    @table = report.term_tables subset
  end

  def term_csv
    term = params[:graduation]
    @theses = Thesis.where(publication_status: 'Published').where('grad_date = ?', params[:graduation])
    @csv_hash = {
      headers: ['authors', 'title', 'departments', 'degrees', 'tranfer_date', 'published_date', 'handle']
    }
    @theses.each do |thesis|
      row = []
      row << thesis.users.map{|user| user.name.tr(',', ' ')}.join(';')
      row << thesis.title
      row << thesis.departments.map{|d| d.name_dspace.tr(',', ' ')}.join(';')
      row << thesis.degrees.map{|d| d.name_dspace.tr(',', ' ')}.join(';')
      row << thesis.date_primary_thesis_file_received
      row << thesis.date_published
      row << thesis.dspace_handle
      @csv_hash["thesis_#{thesis.id}".to_sym] = row
    end

    respond_to do |format|
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=theses.csv"
        render(
          formats: [:csv],
          template: 'thesis/theses_by_term',
        )
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
end
