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
# Running as a Docker image

1. The default database configuration is for SQLLite; The docker image uses Postgres db
and hence before you build the image, update condig/database.yml with contents in config/database-pg.yml.postgres.

2. Build the docker image
    
        docker-compose build
    
3. Create the database and migrate (1st time)
       
       docker-compose run web rake db:create db:migrate
4. Start the container (If this is the first time, go to Step 4 and then come back here.)
       
           docker-compose up     
    
    
At the end of the above commands, you can visit https://localhost and see the main page.


# HTTPS Configuration

The application is configured to run on https and it uses a valid SSL cert issued by MIT. Requests on 80 are automatically forwarded
to SSL port 443. 

In order to enable SSL, Nginx is used as a proxy to service incoming requests even though the application is using [Puma](www.puma.io). The docker-compose.yml 
has the configurations and a brief explanation is as follows:

        version: '3'
        services:
          db:
            image: postgres
          app:
            build: .
            command: bundle exec rails s -p 3000 -b '0.0.0.0'
            volumes:
              - .:/thing
            ports:
              - "3000:3000"
            depends_on:
              - db
          nginx:
            image: nginx
            volumes:
              - ./nginx.conf:/etc/nginx/conf.d/default.conf
              - ./ssl/:/etc/nginx/certs/
            links:
              - app
            ports:
              - "80:80"
              - "443:443"
              

1. __version__:3 - This is indicating to use 3.0 of docker-compose specification. 
2. __services__ - This is the section that tells docker-compose which containers to start. In our case, there are 3 containers that would be 
started namely, app (thing web application), nginx (web server for https) and db (Pogstres database). The __volume__ section defines which host 
directory to be mounted on to the container. This is to enable access to local files from within the container. The __ports__ section defines
which ports are accessible from outside into the container. 