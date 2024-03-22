source 'https://rubygems.org'

gem 'rails', '~> 7.1.3'

# Use sqlite3 as the database (during local development)
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 6.0'
gem 'bootsnap'
# Use bootstrap_form for easy form building
gem 'bootstrap_form', '~> 5.4'
# A gem for simple rails environment specific config
gem 'config'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# CanCanCan is an authorization Gem for rails
gem 'cancancan'
# Use faraday for making HTTP requests
gem 'faraday', '~> 2' # for library hours, Illiad, and Folio clients
gem 'faraday-retry'
gem 'http' # for Reshare and SymphonyClient
# Use kaminari for pagination
gem 'kaminari'
gem 'bootstrap5-kaminari-views'

gem 'redcarpet'

gem 'hash_to_hidden_fields'

# Use Honeybadger for exception reporting
gem 'honeybadger'

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

# See https://stackoverflow.com/questions/70500220/rails-7-ruby-3-1-loaderror-cannot-load-such-file-net-smtp
gem 'net-smtp', require: false

gem 'jwt'
gem 'redis', '~> 4.8'
gem 'sidekiq', '~> 7.1'
gem 'whenever', require: false # Work around https://github.com/javan/whenever/issues/831

group :development, :test do
  # Call 'binding.break' anywhere in the code to stop execution and get a debugger console
  gem 'debug'

  # Axe for accessibility testing
  gem 'axe-core-rspec'

  # RSpec for testing
  gem 'rspec-rails', '~> 6.0'

  # Capybara for feature/integration tests
  gem 'capybara'

  # factory_bot_rails for creating fixtures in tests
  gem 'factory_bot_rails', '~> 6.2.0' # Pinned until https://github.com/thoughtbot/factory_bot_rails/issues/433 is resolved

  # selenium-webdriver is used by Capybara for driving "browser" tests
  gem 'selenium-webdriver'

  # Database cleaner allows us to clean the entire database after certain tests
  gem 'database_cleaner'

  # Rubocop is a static code analyzer to enforce style.
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

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

gem "cssbundling-rails", "~> 1.1"

gem "view_component", "~> 3.0"
gem "parslet"

gem "jsbundling-rails", "~> 1.1"
gem "turbo-rails", "~> 1.4"

gem "propshaft", "~> 0.7.0"

gem 'recaptcha'