class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :ensure_domain

  rescue_from CanCan::AccessDenied do
    redirect_to root_path, alert: 'Not authorized.'
  end

  def new_session_path(_scope)
    root_path
  end

  def after_sign_in_path_for(_resource_or_scope)
    if can?(:select, Transfer)
      transfer_select_path
    elsif can?(:create, Transfer)
      new_transfer_path
    else
      thesis_start_path
    end
  end

  private

  # redirects herokuapp domains and old domains to preferred domains
  def ensure_domain
    return unless ENV['PREFERRED_DOMAIN']
    return if request.host == ENV['PREFERRED_DOMAIN']

    Rails.logger.info("Handling Domain Redirect: #{request.host}")
    redirect_to "https://#{ENV['PREFERRED_DOMAIN']}", status: :moved_permanently
  end
end
