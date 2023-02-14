[![Depfu](https://badges.depfu.com/badges/054347faa25f6d3a4d9e66535fd18763/overview.svg)](https://depfu.com/github/MITLibraries/thing?project=Bundler)
[![Code Climate](https://codeclimate.com/github/MITLibraries/thing/badges/gpa.svg)](https://codeclimate.com/github/MITLibraries/thing)

# th(esis).ing(est)

This is a simple web app to collect metadata and files from a `User` and allow
`Users` with the role `Admin` to download and edit the metadata.

# Production: for real read this bit

This application is currently undergoing a major feature change. As such, the
production instance is represented by the `1.x` branch. If you need to fix a bug
in production, or update dependencies in production, please open a PR into the
`1.x` branch and not `main`.

New feature development is continuing in the `main` branch as normal.

When the new work enters production, we will delete the `1.x` branch and pretend
it never existed.

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

`PREFERRED_DOMAIN` - set this to the domain you would like to use. Any other
requests that come to the app will redirect to the root of this domain. This is
useful to prevent access to herokuapp.com domains as well as any legacy domains
you'd like to handle.

`RAILS_LOG_TO_STDOUT` - log to standard out instead of a file. Heroku enables
this automatically. It is often nice in development as well.

`SENTRY_DSN` - set to your project sentry key to enable exception logging
`SENTRY_ENV` - Sentry environment for the application. Defaults to 'unknown' if unset.

## ActiveStorage Configuration

### Development

`MAINTAINER_EMAIL` - used for `to` field of virus detected emails.
`ETD_APP_EMAIL` - used for `from` field of receipt emails.
`THESIS_ADMIN_EMAIL` - the email to which reports are sent.
`MAINTAINER_EMAIL` - used for `cc` field of report emails.
`SCOUT_DEV_TRACE` - include this and set it to `true` to enable perfomance monitoring in development. Very useful to
track down N+1 queries!
`SKIP_SLOW` - set this to skip tests flagged as slow
`SPEC_REPORTER` - set this to see a detailed list of tests and times during test runs

### Production

The information necessary to identify a bucket on S3 is configured via this set
of variables:
`AWS_ACCESS_KEY_ID`
`AWS_REGION`
`AWS_S3_BUCKET`
`AWS_SECRET_ACCESS_KEY`

In addition, you will need to ensure the bucket CORS `AllowedOrigin` settings
are configured to allow for the domain this app runs at.

## SQS Configuration

We use AWS SQS queues to publish theses to DSpace and read data about published theses from DSpace. The
[DSpace Submission Service](https://github.com/MITLibraries/dspace-submission-service) middleware supports this workflow.

`DSPACE_DOCTORAL_HANDLE` - The handle for the collection to use for depositing Doctoral theses.
`DSPACE_GRADUATE_HANDLE` - The handle for the collection to use for depositing Graduate theses.
`DSPACE_UNDERGRADUATE_HANDLE` - The handle for the collection to use for depositing Undergraduate theses.

`SQS_INPUT_QUEUE_URL` - The URL of the SQS input queue used for publication to DSpace.
`SQS_OUTPUT_QUEUE_NAME` - The name of the SQS output queue. This is used to build the SQS message attributes.
`SQS_OUTPUT_QUEUE_URL` - The URL of the SQS output queue used to read the results from a publication run.

`SQS_RESULT_MAX_MESSAGES`: Configures the :max_number_of_messages arg of the AWS poll method, which specifies how
many messages to receive with each polling attempt. Defaults to 10 if unset.
`SQS_RESULT_WAIT_TIME_SECONDS`: Configures the :wait_time_seconds arg of the AWS poll method, which enables long
polling by specifying a longer queue wait time. Defaults to 10 if unset.
`SQS_RESULT_IDLE_TIMEOUT`: Configures the :idle_timeout arg of the AWS poll method, which specifies the maximum time
in seconds to wait for a new message before the polling loop exists. Defaults to 0 if unset.

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

`SMTP_ADDRESS`, `SMTP_PASSWORD`, `SMTP_PORT`, `SMTP_USER` - all required to send mail.

`THESIS_ADMIN_EMAIL` - used for `from` field of receipt emails. Also the email to which reports are sent.

`MAINTAINER_EMAIL` - used for `cc` field of report emails.

`METADATA_ADMIN_EMAIL` - used for `to` field of MARC export report emails (see
[Metadata export workflow](#metadata-export-workflow)).

`DISABLE_ALL_EMAIL` - emails won't be sent unless this is set to `false`.

In development, emails are written to a file in `tmp`. In testing, they are
stored in memory. You still need the `THESIS_ADMIN_EMAIL` set for the tmp file
to be written without errors.

On staging, the default is disabled email. Set `DISABLE_ALL_EMAIL` to `false` if you
have a reason to turn them on. Due to the potential of unwanted emails being
sent when `FAKE_AUTH_ENABLED` is enabled (like on PR builds), it's best to
leave email off unless you are actively testing it. Staging and Production use
real authentication and are thus not a concern.

## Authentication for Development ONLY

There's a fake auth system you can use on review apps. It bypasses the actual auth system and just logs you in with a fake developer account.

### To enable on review apps

- Set `FAKE_AUTH_ENABLED` to `true`

### To enable on localhost

In `.env`:

- Set `FAKE_AUTH_ENABLED=true`

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

`URN_DISPLAY_NAME` - `urn:oid:2.16.840.1.113730.3.1.241` for MIT. Possibly
the same in testshib, but we haven't confirmed. This corresponds to the
`displayName` field in Shibboleth.

`URN_UID` - `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` should be good enough for both MIT and testshib. However, it is not guaranteed to be forever unique but MIT does not provide a truly unique option so this is the best we've got.

NOTE: There is a rake task to help debug responses from the IdP.

Example usage:

- grab a SAML response from a production or staging log
- remove all XML and quotes and put ONLY the raw encrypted SAML response into
  a single line of a text file. NOTE: the response likely spans multiple logger
  lines so you'll need to be careful to reconstruct this
- `rails debug:saml['tmp/your_saml_to_debug.txt']`

## Data Loading

There are three types of data that get loaded into this system:

### Database Seeds

These should only be loaded when the application database is initially set up (e.g. for new PR/development deploys or if the staging database needs to be destroyed and recreated). These seeds contain default values for certain tables such as copyrights, licenses, hold sources, and degree types.

The above seed data is loaded automatically during PR builds from Github. During local development it can be loaded during first deployment by running `rails db:seed`.

Additionally, degrees and departments can be manually seeded from a CSV file if desired by running `rails db:seed_degrees <csv_file_url>` and `rails db:seed_departments <csv_file_url>`, respectively. See Jira project documentation for link to a Google doc with the initial list of departments and degrees that were loaded into the production database (not maintained).

Seed data is not maintained to match the production database values, which can be changed by admin users as needed. The production database *shouldn't* ever need to be reseeded.

### QA/Stakeholder Testing Data

We're working on a process to load test data for stakeholder testing/QA in an automated fashion. Note this is different from fixture data used for automated tests. Check back soon for more info!

### Registrar Data

Thesis and author data for each term is loaded from a CSV file downloaded from the Registrar. This process is handled manually in the UI by the thesis processing team, and they have their own documentation on how they obtain the right data to load.

Loading registrar data may also add new degrees and departments, which are then manually updated and maintained by stakeholders.

Note: if registrar data needs to be loaded in a local, PR, or staging deployment it should be anonymized first to ensure no protected user data is added to a non-secure database. The test fixtures (test/fixtures/files) include both full and small sample files containing anonymized registrar data that can be used for this purpose.

## Publishing workflow

- stakeholders process theses until they are valid and accurate
- stakeholders choose theses to publish (Process theses - Select term - Select Publication Review - Publish)
- ETD will now automatically send data to DSS via the SQS queue
- DSS runs (as of this writing that is a manual process documented in the
  [DSS repo](https://github.com/MITLibraries/dspace-submission-service#run-stage))
- ETD processes output queue to update records and send email to stakeholders with summary data and list
  of any error records. As of now this is a manual process, but can be triggered via rake task using the
  Heroku run command such as:

  ```shell
  heroku run rails dss:process_output_queue --app TARGET-HEROKU-APP
  ```

### Publishing a single thesis

You can publish a single thesis that is already in `Publication review` status by passing the `thesis_id` to a rake task like:

```shell
heroku run rails dss:publish_thesis_by_id[THESIS_ID] --app TARGET-HEROKU-APP
```

## Preservation workflow

The publishing workflow will automatically trigger preservation for all of the published theses in the results queue.
At this point a submission information package is generated for each thesis, then a bag is constructed, zipped, and
streamed to an S3 bucket. (See the SubmissionInformationPackage and SubmissionInformationPackageZipper classes for more
details on this part of the process.)

Once they are in the S3 bucket, the bags are automatically replicated to the Digital Preservation S3 bucket, where they
can be ingested into Archivematica.

A thesis can be sent to preservation more than once. In order to track provenance across multiple preservation events,
we persist certain data about the SIP and audit the model using [paper_trail](https://github.com/paper-trail-gem/paper_trail).

### Preserving a single thesis

You can manually send a published thesis to preservation by passing the thesis ID to the following rake task:

```shell
heroku run rails preservation:preserve_thesis_by_id[THESIS_ID] --app TARGET-HEROKU-APP
```

## Metadata export workflow

The publishing workflow will automatically trigger a MARC export of all the published theses  in the results queue. The
generated marcxml file is zipped, attached to an email, and sent to the cataloging team (see [Sending Receipt Email in
Production](#sending-receipt-email-in-production)).

## ProQuest export workflow

Students have the option to agree to send their thesis and its metadata to ProQuest. If all authors of a thesis consent,
the thesis will be flagged for ProQuest export. Otherwise, the thesis will not be flagged for export.

This process differs for doctoral theses. We pay ProQuest to harvest metadata for doctoral theses regardless of the
thesis' ProQuest consent status. If the authors of a doctoral thesis provide conflicting responses, all authors decline,
or at least one author does not respond, then the thesis is flagged for 'partial harvest'. In this case, ProQuest will
harvest the thesis metadata *only*, not the thesis itself.

Processors can review all theses that are flagged for export in a dashboard. Once they have confirmed that the list is
correct, they initiate a job that generates a JSON report of all theses that have not yet been exported. The JSON
contains each thesis' DSpace handle and its export status (partial or full harvest). The processor then forwards this
JSON file to the ProQuest Dissertations and Theses team, who will harvest metadata -- and files, where applicable --
using the DSpace handles provided.

The same job that generates the JSON report also creates a CSV listing each 'partial harvest' thesis. This CSV is used
for budget reconciliation, and is sent to the ETD team in the same email as the JSON report.

Each export instantiates a ProquestExportBatch ActiveRecord object, to which the CSV and JSON files are attached using
ActiveStorage. Additionally, a ProquestExportBatch object is associated with all theses it exports. This allows us to
provide information about past export jobs as needed.

The ProQuest export workflow begins with the September 2022 degree period. All theses from prior degree periods are
excluded from export.

## Validation of thesis record

Prior to theses being published to external systems (such as the repository, or
a preservation system), a number of checks are performed to ensure that all
necessary information is present. These checks go beyond the built-in data
validations which are run by the `.valid?` method; more information can be found
by looking at the `evaluate_status` method on the Thesis model.

### Thesis fields

The following table lists the components of a Thesis record, including whether
each is required - and where that check is performed.

| Field              | Required? | Verified by        |
| ------------------ | --------- | ------------------ |
| ID                 | yes       | valid?             |
| Created_at         | yes       | valid?             |
| Updated_at         | yes       | valid?             |
| Title              | yes       | required_fields?   |
| Abstract           | sometimes | required_abstract? |
| Grad_date          | yes       | valid?             |
| Status             | yes       | valid?             |
| Processor_note     | no        |                    |
| Author_note        | no        |                    |
| Files_complete     | yes       | evaluate_status    |
| Metadata_complete  | yes       | evaluate_status    |
| Publication_status | yes       | valid?             |
| Coauthors          | no        |                    |
| Copyright_id       | yes       | required_fields?   |
| License_id         | sometimes | required_license?  |
| Dspace_handle      | no        |                    |
| Issues_found       | yes       | no_issues_found?   |

### Related records

| Record     | Required? | Verified by                                                                                                                                                                                                                 |
| ---------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Advisor    | yes       | advisors?                                                                                                                                                                                                                   |
| Author     | yes       | Two checks<br>- validations<br>- authors_graduated checks the graduated flag on each author record                                                                                                                          |
| Copyright  | yes       | copyright_id?                                                                                                                                                                                                               |
| Degree     | yes       | degrees?                                                                                                                                                                                                                    |
| Department | yes       | validations                                                                                                                                                                                                                 |
| File       | yes       | Three checks<br>- files? confirms that at least one file is attached<br>- file_have_purpose? confirms that each file has an assigned purpose<br>- one_thesis_pdf? confirms one-and-only-one file has a "thesis_pdf" purpose |
| Hold       | yes       | no_active_holds? confirms that no attached hold has an "active" or "expired" status<br>("released" holds are okay)                                                                                                          |
| License    | sometimes | required_license? checks who holds copyright and requires a license if that is the author                                                                                                                                   |

## Alternate file upload feedback

As a default behavior, the bulk file transfer form at `/transfer/new` uses the
browser's built-in file input field, with slight javascript decoration to
improve user feedback before and during file uploading.

However, there is an alternate behavior available. This alternate, which has yet
to be fully tested, can be accessed by appending any value for `upload` to the
querystring (i.e. `/transfer/new?upload=alternate`). This alternative offers
some additional capabilities via javascript decoration, such as appending to (or
pruning from) a pending bulk file transfer. The file uploading itself is
unaffected by this altenative.

## Resetting counter cache

We use counter caches to improve the application's performance. These commands should only need to be run at
most once in a given app to update counter columns on existing records. After that, the counters will update
automatically. If you suspect something has gone wrong with the counters, you can re-run them to ensure they are
accurate with no side effects other than the counters definitely being wrong for a few minutes as they recalculate.

These rake tasks should be updated as we add new counter cache columns.

### Thesis counter_cache

You can run the following rake task to update the counters:

```shell
heroku run rails cache:reset_thesis_counters --app TARGET-HEROKU-APP
```

### Transfer counter_cache

This is a non-standard counter_cache that needs to calculate counters based on Theses and not just Transfers.

```shell
heroku run rails cache:reset_transfer_counters --app TARGET-HEROKU-APP
```

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
