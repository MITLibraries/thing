require 'simplecov'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
]
SimpleCov.start('rails')

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alpha order.
    fixtures :all

    setup do
      ActiveStorage::Current.host = "https://example.com"
    end

    def mock_auth(user)
      OmniAuth.config.mock_auth[:saml] =
        OmniAuth::AuthHash.new(provider: 'saml',
                               uid: user.uid,
                               info: { uid: user.uid, email: user.email })

      get '/users/auth/saml/callback'
    end

    def auth_setup
      Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
      Rails.application.env_config['omniauth.auth'] =
        OmniAuth.config.mock_auth[:saml]
      OmniAuth.config.test_mode = true
    end

    def auth_teardown
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:saml] = nil
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers

    def remove_uploaded_files
      FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
    end

    def after_teardown
      super
      remove_uploaded_files
    end
  end
end
