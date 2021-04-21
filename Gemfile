source 'https://rubygems.org'
ruby '2.7.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'active_storage_drag_and_drop'
gem 'administrate'
gem 'aws-sdk-s3'
gem 'bootsnap'
gem 'cancancan'
gem 'cocoon'
gem 'delayed_job_active_record'
gem 'devise'
gem 'json'
gem 'kaminari'
gem 'lograge'
gem 'mitlibraries-theme'
gem 'omniauth-saml'
gem 'paper_trail'
gem 'puma'
gem 'rails', '~> 6.1.0'
gem 'sass-rails'
gem 'sentry-raven'
gem 'simple_form'
gem 'skylight'
gem 'uglifier'

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
  gem 'listen'
  gem 'rubocop'
  gem 'web-console'
end

group :test do
  gem 'climate_control'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
end
