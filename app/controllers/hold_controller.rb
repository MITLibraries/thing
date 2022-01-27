class HoldController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource
  protect_from_forgery with: :exception

  def show
    @hold = Hold.find(params[:id])
  end
end
