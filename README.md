[![Depfu](https://badges.depfu.com/badges/054347faa25f6d3a4d9e66535fd18763/overview.svg)](https://depfu.com/github/MITLibraries/thing?project=Bundler)
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

`JS_EXCEPTION_LOGGER_KEY` - set this to the value of the exception monitor
public post key to enable capturing javascript exceptions.

`LOG_LEVEL` - we set sane defaults in development or production, but you can
override easily with this ENV if you need to get more details.

`PREFERRED_DOMAIN` - set this to the domain you would like to to use. Any other
requests that come to the app will redirect to the root of this domain. This is
useful to prevent access to herokuapp.com domains as well as any legacy domains
you'd like to handle.

`RAILS_LOG_TO_STDOUT` - log to standard out instead of a file. Heroku enables
this automatically. It is often nice in development as well.

`SENTRY_DSN` - set to your project sentry key to enable exception logging

## ActiveStorage Configuration

### Development

`THESIS_ADMIN_EMAIL` - used for both `from` and `cc` of receipt emails.

### Production

The information necessary to identify a bucket on S3 is configured via this set
of variables:
`AWS_ACCESS_KEY_ID`
`AWS_REGION`
`AWS_S3_BUCKET`
`AWS_SECRET_ACCESS_KEY`

In addition, you will need to ensure the bucket CORS `AllowedOrigin` settings
are configured to allow for the domain this app runs at.

## User Roles

There are a few user roles that provide different levels of permissions. The
abilities of each role are defined in the [ability model](https://github.com/MITLibraries/thing/blob/master/app/models/ability.rb).

`Basic` is the default user role and is assigned when a user self creates an
account. Self creation is the only supported way to create an account. If we
have a new staff member, they first need to login to self create an account
with the basic role and then admin staff can assign them appropriate roles.

`Thesis Processor` is used for any users that process theses.

`Thesis Admin` can do everything a `Thesis Processor` can do but can also create
and update any thesis (not just their own like a `Basic` user).

The `Admin` flag can be assigned to a user with any role. `Admin` users can do
anything, including deleting or changing theses, modifying user roles, and
deleting users.

Assigning roles and the `Admin` flag is done in the web UI.

## Sending Receipt Email in Production

`SMTP_ADDRESS`
`SMTP_PASSWORD`
`SMTP_PORT`
`SMTP_USER`
`THESIS_ADMIN_EMAIL` - used for both `from` and `cc` of receipt emails.

In development, emails are written to a file in `tmp`. In testing, they are
stored in memory. You still need the `THESIS_ADMIN_EMAIL` set for the tmp file
to be written without errors.

On staging, the default is disabled email. Unset `DISABLE_ALL_EMAIL` if you
have a reason to turn them on. Due to the potential of unwanted emails being
sent when `FAKE_AUTH_ENABLED` is enabled (like on PR builds), it's best to
leave email off unless you are actively testing it. Staging and Production use
real authentication and are thus not a concern.

## Authentication for Development ONLY

There's a fake auth system you can use on review apps. It bypasses the actual auth system and just logs you in with a fake developer account.

### To enable on review apps
* Set `FAKE_AUTH_ENABLED` to `true`

### To enable on localhost
In `.env`:
* Set `FAKE_AUTH_ENABLED=true`

### To enable on staging or production
Don't.

Also, you shouldn't be able to. Even if you set `FAKE_AUTH_ENABLED`, the `HEROKU_APP_NAME` check will fail.

### To use in the codebase
Use `Rails.configuration.fake_auth_enabled`, NOT `ENV['FAKE_AUTH_ENABLED']`.

Using the latter bypasses the app name check, which can let us inadvertently turn on fake auth in production. `nope`

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

`URN_GIVEN_NAME` - `urn:oid:2.5.4.42` for MIT
`URN_SURNAME` - `urn:oid:2.5.4.4` for MIT
These have not been tried with testshib but there's a chance they're the same. These correspond to the `givenName` and `sn` fields in Shibboleth.

`URN_UID` - `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` should be good enough for both MIT and testshib. However, it is not guaranteed to be forever unique but MIT does not provide a truly unique option so this is the best we've got.

# Local deployment
Use heroku local. We have also experimented with docker, and are retaining it in case we move toward dockerizing all the things in future.

## Docker Setup

1. Build the docker image
    docker-compose build

2. Connect the database
    docker-compose up

3. Update default config/database.yml with PG configuration


4. Create the database and migrate (1st time)
    docker-compose run web rake db:create db:migrate


At the end of the above commands, you can visit http://localhost:3000 and see the welcome page.
