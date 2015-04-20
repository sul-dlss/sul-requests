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

    # Load all request types automatically
    config.autoload_paths += %W( #{config.root}/app/models/requests )

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

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
      'SAL' => 'SAL1&2 (on-campus shelving)',
      'SAL3' => 'SAL3 (off-campus storage)',
      'SAL-NEWARK' => 'SAL Newark (off-campus storage)',
      'SPEC-COLL' => 'Special Collections',
      'TANNER' => 'Philosophy Library (Tanner)'
    }
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

    config.library_specific_pickup_libraries = {
      'ARS' => ['ARS'],
      'HOOVER' => ['HOOVER'],
      'HV-ARCHIVE' => ['HV-ARCHIVE'],
      'SPEC-COLL' => ['SPEC-COLL']
    }

    config.location_specific_pickup_libraries = {
      'PAGE-AR' => ['ART', 'SPEC-COLL'],
      'PAGE-AS' => ['ARS'],
      'PAGE-BI' => ['BIOLOGY'],
      'PAGE-BU' => ['BUSINESS'],
      'PAGE-CH' => ['CHEMCHMENG'],
      'PAGE-EA' => ['EAST-ASIA'],
      'PAGE-ED' => ['EDUCATION'],
      'PAGE-EN' => ['ENG'],
      'PAGE-ES' => ['EARTH-SCI'],
      'PAGE-GR' => ['GREEN'],
      'PAGE-HA' => ['HV-ARCHIVE'],
      'PAGE-HL' => ['HOOVER'],
      'PAGE-HP' => ['GREEN', 'HOPKINS'],
      'PAGE-HV' => ['HOOVER'],
      'PAGE-IRON' => ['BUSINESS'],
      'PAGE-LAW' => ['LAW'],
      'PAGE-LP' => ['MUSIC', 'MEDIA-MTXT'],
      'PAGE-MA' => ['MATH-CS'],
      'PAGE-MD' => ['MUSIC', 'MEDIA-MTXT'],
      'PAGE-MP' => ['EARTH-SCI'],
      'PAGE-MSS' => ['SPEC-COLL'],
      'PAGE-MU' => ['MUSIC'],
      'PAGE-SL' => ['SAL'],
      'PAGE-SP' => ['SPEC-COLL']
    }
  end
end
