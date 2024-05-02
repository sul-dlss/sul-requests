[![Build Status](https://github.com/sul-dlss/sul-requests/actions/workflows/ruby.yml/badge.svg)](https://github.com/sul-dlss/purl/actions/workflows/ruby.yml)

# Requests

A web application for requesting materials from the Stanford University Library.

## Features

- Request all materials from a single online form, regardless of home location.
- Support Scan & Deliver service for limited materials.
- Provide support for the Special Collections request process.
- Avoid known usability/accessibility issues with third-party request forms.
- Support administrative tasks, including request mediation and updating the paging schedule.
- Provide a mechanism for the general public (without an ILS account) to request items with just name and email, specifically to support government documents.

## Developing

### Requirements

- Ruby (tested on 3.2)
- Rails (tested on 7.0)
- a database (tested on sqlite3)

## Setup

Clone the repository:

```sh
git clone git@github.com:sul-dlss/sul-requests.git
```

Install dependencies:

```sh
bundle install
yarn install
```

Run database migrations:

```
bin/rails db:migrate
```

Run a development server:

```
bin/dev
```

The development server provides an authentication mechanism that allows you to use Shibboleth authentication by setting the `REMOTE_USER` environment variable to a SUNet ID. This will allow you to test the application as if you were logged in as that user:

```sh
REMOTE_USER=yoursunetid bin/dev
```

See below for configuration needed to tie your SUNet ID to the appropriate permissions for testing.

## Configuration

Configuration is handled via the [config](https://github.com/rubyconfig/config) gem. you can create a `config/settings/development.local.yml` file to use while developing, which will be ignored by git.

### Authorization

The `fake_ldap_attributes` setting ties SUNet IDs to a fake LDAP WorkGroup string:

```yml
fake_ldap_attributes:
  yoursunetid:
    eduPersonEntitlement: "sul:requests-super-admin"
```

The name of the workgroup can be anything you like. Once you set it, you can list it in the `super_admin_groups` setting so that your SUNet ID is associated with super admin privileges:

```yml
super_admin_groups: [sul:requests-super-admin]
```

When running with `REMOTE_USER` as detailed above, the application will now identify you as a super admin.

Several settings exist that govern the relationship between user workgroups in LDAP and permissions in the requests application:

- `super_admin_groups` is an array of LDAP workgroups that get all privileges in the application.
- `site_admin_groups` is an array of LDAP workgroups that have the ability to manage all requests and related objects in the application.
- `origin_admin_groups` has library codes configured with an array of LDAP workgroups that can manage requests originating from that library.
- `origin_location_admin_groups` has location codes configured with an array of LDAP workgroups that can manage requests originating from that location.
- `destination_admin_groups` has library codes configured with an array of LDAP workgroups that can manage requests being sent to that library.

### Token encryption

There is a token encryption library that handles encrypting and decrypting tokens given to users who only submit a Name/Email or Library ID for identification purposes.

```yml
token_encrypt:
  secret: ""
  salt: ""
```

To keep these tokens secure, we require a secret and a salt configured of moderate complexity and randomness (`SecureRandom.hex(128)` can be useful).

In development, these can be left alone, since they are set to empty strings by default. In production, they are controlled via `shared_configs`.

Once configured, these keys (or the tokens generated in the app) **MUST NOT** change, otherwise the tokens that users have been given will no longer be valid.

## Testing

The test suite (with RuboCop style enforcement) will be run with the default rake task (also run in CI):

```sh
rake
```

The tests can also be run without RuboCop enforcement:

```sh
rake spec
```

And RuboCop style enforcement can be run without running the tests:

```
rake rubocop
```

## Request lifecycle

The app is structured around the core `PatronRequest` model, which is saved to the database and later used to generate a request in the ILS or to an external system.

`PatronRequest`s begin life with a small amount of information about their subject, provided through query parameters: `instance_hrid`, and `origin_location_code`. These are sent to the application from a link generated in the SearchWorks catalog and correspond to values in the FOLIO ILS.

The `PatronRequest` is equipped to look up more information by querying the FOLIO ILS on its own behalf. This uses the [folio-graphql API](https://github.com/sul-dlss/folio-graphql) to retrieve detailed data on the patron and the items involved in the request.

At the end of its life, the `PatronRequest` will usually trigger a background job to hand off the request for further processing by the ILS or an external system like ILLiad. For some requests, the user is instead redirected to the system themselves to complete the process (e.g. Aeon).

## Making requests in development

When trying to create a particular type of request in development, you can start by using SearchWorks to find a record that will result in the desired type of request.

If you facet using the "Library" facet in combination with "At the library" in the "Access" facet, you can limit your results to items that are physically present at a particular library, like SAL3. When you visit the item's page, you can copy the link from the "Request" button to use as a starting point for creating a request in the development environment.

To find locations that have special rules active, you can run a local folio-graphql server and send a query that includes the location details:

```graphql
query LocationDetails {
  locations {
    code
    details {
      pageAeonSite
      pageMediationGroupKey
      pageServicePointCodes
      scanServicePointCodes
    }
  }
}
```

Another technique is to use the FOLIO web interface to find records. In the "Inventory" app, you can select "item" and facet by effective location, using the search box to find specific locations like "SAL3 Stacks". The "material type" and "item status" facets can also be useful for finding items with special request rules.

Once you find an appropriate item in a given location, you can get its parent instance and use that to construct a URL for creating a request in the development environment. The URL will include the instance HRID and the location code for the item(s) you want to request.

### Examples

#### Pickup/scan

These requests may be sent to the ILS or to ILLiad for fulfillment depending on the item, the user's affiliation, and the request type. Requests for items that are not available (checked out, lost, etc.) will generate hold/recall requests.

The ability to scan is controlled by the user's affiliation and the presence of a `scanServicePointCode` in the item's FOLIO location details. Items can additionally be restricted to certain material types by the `scan_destinations` configuration setting in this application.

Similarly, paging can be restricted to certain locations by the presence of `pageServicePointCodes`.

- [Scan or page from SAL3 to anywhere](http://localhost:3000/patron_requests/new?instance_hrid=13331339&origin_location_code=SAL3-STACKS)
- [Scan or page from SAL3 to anywhere; multiple items](http://localhost:3000/patron_requests/new?instance_hrid=5171263&origin_location_code=SAL3-STACKS)
- [Scan or page from SAL3 to anywhere; multiple items (one is aged to lost)](http://localhost:3000/patron_requests/new?instance_hrid=485717&origin_location_code=SAL3-STACKS)
- [Page from SAL3 to GREEN; multiple items](http://localhost:3000/patron_requests/new?instance_hrid=2028136&origin_location_code=SAL3-PAGE-GR)
- [Page from SAL3 to ART, MUSIC or SPEC](http://localhost:3000/patron_requests/new?instance_hrid=3310560&origin_location_code=SAL3-PAGE-FC)

#### Mediated page

These requests require a staff member to approve the request before it is sent to the ILS. They are controlled by the presence of a `pageMediationGroupKey` field in the FOLIO location details of the item, which specifies the staff group who can approve the request.

- [Mediated page from ART (locked stacks) to ART](http://localhost:3000/patron_requests/new?instance_hrid=14218863&origin_location_code=ART-LOCKED-LARGE)
- [Mediated page from SAL3 to EARTH-SCI](http://localhost:3000/patron_requests/new?instance_hrid=13949001&origin_location_code=SAL3-PAGE-MP)
- [Mediated page from EDU (locked stacks) to SPEC](http://localhost:3000/patron_requests/new?instance_hrid=5625544&origin_location_code=EDU-LOCKED)

#### Aeon

These requests are ultimately handled by the external Aeon system. They are controlled by the presence of a `pageAeonSite` field in the FOLIO location details of the item, which corresponds to a reading room code that is sent to Aeon along with the request details.

For items with finding aids, the user will first be redirected to the Online Archive of California page for the item, which includes a request button that will take them to Aeon to complete the request.

- [SPEC request via aeon](http://localhost:3000/patron_requests/new?instance_hrid=4103002&origin_location_code=SPEC-SAL3-U-ARCHIVES)
- [EAST-ASIA request via aeon](http://localhost:3000/patron_requests/new?instance_hrid=12062439&origin_location_code=EAL-LOCKED-OVERSIZE)
- [SPEC request via aeon; multiple items](http://localhost:3000/patron_requests/new?instance_hrid=11912879&origin_location_code=SPEC-SAL3-U-ARCHIVES)
- [SPEC request with finding aid via OAC](http://localhost:3000/patron_requests/new?instance_hrid=4086059&origin_location_code=SPEC-U-ARCHIVES)
