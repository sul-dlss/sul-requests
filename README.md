[![Build Status](https://travis-ci.org/sul-dlss/sul-requests.svg?branch=master)](https://travis-ci.org/sul-dlss/sul-requests)
[![Coverage Status](https://coveralls.io/repos/sul-dlss/sul-requests/badge.svg)](https://coveralls.io/r/sul-dlss/sul-requests)
[![Code Climate](https://codeclimate.com/github/sul-dlss/sul-requests/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/sul-requests)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/sul-requests/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/sul-requests/coverage)
[![Dependency Status](https://gemnasium.com/sul-dlss/sul-requests.svg)](https://gemnasium.com/sul-dlss/sul-requests)
[![Stories in Ready](https://badge.waffle.io/sul-dlss/sul-requests.png?label=ready&title=Ready)](https://waffle.io/sul-dlss/sul-requests)
[![Latest Tagged version](https://badge.fury.io/gh/sul-dlss%2Fsul-requests.svg)](https://badge.fury.io/gh/sul-dlss%2Fsul-requests)


# SUL Requests

SUL Requests in a rails application that allows users to request materials from the Stanford University Library.  This application aims to:

1. Support Scan & Deliver service for limited materials.
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
```
    origin_admin_groups:
      SAL-NEWARK: ['worgroup1', 'workgroup2']
```

#### Faking WorkGroups in Development

In order to develop the application it may be necessary to fake workgroups so that we don't need a local LDAP service.

* `fake_ldap_attributes` has SUNet IDs configured with a fake LDAP WorkGroup string

```
    fake_ldap_attributes:
      user_sunet:
        WEBAUTH_LDAPPRIVGROUP: 'some-set|of-workgroup-strings'
```

So your `config/settings/development.local.yml` file might look like:

```
fake_ldap_attributes:
  (your sunet id):
    WEBAUTH_LDAPPRIVGROUP: 'mine:mine'

super_admin_groups: ['mine:mine']
```

### Token Encryption

There is a token encryption library that handles encrypting and decrypting tokens given to users who only submit a Name/Email or Library ID for identification purposes. To keep these tokens secure we require a secret and a salt configured of moderate complexity and randomness (`SecureRandom.hex(128)` can be useful).  Once configured, these keys (or the tokens generated in the app) **MUST NOT** change, otherwise the tokens that users have been given will no longer be valid.

## Testing

The test suite (with RuboCop style enforcement) will be run with the default rake task (also run on travis)

    $ rake

The specs can be run without RuboCop enforcement

    $ rake spec

The RuboCop style enforcement can be run without running the tests

    $ rake rubocop


## How to create requests in local development

1.  Use SearchWorks to find appropriate records.

For example:
    Page:  find something at SAL3 using the "Library" facet and "At the Library" in the "Access" facet
    Scan:  ditto
    Mediated Page:  find something at Special Collections using the "Library" facet

2.  Open the "Request" button in SearchWorks in a new tab or new window.

3.  Copy the Request url after the host name and paste it after "localhost:3000" in your browser, when you have the app running locally.  (i.e. `/scan/...`  or `/mediated_page/...`)   Then submit the request in your browser pointed to your locally running app.
