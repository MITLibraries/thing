# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_user!
    before_action :authenticate_admin
    before_action :set_paper_trail_whodunnit

    # Ensure that current user has admin privileges.
    def authenticate_admin
      admin_actions = %w[show update index create edit]

      if current_user
        if [can?(:administrate, Admin) &&
            admin_actions.include?(params[:action]),
            current_user.admin?].any?

          return
        end
      end

      redirect_to '/', alert: 'Not authorized.'
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
