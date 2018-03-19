class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def new_session_path(_scope)
    root_path
  end

  def after_sign_in_path_for(_resource_or_scope)
    if can?(:process_theses, Thesis)
      process_path
    else
      new_thesis_path
    end
  end
end
