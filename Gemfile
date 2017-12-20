source 'https://rubygems.org'
ruby '2.4.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'administrate'
gem 'devise'
gem 'lograge'
gem 'omniauth-saml'
gem 'puma'
gem 'rails', '5.1.4'
gem 'rollbar'
gem 'sass-rails'
gem 'simple_form'
gem 'therubyracer', platforms: :ruby
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
  gem 'listen'
  gem 'rubocop'
  gem 'web-console'
end

group :test do
  gem 'coveralls', require: false
  gem 'minitest-reporters'
end
