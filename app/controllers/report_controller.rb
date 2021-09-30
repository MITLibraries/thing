class ReportController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource except: :create
  protect_from_forgery with: :exception

  include ThesisHelper

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
