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
#Docker Setup

1. Build the docker image
    docker-compose build
    
2. Connect the database
    docker-compose up

3. Update default config/database.yml with PG configuration
    
    
4. Create the database and migrate (1st time)
    docker-compose run web rake db:create db:migrate
    
    
At the end of the above commands, you can visit http://localhost:3000 and see the welcome page.