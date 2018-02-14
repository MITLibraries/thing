# 4. activestorage

Date: 2018-02-14

## Status

Accepted

## Context

One core feature of this application is to allow users to upload files. We will
be using AWS S3 as our storage backend due to our decision to deploy on
Heroku where there is no persistent local storage available.

There are various options to get files from the user to S3, but we need one in
which a user can upload directly and securely to an S3 bucket we
control so we don't have to stream the file through our server.

ActiveStorage is currently part of a Release Candidate version of Rails 5.2. It
is possible, though unlikely at this time, that before the final release
of Rails 5.2 the API will change enough that we will need to adjust our
implementation. It is also possible, but very unlikely, that Rails 5.2 will not
be released before we enter production with this product.

However, implementing ActiveStorage now will align us with the core Rails
community in what is likely to become the preferred solution for cloud storage
integration. It seems unlikely that non-integrated community solutions will
receive as much attention in the future if the core framework can provide what
most people need.

## Decision

We will use Rails
[ActiveStorage](http://edgeguides.rubyonrails.org/active_storage_overview.html)
to handle the uploading of files to S3 and linking the references to our data
models.

## Consequences

We will initially have a solution that is not as well documented or production
tested as we may prefer, but over time with likely community adoption it should
become the best option in Rails for handling cloud storage attachments.
