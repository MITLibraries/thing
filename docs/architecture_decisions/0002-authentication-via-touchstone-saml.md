# 2. Authentication via Touchstone SAML

Date: 2017-12-01

## Status

Accepted

## Context

A mechanism for providing end-user authentication of MIT users is required for
core aspects of this application.

MIT officially only supports Shibboleth / Touchstone which traditionally is enabled via an Apache httpd module.

The [MIT OpenID Pilot](https://mitlibraries.github.io/oauth.html) was determined
unacceptable for this project.

In order to use Shibboleth we intended to containerize the application. However,
while that process ended in a successful proof-of-concept, it used SAML and not
mod_shib. Once we went down the path of not using the officially MIT supported
mod_shib solution, we felt using SAML in-app should be explored.

## Decision

We will use an in-app Touchstone SP using ruby-saml as documented in our
[Developer Documentation](https://mitlibraries.github.io/touchstone_saml.html).

## Consequences

Using an in-app SAML solution will allow us to focus on the software needs in
this project while we address future architecture needs in other projects that
may allow for containerized applications in the future.

We can now also deploy to Heroku and use our proven CI / CD solutions.
