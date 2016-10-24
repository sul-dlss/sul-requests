source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'
# Use sqlite3 as the database (during local development)
gem 'sqlite3'
# Use mysql as the database when running on the server environment
gem 'mysql2', '~> 0.3.0'
# Use sass-powered bootstrap
gem 'bootstrap-sass', "~> 3.3.4"
# Use bootstrap_form for easy form building
gem 'bootstrap_form'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2.1'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# JS Runtime. See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer'
# Common styles for SUL
gem 'sul_styles', '>= 0.5.0'
# A gem for simple rails invornment specific config
gem 'config'
# Use jquery as the JavaScript library
# (pinning to < 4.1 until issue w/ webshims is resolved https://github.com/aFarkas/webshim/issues/560)
gem 'jquery-rails', '< 4.1'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# CanCanCan is an authorization Gem for rails
gem 'cancancan', '~> 1.10'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
# Use faraday for making HTTP requests
gem 'faraday'
# Use kaminari for pagination
gem 'kaminari'
gem 'kaminari_bootstrap_paginator'

gem 'redcarpet'

gem 'hash_to_hidden_fields'

# Use Capistrano for deployment
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano'
end

# Use Honeybadger for exception reporting
gem 'honeybadger'

# Use is_it_working to monitor the application
gem 'is_it_working'

# lograge to reduce noise in logs
gem 'lograge'

# Access an IRB console on exception pages or by using <%= console %> in views
gem 'web-console', '~> 2.0', group: :development

# test coverage in static code analysis GUI
gem 'codeclimate-test-reporter', group: :test, require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # RSpec for testing
  gem 'rspec-rails', '~> 3.0'

  # Capybara for feature/integration tests
  gem 'capybara'

  # factory_girl_rails for creating fixtures in tests
  gem 'factory_girl_rails'

  # Poltergeist is a capybara driver to run integration tests using PhantomJS
  gem 'poltergeist'

  # Teaspoon-jasmine is a wrapper for the Jasmine javascript testing library
  gem 'teaspoon-jasmine'

  # Allows jQuery integration into the Jasmine javascript testing framework
  gem 'jasmine-jquery-rails'

  # Database cleaner allows us to clean the entire database after certain tests
  gem 'database_cleaner'

  # Rubocop is a static code analyzer to enforce style.
  gem 'rubocop', '~> 0.36', require: false

  # scss-lint will test the scss files to enfoce styles
  gem 'scss-lint', require: false

  # Coveralls for code coverage metrics
  gem 'coveralls', require: false
end
