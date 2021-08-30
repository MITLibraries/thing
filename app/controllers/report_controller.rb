class ReportController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource except: :create
  protect_from_forgery with: :exception

  include ThesisHelper

  def index
    term = params[:graduation] ? params[:graduation].to_s : 'all'
    report = Report.new
    theses = Thesis.all
    @terms = report.extract_terms theses
    subset = filter_theses_by_term theses
    @data = report.dashboard_data subset, term
    @table = report.dashboard_tables subset
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
