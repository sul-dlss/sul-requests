require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SULRequests
  class Application < Rails::Application
    config.application_name = 'SUL Requests'
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.action_mailer.default_url_options = { host: Settings.mailer_host }

    require 'token_encryptor'
    # Load all request types automatically
    config.autoload_paths += %W( #{config.root}/app/models/requests #{config.root}/app/mailers/factories )

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.confirm_eligibility_libraries = ['ART', 'EDUCATION','RUMSEYMAP', 'SPEC-COLL']

    config.scanning_library_proxy = { 'SCAN' => 'GREEN' }

    if Rails.env.test?
      config.pageable_libraries = [
        'SAL',
        'SAL3',
        'SAL-NEWARK'
      ]
    else
      config.pageable_libraries = ['GREEN']
    end

    # ad_hoc_item_commentable_libraries is configured to not display for any library.
    # Keeping this feature in case SPEC-COLL changes thier minds or we need to add
    # this behavior for another library.
    config.ad_hoc_item_commentable_libraries = []
    config.item_commentable_libraries = ['SAL-NEWARK', 'SPEC-COLL']

    config.contact_info = {
      'PAGE-MP' => {
        phone: '(650) 723-2746',
        email: 'brannerlibrary@stanford.edu'
      }
    }

    config.symphony_success_codes = ['209', '722', 'S001', 'P001', 'P001B', 'P002', 'P005']

    config.no_user_privs_codes = ['U003', 'U004']

    config.mediator_contact_info = {
      'ART'        => { email: 'sul-requests-art@lists.stanford.edu' },
      'EDUCATION'  => { email: 'sul-requests-education@lists.stanford.edu'},
      'HV-ARCHIVE' => { email: 'sul-requests-hoover-archive@lists.stanford.edu' },
      'HOOVER'     => { email: 'sul-requests-hoover-library@lists.stanford.edu' },
      'HOPKINS'    => { email: 'sul-requests-hopkins@lists.stanford.edu' },
      'PAGE-MP'    => { email: 'sul-requests-branner@lists.stanford.edu' },
      'SPEC-COLL'  => { email: 'sul-requests-spec@lists.stanford.edu' },
      'RUMSEYMAP'  => { email: 'sul-requests-rumsey@lists.stanford.edu' }
    }

    config.picklist_contact_info = {
      'SPEC-COLL' => { email: 'specialcollections@stanford.edu' }
    }

    config.illiad_nvtgc_map = {
      default: 'st2',
      'organization:law' => 'rcj',
      'organization:gsb' => 's7z'
    }

    config.pickup_library_pseudo_patrons = {
      'HOOV-DESK' => 'HOLD@HL',
      'SPEC-DESK' => 'HOLD@SP',

    config.scan_destinations = {
      'EAL_REVIEW_WORKFLOW' => { key: 'EAST-ASIA', patron_barcode: 'EAL-SCANREVIEW' },
      'GREEN' => { key: 'GREEN', patron_barcode: 'GRE-SCANDELIVER' },
      'SAL' => { key: 'GREEN', patron_barcode: 'GRE-SCANDELIVER' },
      'SAL3' => { key: 'SAL3', patron_barcode: 'SAL3-SCANDELIVER' }
    }
  end
end
