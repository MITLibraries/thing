require 'simplecov'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov::Formatter::LcovFormatter.config.lcov_file_name = 'coverage.lcov'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
]
SimpleCov.start('rails')

# We've experienced segmentation faults when pre-compiling assets with libsass.
# Disabling Sprockets export_concurrent setting seems to resolve the issues
# see: https://github.com/rails/sprockets/issues/633
# see: https://github.com/sass/sassc-ruby/issues/207#issuecomment-929299171
require 'sprockets'
Sprockets.export_concurrent = false

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require "minitest/reporters"
if ENV.fetch("SPEC_REPORTER", false)
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
else
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
end
module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alpha order.
    fixtures :all

    setup do
      ActiveStorage::Current.host = "https://example.com"

      # This is required for tests that reference the authors_count counter cache on the Thesis model. If we add other
      # counter caches, we should reset them here.
      Thesis.all.each { |thesis| Thesis.reset_counters(thesis.id, :authors) }
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
