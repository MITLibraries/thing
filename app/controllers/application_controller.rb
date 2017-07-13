class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def new_session_path(_scope)
    root_path
  end
end
