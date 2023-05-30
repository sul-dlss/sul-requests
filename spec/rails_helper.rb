# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rails'
require 'selenium-webdriver'

# Auto require all files in spec/support.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
Capybara.javascript_driver = :headless_chrome

Capybara.register_driver :headless_chrome do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args << '--headless'
    opts.args << '--window-size=1000,700'
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end
Capybara.default_max_wait_time = 5
# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# Module that when included causes RSpec to
# stup our API requests. We can then explicitly
# allow them in tests that need them by adding
# allow_apis: true to the tests themselves
module DisallowAPIs
  def self.included(host)
    host.metadata[:allow_apis] = false
  end
end

ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = Rails.root.join('spec/fixtures')

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.include ActiveSupport::Testing::TimeHelpers

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.include DisallowAPIs
  config.before(:each, allow_apis: false) do
    stub_searchworks_api_json({})
    stub_request(:get, %r{https://example.com/symws/.*})
      .to_return(status: 200, body: '', headers: {})
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
end

def stub_current_user(user = create(:anon_user))
  allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
end

def stub_searchworks_api_json(json)
  allow_any_instance_of(SearchworksItem).to receive(:json).and_return(json)
end

def stub_symphony_response(response)
  allow_any_instance_of(Request).to receive(:symphony_response_data).and_return(response)
end

def expect_to_be_on_success_page
  expect(page).to have_css('h1#dialogTitle', text: /We're working on it/)
end
