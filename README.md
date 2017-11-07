[![Build Status](https://travis-ci.org/MITLibraries/thing.svg?branch=master)](https://travis-ci.org/MITLibraries/thing)
[![Dependency Status](https://gemnasium.com/badges/github.com/MITLibraries/thing.svg)](https://gemnasium.com/github.com/MITLibraries/thing)
[![Code Climate](https://codeclimate.com/github/MITLibraries/thing/badges/gpa.svg)](https://codeclimate.com/github/MITLibraries/thing)

# th(esis).ing(est)

This is a simple web app to collect metadata and files from a `User` and allow
`Users` with the role `Admin` to download and edit the metadata.

# Developer Notes

When changing the db schema, please run `bundle exec annotate` to update the
model and associated tests to reflect the changes in a nice convenient,
consistent way.



*********************************************************************************
# Docker Setup

1. The default database configuration is for SQLLite; The docker image uses Postgres db
and hence before you build the image, update condig/database.yml with contents in config/database-pg.yml.postgres.

2. Build the docker image
    
        docker-compose build
    
3. Create the database and migrate (1st time)
       
       docker-compose run web rake db:create db:migrate
4. Start the container (If this is the first time, go to Step 4 and then come back here.)
       
           docker-compose up     
    
    
At the end of the above commands, you can visit https://localhost and see the main page.