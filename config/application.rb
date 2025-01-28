require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SULRequests
  class Application < Rails::Application
    config.application_name = 'SUL Requests'
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.exceptions_app = self.routes

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.eager_load_paths << Rails.root.join("extras")

    config.middleware.use Warden::Manager do |manager|
      manager.default_strategies :shibboleth
    end

    require 'token_encryptor'
    # Load all request types automatically
    config.autoload_paths += %W( #{config.root}/app/models/requests #{config.root}/app/mailers/factories )

    config.time_zone = 'Pacific Time (US & Canada)'

    config.scanning_library_proxy = { 'SCAN' => 'GREEN' }

    config.no_user_privs_codes = ['U003', 'U004']

    config.mediator_contact_info = {
      'ART'        => { email: 'sul-requests-art@lists.stanford.edu' },
      'EDUCATION'  => { email: 'sul-requests-education@lists.stanford.edu'},
      'GRE-HH-SVA'    => { email: 'sul-requests-sva@lists.stanford.edu' },
      'MARINE-BIO'    => { email: 'sul-requests-hopkins@lists.stanford.edu' },
      'PAGE-MP'    => { email: 'sul-requests-branner@lists.stanford.edu' },
      'SAL3-PAGE-MP'    => { email: 'sul-requests-branner@lists.stanford.edu' },
      'SPEC-COLL'  => { email: 'sul-requests-spec@lists.stanford.edu' },
      'RUMSEY-MAP'  => { email: 'sul-requests-rumsey@lists.stanford.edu' }
    }

    config.illiad_nvtgc_map = {
      default: 'stf',
      'organization:law' => 'rcj',
      'organization:gsb' => 's7z'
    }
  end
end
