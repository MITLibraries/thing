require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Before filter for Flipflop dashboard. Replace with a lambda or method name
  # defined in ApplicationController to implement access control.
  config.flipflop.dashboard_access_filter = nil

  # By default, when set to `nil`, strategy loading errors are suppressed in test
  # mode. Set to `true` to always raise errors, or `false` to always warn.
  config.flipflop.raise_strategy_errors = nil


  # Bullet configuration: currently disabled because we can't currently fix all issues
  # This configuration block is still useful to allow manually enabling detection locally
  # to investigate problems.
  config.after_initialize do
    Bullet.enable        = true
    Bullet.bullet_logger = true
    Bullet.raise         = false # raise an error if n+1 query occurs
    Bullet.unused_eager_loading_enable = false
    Bullet.counter_cache_enable        = false
  end

  # Settings specified here will take precedence over those in config/application.rb.

  ENV['SP_PRIVATE_KEY'] = ''
  ENV['SP_CERTIFICATE'] = ''
  ENV['THESIS_ADMIN_EMAIL'] = 'test@example.com'
  ENV['ETD_APP_EMAIL'] = 'app@example.com'
  ENV['METADATA_ADMIN_EMAIL'] = 'test-metadata@example.com'
  ENV['SQS_INPUT_QUEUE_URL'] = 'http://localhost:5000/123456789012/etd-test-input'
  ENV['SQS_OUTPUT_QUEUE_NAME'] = 'etd-test-output'
  ENV['SQS_OUTPUT_QUEUE_URL'] = 'http://localhost:5000/123456789012/etd-test-output'
  ENV['SQS_RESULT_MAX_MESSAGES'] = '10'
  ENV['SQS_RESULT_WAIT_TIME_SECONDS'] = '10'
  ENV['SQS_RESULT_IDLE_TIMEOUT'] = '0'
  ENV['AWS_REGION'] = 'us-east-1'
  ENV['AWS_S3_BUCKET'] = 'fake-etd-bucket'
  ENV['DSPACE_DOCTORAL_HANDLE'] = '1721.1/999999'
  ENV['DSPACE_GRADUATE_HANDLE'] = '1721.1/888888'
  ENV['DSPACE_UNDERGRADUATE_HANDLE'] = '1721.1/777777'
  ENV['APT_CHALLENGE_SECRET'] = 'fake-challenge-secret'
  ENV['APT_S3_BUCKET'] = 's3://fake-apt-bucket'
  ENV['APT_LAMBDA_URL'] = 'https://fake-lambda.example.com/'
  ENV['APT_COMPRESS_ZIP'] = 'true'

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true
end
