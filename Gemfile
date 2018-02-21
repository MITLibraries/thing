source 'https://rubygems.org'
ruby '2.4.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'administrate'
gem 'aws-sdk-s3'
gem 'bootsnap'
gem 'cancancan'
gem 'delayed_job_active_record'
gem 'devise'
gem 'kaminari'
gem 'lograge'
gem 'omniauth-saml'
gem 'puma'
gem 'rails', '5.2.0.rc1'
gem 'rollbar'
gem 'sass-rails'
gem 'simple_form'
gem 'skylight'
gem 'therubyracer', platforms: :ruby
gem 'uglifier'

group :production do
  gem 'pg', '0.21'
end

group :development, :test do
  gem 'byebug'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'sqlite3'
end

group :development do
  gem 'annotate'
  gem 'listen'
  gem 'rubocop'
  gem 'web-console'
end

group :test do
  gem 'climate_control'
  gem 'coveralls', require: false
end
