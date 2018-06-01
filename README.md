# Docker Migrate

This repo contains an environment for a Drupal 7 to Drupal 8 migration, using Docker4Drupal. It is an umbrella docker file that creates containers that create two docker sites, a new site for D8 and one for the existing D7 site. The `docker-compose.yml` contains basic settings that should work in most cases. See many other options on [Docker4Drupal](https://github.com/wodby/docker4drupal/blob/master/docker-compose.yml).

An .env file goes in the root of your repository. It is used for environment variables that you can pass into your containers. By changing variables in this file, you only have to change variables in one place and it will be picked up in your docker-compose file. `COMPOSE_PROJECT_NAME` is a special variable used by Docker that will set the prefix for the container names. It is also used in the docker-compose file to set the browser url so each project has its own url.

Do a git checkout of the repos for the D7 and D8 sites into d7 and d8 folders. The following file structure is expected:

- .env
- docker-compose.yml
- makefile
- docker-info
	- // D7 and D8 settings.local.php files.
	- // Empty db dump, updated later using Drush. 
- drush
	- // Drush aliases, including Drush 9 version. 
- d8
	- // Git checkout of the D8 site goes here, excluded from repo.
- d7
	- // Git checkout of the D7 site goes here, excluded from repo.

Note that this docker-compose configuration passes your ssh credentials and drush aliases into the container, which should be fine for working locally but may need to be adjusted if used in a public location. If your ssh keys are required, be sure to set the username you use on remote sites in your ssh config file, since the container won't use the correct username otherwise:

```
Host d7.com d8.com
  User karen
```

## Usage

Launch the container:

```
docker-compose up -d
```
Watch the logs to see when it is ready:

```
docker-compose logs -f
```

The containers are ready when you start to see messages like the following (exit the logs with ctl-c):

```
mailhog_1    | [APIv1] KEEPALIVE /api/v1/events
```

## Launch and Build

Once the containers are up and running, you can use commands in the makefile to build and update the sites.

```
make create
```
Visit the sites in a browser to see that they are working. The urls are based on the project name in the .env file, with ports identified in the docker-compose file. If the project name is 'lullabot', the browser addresses are:

```
http://lullabot7.docker.localhost:8000
http://lullabot8.docker.localhost:8000
```
Some browsers, like Chrome, will automatically handle any url that ends with `localhost`, otherwise you may have to add this to your hosts file. 

Run a migration using commands in the makefile:

```
make migrate
```
Other makefile commands:

```
# Update the D7 repo:
make updaterepo

# Update the D7 files:
make updatefiles

# Update the D7 database:
make updatedb
```

## Docker Commands

Pipe a drush command through the D8 php container (assuming Drupal is installed in /web):

```
docker-compose exec --user 82 php drush -r web
```

Pipe a drush command through the D7 php container (assuming Drupal is installed in /docroot):

```
docker-compose exec --user 82 php7 drush -r docroot
```

Execute mysql for the D8 site:

```
docker-compose exec --user 82 php mysql -udrupal -pdrupal -hmariadb
```

Execute mysql for the D7 site:

```
docker-compose exec --user 82 php7 mysql -udrupal -pdrupal -hmariadb7
```

See all the containers:

```
docker ps
```

Use portainer to manage containers in the browser:

```
http://portainer.lullabot.docker.localhost:8000
```

Start your containers in the background (detached):

```
docker-compose up -d
```

Stop your containers without destroying data:

```
docker-compose stop
```

Destroy containers and all their data volumes:

```
docker-compose down -v
```

Watch the logs (exit with ctl-c):

```
docker compose logs -f

```

For ease in use, create an alias for `docker-compose exec --user 82 ` in your bash_profile to avoid typing it over and over.



