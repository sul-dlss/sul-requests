[![Build Status](https://travis-ci.org/sul-dlss/sul-requests.svg?branch=master)](https://travis-ci.org/sul-dlss/sul-requests)
[![Coverage Status](https://coveralls.io/repos/sul-dlss/sul-requests/badge.svg)](https://coveralls.io/r/sul-dlss/sul-requests)
[![Dependency Status](https://gemnasium.com/sul-dlss/sul-requests.svg)](https://gemnasium.com/sul-dlss/sul-requests)
[![Stories in Ready](https://badge.waffle.io/sul-dlss/sul-requests.png?label=ready&title=Ready)](https://waffle.io/sul-dlss/sul-requests)


# SUL Requests

SUL Requests in a rails application that allows users to request materials from the Stanford University Library.  This application aims to:

1. Support Scan & Deliver service for limited materials. *Pilot project for a limited audience.*
2. Provide better support for the Special Collections request process. *Request all materials from a single online form, regardless of home location.*
3. Address known usability/accessibility issues with existing request forms.
4. Support necessary administrative tasks, including request mediation, updating the paging schedule, adding/removing requestable item categories.


## Requirements

1. Ruby (2.2.1 or greater)
2. Rails (4.2.0 or greater)
3. A database

## Installation

Clone the repository

    $ git clone git@github.com:sul-dlss/sul-requests.git

Change directories into the app and install dependencies

    $ bundle install

Run database migrations

    $ rake db:migrate

Start the development server

    $ rails s

## Configuring

Configuration is handled through the [RailsConfig](/railsconfig/rails_config) settings.yml files.

### WorkGroups

* `super_admin_groups` is an array of LDAP workgroups that get all privileges in the application.
* `site_admin_groups` is an array of LDAP workgroups that have the ability to manage all requests and related objects in the application.
* `origin_admin_groups` has library codes configured with an array of LDAP workgroups that can manage requests originating from that library.
* `destination_admin_groups` has library codes configured with an array of LDAP workgroups that can manage requests being sent to that library.


    origin_admin_groups:
      SAL-NEWARK: ['worgroup1', 'workgroup2']

#### Faking WorkGroups in Development

In order to develop the application it may be necessary to fake workgroups so that we don't need a local LDAP service.

* `fake_ldap_attributes` has SUNet IDs configured with a fake LDAP WorkGroup string


    fake_ldap_attributes:
      user_sunet:
        WEBAUTH_LDAPPRIVGROUP: 'some-set|of-workgroup-strings'

### Token Encryption

There is a token encryption library that handles encrypting and decrypting tokens given to users who only submit a Name/Email or Library ID for identification purposes. To keep these tokens secure we require a secret and a salt configured of moderate complexity and randomness (`SecureRandom.hex(128)` can be useful).  Once configured, these keys (or the tokens generated in the app) **MUST NOT** change, otherwise the tokens that users have been given will no longer be valid.

## Testing

The test suite (with RuboCop style inforcement) will be run with the default rake task (also run on travis)

    $ rake

The specs can be run without RuboCop enforcement

    $ rake spec

The RuboCop style enforcement can be run without running the tests

    $ rake rubocop
