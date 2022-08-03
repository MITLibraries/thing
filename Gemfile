source 'https://rubygems.org'
ruby '3.1.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'administrate'
gem 'aws-sdk-rails'
gem 'aws-sdk-s3'
gem 'bootsnap'
gem 'cancancan'
gem 'cocoon'
gem 'delayed_job_active_record'
gem 'devise'
gem 'json'
gem 'kaminari'
gem 'lograge'
gem 'marc'
gem 'mitlibraries-theme'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-saml'
gem 'paper_trail'
gem 'puma'
gem 'rails', '~> 6.1.0'
gem 'rubyzip'
gem 'sass-rails'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'simple_form'
gem 'skylight'
gem 'uglifier'
gem 'zip_tricks'

group :production do
  gem 'pg'
end

group :development, :test do
  gem 'byebug'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'sqlite3'
end

group :development do
  gem 'annotate'
  gem 'dotenv-rails'
  gem 'letter_opener'
  gem 'listen'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'scout_apm'
  gem 'web-console'
end

group :test do
  gem 'climate_control'
  gem 'minitest-reporters'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'timecop'
end
