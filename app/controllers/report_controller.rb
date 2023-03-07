class ReportController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource except: :create
  protect_from_forgery with: :exception

  include ThesisHelper
  include HoldHelper

  def authors_not_graduated
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    @this_term = 'all terms'
    @this_term = term.in_time_zone('Eastern Time (US & Canada)').strftime('%b %Y') if term != 'all'
    report = Report.new
    theses = Thesis.with_files.includes(authors: :user).includes(:departments)
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @list = report.list_authors_not_graduated subset
  end

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
    @list = Hold.active_or_expired.ends_today_or_before.order(:date_end).includes([:thesis, {
                                                                                    thesis: %i[authors departments]
                                                                                  }])
  end

  def files
    report = Report.new
    theses = Thesis.all.with_attached_files.includes(%i[authors departments])
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

  def proquest_status
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    @this_term = 'all terms'
    @this_term = term.in_time_zone('Eastern Time (US & Canada)').strftime('%b %Y') if term != 'all'
    theses = Thesis.with_files.advanced_degree.includes(authors: :user).includes(:departments)
                   .includes(degrees: :degree_type)
    @terms = Report.new.extract_terms theses
    @departments = Department.pluck(:name_dw)
    @degree_types = DegreeType.pluck(:name).reject { |type| type == 'Bachelor' }
    filtered = filter_proquest_status(theses)
    @data = proquest_status_counts(filtered)
    @list = filtered
  end

  def student_submitted_theses
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    @this_term = 'all terms'
    @this_term = term.in_time_zone('Eastern Time (US & Canada)').strftime('%b %Y') if term != 'all'
    report = Report.new
    theses = Thesis.all.includes([:versions])
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @list = report.list_student_submitted_metadata subset
  end

  def holds_by_source
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    @this_term = 'all terms'
    @this_term = term.in_time_zone('Eastern Time (US & Canada)').strftime('%b %Y') if term != 'all'
    holds = Hold.all.includes([:thesis, :hold_source, { thesis: [:authors, { authors: :user }] }])
    @terms = Report.new.extract_terms holds
    @hold_sources = HoldSource.pluck(:source).uniq.sort
    term_filtered = filter_holds_by_term holds
    @list = filter_holds_by_source term_filtered
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
end
