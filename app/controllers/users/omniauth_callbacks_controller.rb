module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def saml
      @user = User.from_omniauth(request.env['omniauth.auth'])
      sign_in_and_redirect @user, event: :authentication
      flash[:notice] = "Welcome #{@user.email}!"
    end

    # Do _NOT_ set FAKE_AUTH_ENABLED in staging or production. Ever. Bad Idea.
    def developer
      raise 'Invalid Authentication' unless ENV['FAKE_AUTH_ENABLED'] == 'true'
      @user = User.from_omniauth(request.env['omniauth.auth'])
      @user.admin = true
      @user.uid = @user.email
      @user.save
      sign_in_and_redirect @user, event: :authentication
      flash[:notice] = "Welcome #{@user.email}!"
    end
  end
end
