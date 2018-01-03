[![Build Status](https://travis-ci.org/MITLibraries/thing.svg?branch=master)](https://travis-ci.org/MITLibraries/thing)
[![Dependency Status](https://gemnasium.com/badges/github.com/MITLibraries/thing.svg)](https://gemnasium.com/github.com/MITLibraries/thing)
[![Code Climate](https://codeclimate.com/github/MITLibraries/thing/badges/gpa.svg)](https://codeclimate.com/github/MITLibraries/thing)

# th(esis).ing(est)

This is a simple web app to collect metadata and files from a `User` and allow
`Users` with the role `Admin` to download and edit the metadata.

# Architecture Decision Records

This repository contains Architecture Decision Records in the
[docs/architecture-decisions directory](docs/architecture_decisions).

[adr-tools](https://github.com/npryce/adr-tools) should allow easy creation of
additional records with a standardized template.

# Developer Notes

When changing the db schema, please run `bundle exec annotate` to update the
model and associated tests to reflect the changes in a nice convenient,
consistent way.

# Environment Variables

`DISABLE_LOGRAGE` - set this in to disable lograge single line logging config
and use rails standard verbose logging.

`RAILS_LOG_TO_STDOUT` - log to standard out instead of a file. Heroku enables
this automatically. It is often nice in development as well.

## Authentication for Development ONLY

`FAKE_AUTH_ENABLED` - set to `true`. WARNING: DO NOT DO THIS IN PRODUCTION! BAD!

## Authentication for production

For SAML authentication, you will need all of the following.

[DLE Docs on SAML](https://mitlibraries.github.io/touchstone_saml.html)

`IDP_METADATA_URL` - URL from which the IDP metadata can be obtained. This is
  loaded at application start to ensure it remains up to date.

`IDP_ENTITY_ID` - If `IDP_METADATA_URL` returns more than one IdP (like MIT
  does) entry, this setting signifies which IdP to use.

`IDP_SSO_URL` - the URL from the IdP metadata to use for authentication. I was
  unable to extract this directly from the metadata with the ruby-saml tool
  even though it for sure exists.

`SP_ENTITY_ID` - unique identifier to this application,
  ex: `https://example.com/shibboleth`

`SP_PRIVATE_KEY` - Base64 strict encoded version of the SP Private Key.
  note: Base64 is required due to multiline ENV being weird to deal with.

`SP_CERTIFICATE` - Base64 strict encoded version of the SP Certificate.
  note: Base64 is required due to multiline ENV being weird to deal with.

`URN_EMAIL` - URN to extract from SAML response. For MIT, `urn:oid:0.9.2342.19200300.100.1.3` for testshib `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` is close enough for testing.

`URN_NAME` - `urn:oid:2.16.840.1.113730.3.1.241` for MIT, `urn:oid:2.5.4.3` for testshib

`URN_UID` - `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` should be good enough for both MIT and testshib. However, it is not guaranteed to be forever unique but MIT does not provide a truly unique option so this is the best we've got.


*********************************************************************************
#Docker Setup

1. Build the docker image
    docker-compose build

2. Connect the database
    docker-compose up

3. Update default config/database.yml with PG configuration


4. Create the database and migrate (1st time)
    docker-compose run web rake db:create db:migrate


At the end of the above commands, you can visit http://localhost:3000 and see the welcome page.
