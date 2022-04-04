# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :require_user
    before_action :authorized_or_redirect
    before_action :set_paper_trail_whodunnit

    def require_user
      return if current_user

      redirect_to login_path, alert: 'Please sign in to continue'
    end

    def authorized_or_redirect
      return if can?(action_name, resource_name)

      redirect_to root_path, alert: 'Not authorized.'
    end

    # Hide links to actions if the user is not allowed to do them.
    # This is an override of an Administrate method to work with CanCan
    def show_action?(action, resource)
      can? action, resource
    end
  end
end
