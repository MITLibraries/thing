[![Depfu](https://badges.depfu.com/badges/054347faa25f6d3a4d9e66535fd18763/overview.svg)](https://depfu.com/github/MITLibraries/thing?project=Bundler)
[![Code Climate](https://codeclimate.com/github/MITLibraries/thing/badges/gpa.svg)](https://codeclimate.com/github/MITLibraries/thing)

# Electronic Thesis Deposit (ETD)

This application supports the Institute's thesis deposit, publication, and preservation workflows by providing the
following features:

* A registrar data importer to batch load thesis metadata for a given term;
* A form for students to add or edit metadata for their thesis;
* A batch file uploader for department admins to transfer thesis files for a given term;
* A processing dashboard for library staff to review thesis files and metadata;
* Automated workflows to publish theses to [DSpace@MIT](https://dspace.mit.edu/), prepare them for preservation in the
Institute's Archivematica instance, and export their metadata as MARC to be added to the library catalog.
* On-demand reporting for staff to review activity by term, publication status, and other criteria.

ETD evolved from an more narrowly focused application known as `thing (th(esis).ing(est))`, which collected metadata
and files via a form and allowed admin users to download them. This was part of MIT Libraries' previous thesis deposit
workflow. It has since been replaced with this fully electronic workflow, which requires less manual intervention.

## Architecture decision records (ADRs)

This repository contains ADRs in the
[docs/architecture-decisions directory](docs/architecture_decisions).

[adr-tools](https://github.com/npryce/adr-tools) should allow easy creation of
additional records with a standardized template.

## Developer notes

### Confirming functionality after updating dependencies

The application has excellent test coverage, and most errors are likely to be caught by our test suite. This runs in CI,
but it's good practice to run it locally after making updates:

`bin/rails test`

Updates to certain gems may require additional checks:

#### `administrate`

We generally do not test for the presence or appearance of UI elements, as such tests can be brittle. If you suspect
that a dependency update may affect the UI in some way, it's a good idea to review it more closely. This is most likely to occur with updates to the `administrate` gem, which we use
to manage the admin dashboards. We maintain some custom views (see `app/views/admin`) and fields (see `app/fields`) for
this gem that may need to be updated along with the gem. The `administrate` maintainers typically include a warning at
the top of the release notes if it will affect custom views, but it's a good idea to double-check the release notes
either way before updating this gem.

#### `paper_trail`

While `paper_trail` is covered in our test suite, audit trails are a crucial data in our application that cannot be 
backfilled, so updates to this gem may warrant some manual tests. Make sure that calling the `versions` method on an
object in a PT-enabled model (e.g., Thesis) returns the expected set of versions. You can create a new version by
updating the object. You may also want to confirm that the `whodunnit` value is equal to the ID of the user that made
the update.

#### `aws-sdk-rails`

Updates to `aws-sdk-rails` and related gems should prompt testing of the corresponding AWS feature. For example, if you
notice that `aws-sdk-sqs` is updated, you should confirm that SQS still works by running the publication workflow: first
publishing a thesis, then running
[DSpace Submission Service (DSS)](https://github.com/MITLibraries/dspace-submission-service) stage, and finally
processing the output queue.

If `aws-sdk-s3` is updated, try uploading a file with S3 configured and see if it works, and check existing files to see
if they're still there. You can test S3 in a PR build, or locally by adding the staging S3 config to your env.

#### `devise`

When updating `devise`, make sure that authentication via Touchstone works. You will need to do this in staging, as
Touchstone is not configured for PR builds. In the unlikely case that authentication fails in staging, you will need to
merge a subsequent commit with the previous version, so the broken version does not get deployed to production with
other changes.

### Annotating the database schema

When changing the db schema, please run `bundle exec annotate` to update the
model and associated tests to reflect the changes in a nice convenient,
consistent way.

### Local deployment

Use `bin/rails server` for local testing. If you need test data, you can
[pull the staging db](https://devcenter.heroku.com/articles/managing-heroku-postgres-using-cli#pg-push-and-pg-pull),
which contains fake records with no personally identifiable inofrmation. See `config/database.yml.postgres` for sample
postgres config.

## Environment variables

`DISABLE_LOGRAGE` - set this in to disable lograge single line logging config
and use rails standard verbose logging.

`JS_EXCEPTION_LOGGER_KEY` - set this to the value of the exception monitor
public post key to enable capturing javascript exceptions.

`LOG_LEVEL` - we set sane defaults in development or production, but you can
override easily with this ENV if you need to get more details.

`MAINTENANCE_MODE` - this toggles a [Flipflop feature](https://github.com/voormedia/flipflop) that disables thesis
transfers and informs transfer submitters that the application is under maintenance.
`MAINTENANCE_MESSAGE_TRANSFER` - provides a custom message to transfer submitters if more details are necessary.

`PLATFORM_NAME`: The value set is added to the header after the MIT Libraries logo. The logic and CSS for this comes from our theme gem.

`PREFERRED_DOMAIN` - set this to the domain you would like to use. Any other
requests that come to the app will redirect to the root of this domain. This is
useful to prevent access to herokuapp.com domains as well as any legacy domains
you'd like to handle.

`RAILS_LOG_TO_STDOUT` - log to standard out instead of a file. Heroku enables
this automatically. It is often nice in development as well.

`SENTRY_DSN` - set to your project sentry key to enable exception logging
`SENTRY_ENV` - Sentry environment for the application. Defaults to 'unknown' if unset.

### ActiveStorage configuration

#### Development

`MAINTAINER_EMAIL` - used for `to` field of virus detected emails.
`ETD_APP_EMAIL` - used for `from` field of receipt emails.
`THESIS_ADMIN_EMAIL` - the email to which reports are sent.
`MAINTAINER_EMAIL` - used for `cc` field of report emails.
`SCOUT_DEV_TRACE` - include this and set it to `true` to enable perfomance monitoring in development. Very useful to
track down N+1 queries!
`SKIP_SLOW` - set this to skip tests flagged as slow
`SPEC_REPORTER` - set this to see a detailed list of tests and times during test runs

#### Production

The information necessary to identify a bucket on S3 is configured via this set
of variables:

`AWS_ACCESS_KEY_ID`
`AWS_REGION`
`AWS_S3_BUCKET`
`AWS_SECRET_ACCESS_KEY`

In addition, you will need to ensure the bucket CORS `AllowedOrigin` settings
are configured to allow for the domain this app runs at.

### SQS configuration

We use AWS SQS queues to publish theses to DSpace and read data about published theses from DSpace. The
[DSpace Submission Service](https://github.com/MITLibraries/dspace-submission-service) middleware supports this workflow.

`DSPACE_DOCTORAL_HANDLE` - The handle for the collection to use for depositing Doctoral theses.
`DSPACE_GRADUATE_HANDLE` - The handle for the collection to use for depositing Graduate theses.
`DSPACE_UNDERGRADUATE_HANDLE` - The handle for the collection to use for depositing Undergraduate theses.

`SQS_INPUT_QUEUE_URL` - The URL of the SQS input queue used for publication to DSpace.
`SQS_OUTPUT_QUEUE_NAME` - The name of the SQS output queue. This is used to build the SQS message attributes.
`SQS_OUTPUT_QUEUE_URL` - The URL of the SQS output queue used to read the results from a publication run.

`SQS_RESULT_MAX_MESSAGES` - Configures the :max_number_of_messages arg of the AWS poll method, which specifies how
many messages to receive with each polling attempt. Defaults to 10 if unset.
`SQS_RESULT_WAIT_TIME_SECONDS` - Configures the :wait_time_seconds arg of the AWS poll method, which enables long
polling by specifying a longer queue wait time. Defaults to 10 if unset.
`SQS_RESULT_IDLE_TIMEOUT` - Configures the :idle_timeout arg of the AWS poll method, which specifies the maximum time
in seconds to wait for a new message before the polling loop exists. Defaults to 0 if unset.

### Archival Packaging Tool (APT) configuration

The following enviroment variables are needed to communicate with [APT](https://github.com/MITLibraries/archival-packaging-tool), which is used in the
[preservation workflow](#publishing-workflow).

`APT_CHALLENGE_SECRET` - Secret value used to authenticate requests to the APT Lambda endpoint.
`APT_VERBOSE` - If set to `true`, enables verbose logging for APT requests.
`APT_CHECKSUMS_TO_GENERATE` - Array of checksum algorithms to generate for files (default: ['md5']).
`APT_COMPRESS_ZIP` - Boolean value to indicate whether the output bag should be compressed as a zip
file (default: true).
`APT_S3_BUCKET` - S3 bucket URI where APT output bags are stored.
`APT_LAMBDA_URL` - The URL of the APT Lambda endpoint for preservation requests.

### Email configuration

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

### Authentication configuration

#### Authentication for development

There's a fake auth system you can use on review apps. It bypasses the actual auth system and just logs you in with a fake developer account.

##### To enable on review apps

- Set `FAKE_AUTH_ENABLED` to `true`

##### To enable on localhost

In `.env`:

- Set `FAKE_AUTH_ENABLED=true`

##### To enable on staging or production

Don't.

Also, you shouldn't be able to. Even if you set `FAKE_AUTH_ENABLED`, the `HEROKU_APP_NAME` check will fail.

##### To use in the codebase

Use `Rails.configuration.fake_auth_enabled`, NOT `ENV['FAKE_AUTH_ENABLED']`.

Using the latter bypasses the app name check, which can let us inadvertently turn on fake auth in production. `nope`

#### Authentication for production

For SAML authentication, you will need all of the following.

[DLS docs on SAML](https://mitlibraries.github.io/guides/authentication/touchstone_saml.html)

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

## User roles

There are a few user roles that provide different levels of permissions. The
abilities of each role are defined in the [ability model](https://github.com/MITLibraries/thing/blob/master/app/models/ability.rb).

`Basic` is the default user role and is assigned when a user self creates an
account. Self creation is the only supported way to create an account. If we
have a new staff member, they first need to login to self create an account
with the basic role and then admin staff can assign them appropriate roles.

`Thesis Processor` is assigned to a user that processes theses. This role is not currently used, however, as our thesis
processors need a higher level of permissions than it offers. We have retained this role for potential future use (e.g.,
if we have multiple processors, and some don't need the full set of permissions).

`Transfer Submitter` is assigned to users that transfers thesis files (typically department admins). Stakeholders are
responsible for assigning this role.

`Thesis Admin` can do everything a `Thesis Processor` can do but can also create
and update any thesis (not just their own like a `Basic` user).

Roles and the `Admin` flag can be assigned in the Users administrate dashboard in the web UI.

## Audit trail

We use the [`paper_trail`](https://github.com/paper-trail-gem/paper_trail) gem to maintain audit trails of certain
objects. Classes with `paper_trail` enabled include Thesis, ArchivematicaAccession, and Hold.

Following maintainer recommendations, we chose to migrate our `paper_trail` data from YAML to JSON. In YAML, enum fields
were stored as integers and mapped to their string values as part of the deserialization process. After migrating to
JSON, new enums are correctly stored as their mapped string values, but legacy data is still stored in the database
as integers.

After consulting with stakeholders, we decided to leave the legacy data as is and map the enums in the UI,
so as to avoid altering the audit trail. This only affects the hold status field in the Hold table, as that is the only
enum field under `paper_trail` that we render in a view (see `app/views/hold_status`).

## Data loading

There are three types of data that get loaded into this system.

### Database seeds

These should only be loaded when the application database is initially set up (e.g. for new PR/development deploys or if
the staging database needs to be destroyed and recreated). These seeds contain default values for certain tables such as
copyrights, licenses, hold sources, and degree types.

The above seed data is loaded automatically during PR builds from Github. During local development it can be loaded
during first deployment by running `rails db:seed`.

Additionally, degrees and departments can be manually seeded from a CSV file if desired by running
`rails db:seed_degrees <csv_file_url>` and `rails db:seed_departments <csv_file_url>`, respectively. See Jira project
documentation for link to a Google doc with the initial list of departments and degrees that were loaded into the
production database (not maintained).

Seed data is not maintained to match the production database values, which can be changed by admin users as needed. *Do
not ever reseed the production database.*

### QA/Stakeholder testing data

Currently, most stakeholder testing occurs in staging after a feature has been merged, as staging contains test data.
We're in need of atuomated process to load test data to PR builds for stakeholder testing/QA. (Note this is different
from fixture data used for automated tests.) This would make it easier to keep the `main` branch deployable while
multiple features are in QA, and it may help with testing and QA in staging, where records can quickly become invalid
as the data model changs.

### Registrar data

Thesis and author data for each term is loaded from a CSV file downloaded from the Registrar. This process is handled
manually in the UI by the thesis processing team, and they have their own documentation on how they obtain the right
data to load.

Loading registrar data may also add new degrees, departments, degree periods, which are then manually updated and
maintained by stakeholders.

Note: if registrar data needs to be loaded in a local, PR, or staging deployment it should be anonymized first to ensure
no protected user data is added to a non-secure database. The test fixtures (test/fixtures/files) include both full and
small sample files containing anonymized registrar data that can be used for this purpose.

## Processing workflow

Processors review thesis metadata each term to ensure that all necessary files and metadata are present and accurate.
In addition to fields on the Thesis model, this also includes relevant data from the Author, Degree, Copyright, License,
Hold, and ArchivematicaAccession models. When all [validations are satisfied](#validations), thesis processors can begin
the [publishing workflow](#publishing-workflow)

The ArchivematicaAccession model is unique in that it is not directly related to the Thesis model. We first designed
this application under the assumption that the notion of degree periods would not be shared across the data model.
However, as the application expanded, we found that this logic was duplicated in multiple places (e.g., the Transfer
model). When the need emerged to add an ArchivematicaAccession model to assign accession numbers to theses, we corrected
this by adding a DegreePeriod model that `has_one` ArchivematicaAccession.

We plan to abstract the duplicative degree period logic to the DegreePeriod model, but this is a substantial refactor
that will require careful planning and execution. In the meantime, a Thesis is not directly associated with an
ArchivematicaAccession, but instead looks it up based on the DegreePeriod that corresponds with the thesis`
graduation date.

New degree periods are generated for each subsequent term from [registrar data uploads](#registrar-data), at which point
processors must create a corresponding Archivematica accession number.

## Publishing workflow

1. Following the processing workflow, stakeholders choose a term to publish (Process theses - Select term - Select
Publication Review - Publish)
2. ETD will now automatically send data to DSS via the SQS queue
3. DSS runs (as of this writing that is a manual process documented in the
  [DSS repo](https://github.com/MITLibraries/dspace-submission-service#run-stage))
4. ETD processes output queue to update records and send email to stakeholders with summary data and list
  of any error records. As of now this is a manual process, but can be triggered via rake task using the following
  sequence of heroku-cli commands:

  ```shell
  # scale the worker dyno to ensure we have enough memory
  # as off Aug 2024 `performance-m` has been sufficient
  heroku ps:scale worker=1:performance-m --app TARGET-HEROKU-APP

  # run the output queue processing job
  heroku run -s performance-m rails dss:process_output_queue --app TARGET-HEROKU-APP

  # wait for all ETD emails to be received (there are three emails: one overall results summary, one preservation
  # results summary, and one MARC batch export).
  # Then, scale the worker back down so we do not pay for more CPU/memory than we need
  heroku ps:scale worker=1:standard-1x --app TARGET-HEROKU-APP
  ```

Note the `-s` option on the second command, which sets the dyno size for the run command. We are scaling to the larger '2X' dyno because this job is very memory-intensive. We also first scale the worker dyno to 2x and then set it back to 1x when we are done for the same reason (preservation takes a lot of memory).

### Publishing a single thesis

You can publish a single thesis that is already in `Publication review` or `Pending publication` status by passing the `thesis_id` to a rake
task:

```shell
heroku run -s standard-2x rails dss:publish_thesis_by_id[THESIS_ID] --app TARGET-HEROKU-APP
```

Note: `Pending publication` is allowed here, but not expected to be a normal occurence, to handle the edge case of the app thinking data was sent to SQS but the data not arriving for any reason.

## Preservation workflow

The publishing workflow will automatically trigger preservation for all of the published theses in the results queue.

At this point, the preservation job will generate an Archivematica payload for each thesis, which
are then POSTed to [APT](https://github.com/MITLibraries/archival-packaging-tool) for further processing. Each payload includes a metadata CSV and a JSON object containing structural information about the thesis files. 

Once the payloads are sent to APT, each thesis is structured as a BagIt bag and saved to an S3
bucket, where they can be ingested into Archivematica.

A thesis can be sent to preservation more than once. In order to track provenance across multiple preservation events, we persist certain data about the Archivematica payload and audit the model
using `paper_trail`.

### Preserving a single thesis

You can manually send a published thesis to preservation by passing the thesis ID to the following rake task:

```shell
heroku run rails preservation:preserve_thesis_by_id[THESIS_ID] --app TARGET-HEROKU-APP
```

## Metadata export workflow

The publishing workflow will automatically trigger a MARC export of all the published theses in the results queue. The
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

## Validation of thesis records

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

| Record           | Required? | Verified by |
| ---------------- | --------- | ----------- |
| Advisor          | yes       | advisors? |
| Author           | yes       | Two checks:<br>- validations<br>- authors_graduated checks the graduated flag on each author record |
| Copyright        | yes       | copyright_id? |
| Degree           | yes       | `degrees?` and `degrees_have_types?` |
| Department       | yes       | validations and `departments_have_dspace_name?` |
| File             | yes       | Four checks:<br>- files? confirms that at least one file is attached<br>-file_have_purpose? confirms that each file has an assigned purpose<br>- one_thesis_pdf? confirms one-and-only-one file has a "thesis_pdf" purpose<br>- `unique_filenames?(self)` confirms that no duplicate filenames exist within a thesis |
| Hold             | yes       | no_active_holds? confirms that no attached hold has an "active" or "expired" status<br>("released" holds are okay) |
| License          | sometimes | required_license? checks who holds copyright and requires a license if that is the author |
| Accession number | yes       | `accession_number.present?` |

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
