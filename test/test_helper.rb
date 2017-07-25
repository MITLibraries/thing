require 'simplecov'
require 'coveralls'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start('rails')

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alpha order.
    fixtures :all

    def mock_auth(user)
      OmniAuth.config.mock_auth[:mit_oauth2] =
        OmniAuth::AuthHash.new(provider: 'mit_oauth2',
                               uid: user.uid,
                               info: { email: user.email })
      get '/users/auth/mit_oauth2/callback'
    end
  end
end
