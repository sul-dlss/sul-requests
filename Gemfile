source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.1'
# Use sqlite3 as the database (during local development)
gem 'sqlite3'
# Use mysql as the database when running on the server environment
gem 'mysql2'
# Use sass-powered bootstrap
gem 'bootstrap-sass', "~> 3.3.4"
# Use bootstrap_form for easy form building
gem 'bootstrap_form'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# JS Runtime. See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer'
# A gem for simple rails invornment specific config
gem 'rails_config'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# CanCanCan is an authorization Gem for rails
gem 'cancancan', '~> 1.10'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # RSpec for testing
  gem 'rspec-rails', '~> 3.0'

  # Capybara for feature/integration tests
  gem 'capybara'

  # factory_girl_rails for creating fixtures in tests
  gem 'factory_girl_rails'

  # Poltergeist is a capybara driver to run integration tests using PhantomJS
  gem 'poltergeist'

  # Database cleaner allows us to clean the entire database after certain tests
  gem 'database_cleaner'

  # Rubocop is a static code analyzer to enforce style.
  gem 'rubocop', require: false

  # Coveralls for code coverage metrics
  gem 'coveralls', require: false
end
