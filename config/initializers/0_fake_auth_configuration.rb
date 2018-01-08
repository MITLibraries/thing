# This configuration needs to load before the devise initializer so this value
# is available when needed.

include FakeAuthConfig
Rails.application.config.fake_auth_enabled = FakeAuthConfig.fake_auth_status
