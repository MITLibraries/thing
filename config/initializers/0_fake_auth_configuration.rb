# This configuration needs to load before the devise initializer so this value
# is available when needed.

require "#{Rails.root}/app/models/concerns/fake_auth_config.rb"
Rails.application.config.fake_auth_enabled = FakeAuthConfig.fake_auth_status
