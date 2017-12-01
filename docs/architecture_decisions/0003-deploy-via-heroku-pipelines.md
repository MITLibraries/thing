# 3. Deploy via Heroku Pipelines

Date: 2017-12-01

## Status

Accepted

## Context

Initially this project was not appropriate for deploy on Heroku because it
needed MIT Touchstone authentication. However, based on
[ADR-0002 Authentication via Touchstone SAML](0002-authentication-via-touchstone-saml.md)
we are now able to remove the `mod_shib` requirement that initially prevented
us from using Heroku.

## Decision

We will use Heroku Pipelines for Staging / Production and PR builds.

## Consequences

We will have CI / CD for this application in an environment we have proven in
production on previous applications.
