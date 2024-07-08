source 'https://rubygems.org'
ruby '3.2.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'administrate', '~> 0.19.0'
gem 'aws-sdk-rails', '~> 3.8.0'
gem 'aws-sdk-s3', '~> 1.156.0'
gem 'aws-sdk-sqs', '~> 1.62.0'
gem 'bootsnap'
gem 'cancancan'
gem 'cocoon'
gem 'delayed_job_active_record'
gem 'devise'
gem 'flipflop'
gem 'json'
gem 'kaminari'
gem 'lograge'
gem 'marc'
gem 'mitlibraries-theme', git: 'https://github.com/mitlibraries/mitlibraries-theme', tag: 'v1.4'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-saml'
gem 'paper_trail'
gem 'puma'
gem 'rails', '~> 7.0.2', '>= 7.0.2.3'
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
  gem 'bullet'
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
  gem 'rails-mermaid_erd'
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
