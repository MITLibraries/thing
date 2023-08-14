module FakeAuthConfig
  # Used in an initializer to determine if the application is configured and
  # allowed to use fake authentication.
  def self.fake_auth_status
    return true if fake_auth_enabled? && app_name_pattern_match?

    false
  end

  private_class_method def self.fake_auth_enabled?
    # Default to fake auth in development unless FAKE_AUTH_ENABLED=false
    # This allows rake tasks to run without loading ENV.
    # This line is not testable because it checks for dev env explicitly.
    if Rails.env.development? && ENV['FAKE_AUTH_ENABLED'].nil?
      true
    else
      ENV['FAKE_AUTH_ENABLED'] == 'true'
    end
  end

  # Checks to make sure the application is not the staging or production
  # instance via a heroku ENV.
  # In development env we always return `true` to avoid having to set a fake app
  # name to match the pr build name patterns.
  # In test env we require setting a fake app name to allow for testing of the
  # pattern.
  private_class_method def self.app_name_pattern_match?
    return true if Rails.env.development?

    # TODO: remove this line once we have confirmed the S3 and SQS migration to the new AWS org. We created a temporary
    # second review app to test that migration.
    return true if ENV.fetch('HEROKU_APP_NAME', nil) == 'thesis-submit-staging-new'

    review_app_pattern = /^thesis-(submit|dropbox)-pr-\d+$/
    review_app_pattern.match(ENV.fetch('HEROKU_APP_NAME', nil)).present?
  end
end
