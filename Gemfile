source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'puma'
gem 'rails', '~> 5.1.2'
gem 'sass-rails'
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
  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'
end
