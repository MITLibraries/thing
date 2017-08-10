class ThesisController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!

  def new; end

  private

  def require_user
    return if current_user
    if ENV['FAKE_AUTH_ENABLED'] == 'true'
      redirect_to user_developer_omniauth_authorize_path
    else
      redirect_to user_mit_oauth2_omniauth_authorize_path
    end
  end
end
