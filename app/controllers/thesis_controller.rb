class ThesisController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!

  def new
    @thesis = Thesis.new
    @thesis.user = current_user
  end

  def create
    @thesis = Thesis.new(thesis_params)
    @thesis.user = current_user
    if @thesis.save
      flash.notice = 'Your thesis submission is now in progress'
      redirect_to root_path
    else
      render 'new'
    end
  end

  private

  def require_user
    return if current_user
    if ENV['FAKE_AUTH_ENABLED'] == 'true'
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
