# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rails'
require 'timecop'

# Auto require all files in spec/support.
Rails.root.glob('spec/support/**/*.rb').each { |f| require f }

# Working around https://github.com/teamcapybara/capybara/issues/2800
Capybara.register_driver :selenium_chrome_headless do |app|
  browser_options = Selenium::WebDriver::Chrome::Options.new
  browser_options.add_argument('--headless=new')
  browser_options.add_argument('--window-size=1920,1080')
  browser_options.add_argument('--disable-background-timer-throttling')
  browser_options.add_argument('--disable-backgrounding-occluded-windows')
  browser_options.add_argument('--disable-renderer-backgrounding')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end
Capybara.javascript_driver = :selenium_chrome_headless

# Set a little higher for github actions, to avoid flappy tests
Capybara.default_max_wait_time = ENV['CI'] ? 10 : 5

Capybara.disable_animation = true

# Allow selecting capybara elements via aria-label
Capybara.enable_aria_label = true

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

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join('spec/fixtures')]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include ActiveSupport::Testing::TimeHelpers

  config.before do
    stub_request(:any, %r{http://example.com/.*}).to_return(status: 200, body: '', headers: {})
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

  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveJob::TestHelper, type: :feature

  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  config.include Warden::Test::Helpers
  config.include Warden::Test::ControllerHelpers, type: :controller
  config.after do
    Warden.test_reset!
  end
end

def stub_current_user(user = create(:anon_user))
  allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
end
