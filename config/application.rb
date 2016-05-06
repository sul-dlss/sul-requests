require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SULRequests
  class Application < Rails::Application
    config.application_name = 'SUL Requests'
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'ALLOWALL'
    }

    config.action_mailer.default_url_options = { host: Settings.mailer_host }

    require 'token_encryptor'
    # Load all request types automatically
    config.autoload_paths += %W( #{config.root}/app/models/requests )

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.libraries = {
      'ARS' => 'Archive of Recorded Sound',
      'ART' => 'Art & Architecture Library',
      'BIOLOGY' => 'Biology Library (Falconer)',
      'BUSINESS' => 'Business Library',
      'CHEMCHMENG' => 'Chemistry & ChemEng Library (Swain)',
      'CLASSICS' => 'Classics Library',
      'EARTH-SCI' => 'Earth Sciences Library (Branner)',
      'EAST-ASIA' => 'East Asia Library',
      'EDUCATION' => 'Education Library (Cubberley)',
      'ENG' => 'Engineering Library (Terman)',
      'GREEN' => 'Green Library',
      'HOOVER' => 'Hoover Library',
      'HOPKINS' => 'Marine Biology Library (Miller)',
      'HV-ARCHIVE' => 'Hoover Archives',
      'LANE-MED' => 'Medical Library (Lane)',
      'LATHROP' => 'Lathrop Library',
      'LAW' => 'Law Library (Crown)',
      'MATH-CS' => 'Math & Statistics Library',
      'MEDIA-MTXT' => 'Media Microtext',
      'MUSIC' => 'Music Library',
      'RUMSEYMAP' => 'David Rumsey Map Center',
      'SAL' => 'SAL1&2 (on-campus shelving)',
      'SAL3' => 'SAL3 (off-campus storage)',
      'SAL-NEWARK' => 'SAL Newark (off-campus storage)',
      'SPEC-COLL' => 'Special Collections',
      'TANNER' => 'Philosophy Library (Tanner)'
    }

    config.default_pickup_library = 'GREEN'

    config.pickup_libraries = [
      'ART',
      'BIOLOGY',
      'BUSINESS',
      'CHEMCHMENG',
      'EARTH-SCI',
      'EAST-ASIA',
      'EDUCATION',
      'ENG',
      'GREEN',
      'HOOVER',
      'HOPKINS',
      'LAW',
      'MATH-CS',
      'MUSIC',
      'SAL'
    ]

    config.scanning_library_proxy = { 'SCAN' => 'GREEN' }

    config.library_specific_pickup_libraries = {
      'ARS' => ['ARS'],
      'HOOVER' => ['HOOVER'],
      'HV-ARCHIVE' => ['HV-ARCHIVE'],
      'LAW' => ['LAW'],
      'MEDIA-MTXT' => ['MEDIA-MTXT'],
      'RUMSEYMAP' => ['RUMSEYMAP'],
      'SPEC-COLL' => ['SPEC-COLL']
    }

    config.pageable_libraries = [
      'SAL',
      'SAL3',
      'SAL-NEWARK'
    ]

    config.ad_hoc_item_commentable_libraries = ['SAL-NEWARK', 'SPEC-COLL']
    config.item_commentable_libraries = ['SAL-NEWARK', 'SPEC-COLL']

    config.location_specific_pickup_libraries = {
      'PAGE-AR' => ['ART', 'SPEC-COLL'],
      'PAGE-AS' => ['ARS'],
      'PAGE-BI' => ['BIOLOGY'],
      'PAGE-BU' => ['BUSINESS'],
      'PAGE-CH' => ['CHEMCHMENG'],
      'PAGE-EA' => ['EAST-ASIA'],
      'HY-PAGE-EA' => ['EAST-ASIA'],
      'L-PAGE-EA'  => ['EAST-ASIA'],
      'PAGE-ED' => ['EDUCATION'],
      'PAGE-EN' => ['ENG'],
      'PAGE-ES' => ['EARTH-SCI'],
      'PAGE-GR' => ['GREEN'],
      'PAGE-HA' => ['HV-ARCHIVE'],
      'PAGE-HP' => ['GREEN', 'HOPKINS'],
      'PAGE-HV' => ['HOOVER'],
      'PAGE-IRON' => ['BUSINESS'],
      'PAGE-LP' => ['MUSIC', 'MEDIA-MTXT'],
      'PAGE-LW' => ['LAW'],
      'PAGE-MA' => ['MATH-CS'],
      'PAGE-MD' => ['MUSIC', 'MEDIA-MTXT'],
      'PAGE-MP' => ['EARTH-SCI'],
      'PAGE-MU' => ['MUSIC'],
      'PAGE-SP' => ['SPEC-COLL']
    }

    config.contact_info = {
      'SCAN' => {
        phone: '(650) 723-1493',
        email: 'scan-and-deliver@stanford.edu'
      },
      'HOOVER' => {
        phone: '(650) 723-2058',
        email: 'hoovercirc@stanford.edu'
      },
      'HV-ARCHIVE' => {
        phone: '(650) 723-3563',
        email: 'hooverarchives@stanford.edu'
      },
      'HOPKINS' => {
        phone: '(831) 655-6229',
        email: 'HMS-Library@lists.stanford.edu'
      },
      'PAGE-MP' => {
        phone: '(650) 723-2746',
        email: 'brannerlibrary@stanford.edu'
      },
      'SPEC-COLL' => {
        phone: '(650) 725-1022',
        email: 'specialcollections@stanford.edu'
      },
      'default' => {
        phone: '(650) 723-1493',
        email: 'greencirc@stanford.edu'
      }
    }

    config.symphony_success_codes = ['209', 'S001', 'P001', 'P001B', 'P002', 'P005']

    config.no_user_privs_codes = ['U003', 'U004']

    config.mediator_contact_info = {
      'HV-ARCHIVE' => { email: 'sul-requests-hoover-archive@lists.stanford.edu' },
      'HOOVER'     => { email: 'sul-requests-hoover-library@lists.stanford.edu' },
      'HOPKINS'    => { email: 'sul-requests-hopkins@lists.stanford.edu' },
      'PAGE-MP'    => { email: 'sul-requests-branner@lists.stanford.edu' },
      'SPEC-COLL'  => { email: 'sul-requests-spec@lists.stanford.edu' },
      'RUMSEYMAP'  => { email: 'sul-requests-rumsey@lists.stanford.edu' }
    }

    config.hours_api_location_map = {
      'ARS' => { library_slug: 'ars', location_slug: 'archive-recorded-sound' },
      'ART' => { library_slug: 'art', location_slug: 'library-circulation' },
      'BIOLOGY' => { library_slug: 'falconer', location_slug: 'library-circulation' },
      'BUSINESS' => { library_slug: 'business', location_slug: 'library-i-desk' },
      'CHEMCHMENG' => { library_slug: 'swain', location_slug: 'library-circulation' },
      'CLASSICS' => { library_slug: 'classics-library', location_slug: 'library-circulation' },
      'EARTH-SCI' => { library_slug: 'branner', location_slug: 'library-circulation' },
      'EAST-ASIA' => { library_slug: 'eal', location_slug: 'library-circulation' },
      'EDUCATION' => { library_slug: 'cubberley', location_slug: 'library-circulation' },
      'ENG' => { library_slug: 'englib', location_slug: 'library-circulation' },
      'GREEN' => { library_slug: 'green', location_slug: 'library-circulation' },
      'HOOVER' => { library_slug: 'hoover', location_slug: 'library-circulation' },
      'HOPKINS' => { library_slug: 'hopkins', location_slug: 'library-circulation' },
      'HV-ARCHIVE' => { library_slug: 'hila', location_slug: 'reference' },
      'LANE-MED' => { library_slug: 'lane', location_slug: 'library-circulation' },
      'LATHROP' => { library_slug: 'lathrop', location_slug: 'tech-lounge' },
      'LAW' => { library_slug: 'law', location_slug: 'library-circulation' },
      'MATH-CS' => { library_slug: 'mathstat', location_slug: 'library-circulation' },
      'MEDIA-MTXT' => { library_slug: 'green', location_slug: 'media-microtext-center' },
      'MUSIC' => { library_slug: 'music', location_slug: 'library-circulation' },
      'RUMSEYMAP' => { library_slug: 'Rumsey', location_slug: 'visitor-access' },
      'SAL' => { library_slug: 'sal12', location_slug: 'sal12-circulation' },
      'SAL3' => { library_slug: 'sal3', location_slug: 'operations' },
      'SAL-NEWARK' => { library_slug: 'newark', location_slug: 'operations' },
      'SPEC-COLL' => { library_slug: 'spc', location_slug: 'field-reading-room' },
      'TANNER' => { library_slug: 'philosophy', location_slug: 'library-circulation' }
    }

    config.illiad_nvtgc_map = {
      default: 'st2',
      'organization:law' => 'rcj',
      'organization:gsb' => 's7z'
    }
  end
end
