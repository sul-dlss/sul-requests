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

## Testing

The test suite (with RuboCop style inforcement) will be run with the default rake task (also run on travis)

    $ rake

The specs can be run without RuboCop enforcement

    $ rake spec

The RuboCop style enforcement can be run without running the tests

    $ rake rubocop
