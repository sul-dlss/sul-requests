source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'
# Use sqlite3 as the database (during local development)
gem 'sqlite3'
# Use Puma as the app server
gem 'puma'
gem 'bootsnap'
# Use sass-powered bootstrap
gem 'bootstrap-sass', "~> 3.4"
# Use bootstrap_form for easy form building
gem 'bootstrap_form', '< 4' # pin to < 4 since we are not on bootstrap 4
gem 'bootstrap-editable-rails'
gem 'nested_form'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 2.7.2'
# Common styles for SUL
gem 'sul_styles', '>= 0.5.0'
# A gem for simple rails invornment specific config
gem 'config'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# CanCanCan is an authorization Gem for rails
gem 'cancancan'
# Use faraday for making HTTP requests
gem 'faraday', '~> 1'
gem 'http'
# Use kaminari for pagination
gem 'kaminari'
gem 'kaminari_bootstrap_paginator'

gem 'redcarpet'

gem 'hash_to_hidden_fields'

# Use Honeybadger for exception reporting
gem 'honeybadger'

# Use is_it_working to monitor the application
gem 'is_it_working'

# Use okcomputer to monitor the application
gem 'okcomputer'

# lograge to reduce noise in logs
gem 'lograge'

# Access an IRB console on exception pages or by using <%= console %> in views
gem 'web-console', group: :development

# Specify Nokogiri to address security concerns
gem 'nokogiri', '>= 1.7.1'

# borrow_drect gem is used to attempt to submit requests for Hold/Recalls before sending to symphony
gem 'borrow_direct'

# rack is a webserver interface used by rails.
gem 'rack'

group :test do
  gem 'simplecov', require: false
end

# Sidekiq is our background processing framework, run via Active Job
gem 'sidekiq'
gem 'sidekiq-statistic'

gem 'whenever'

gem 'jwt'
gem 'rack-attack'
gem 'redis'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # or call 'binding.pry'  (you may need require 'pry-byebug' first)
  gem 'pry-byebug'

  # RSpec for testing
  gem 'rspec-rails', '~> 4.0'

  # Capybara for feature/integration tests
  gem 'capybara'

  # factory_bot_rails for creating fixtures in tests
  gem 'factory_bot_rails'

  # selenium-webdriver is used by Capybara for driving "browser" tests
  gem 'selenium-webdriver'
  gem 'webdrivers'

  # Database cleaner allows us to clean the entire database after certain tests
  gem 'database_cleaner'

  # Rubocop is a static code analyzer to enforce style.
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

  # scss-lint will test the scss files to enfoce styles
  gem 'scss-lint', require: false

  gem 'rails-controller-testing'

  # listen is used by bootsnap to listen to file changes
  gem 'listen'

  gem 'webmock'
end

group :production do
  # Use mysql as the database when running on the server environment
  gem 'mysql2'
end

# Use Capistrano for deployment
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano'
end
