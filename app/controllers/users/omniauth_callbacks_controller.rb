module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token

    def saml
      @user = User.from_omniauth(request.env['omniauth.auth'])
      sign_in_and_redirect @user, event: :authentication
      flash[:notice] = "Welcome #{@user.email}!"
    end

    # Make sure to use Rails.configuration.fake_auth_enabled and not
    # ENV['FAKE_AUTH_ENABLED'] here. The config performs an additional check
    # to make sure we're not on the production server.
    def developer
      raise 'Invalid Authentication' unless Rails.configuration.fake_auth_enabled

      # User.from_omniauth will look in auth.info for a uid, but the fake auth
      # actually has auth.uid, not auth.info.uid.
      request.env['omniauth.auth'].info.uid = request.env['omniauth.auth'].uid

      @user = User.from_omniauth(request.env['omniauth.auth'])
      @user.admin = true
      @user.save
      sign_in_and_redirect @user, event: :authentication
      flash[:notice] = "Welcome #{@user.email}!"
    end
  end
end
