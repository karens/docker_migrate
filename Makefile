#===========================================
# VARIABLES
#===========================================
# Parent paths
BASE_PROJECT_NAME=lullabot
PROJECT_NAME=${BASE_PROJECT_NAME}8
PROJECT_NAME7=${BASE_PROJECT_NAME}7
PROJECT_PATH=web
PROJECT_PATH7=docroot
CURRENT_DIR=$(shell pwd)
PARENT_ROOT=${CURRENT_DIR}/d8/${PROJECT_PATH}
PARENT_ROOT7=${CURRENT_DIR}/d7/${PROJECT_PATH7}
DOCKER_DIR=docker-info

# Container paths
CONTAINER_ROOT=/var/www/html
DRUPAL_ROOT=${CONTAINER_ROOT}/${PROJECT_PATH}
DRUPAL_ROOT7=${CONTAINER_ROOT}/${PROJECT_PATH7}
SITES_DIR=sites/default
FILES_DIR=${SITES_DIR}/files
CONFIG_DIR=${SITES_DIR}/files/sync

# Source data
SOURCE7=http://edit.lullabot.com/
DRUSH_ALIAS7=@lullabot.dev
SETTINGS=${PARENT_ROOT}/${SITES_DIR}/settings.php
SETTINGS7=${PARENT_ROOT7}/${SITES_DIR}/settings.php
SETTINGS_LOCAL=${DOCKER_DIR}/settings.docker.local.php
SETTINGS_LOCAL7=${DOCKER_DIR}/settings.docker.local7.php

# Command shortcuts.
DRUSH=docker-compose exec --user 82 php drush -r ${DRUPAL_ROOT}
EXEC=docker exec --user 82 ${BASE_PROJECT_NAME}_php_1 
ENTER=docker exec -it ${BASE_PROJECT_NAME}_php_1 /bin/bash

DRUSH7=docker-compose exec --user 82 php7 drush -r ${DRUPAL_ROOT7}
EXEC7=docker exec --user 82 ${BASE_PROJECT_NAME}_php7_1 
ENTER7=docker exec -it ${BASE_PROJECT_NAME}_php7_1 /bin/bash

#===========================================
# COMMANDS
#===========================================
# Run if drush aliases have not yet been converted to Drush 9 format.
aliasup:
	${DRUSH} site:alias-convert

# Run if parent repo has not already been created.
createrepo:
	touch .env
	echo "COMPOSER_PROJECT_NAME=${BASE_PROJECT_NAME}" >> .env
	mkdir d7
	mkdir d8

# Set up D8 site
# Run when creating parent repository. If these changes are not committed to
# D8 repository, run each time containers are created.
initialize:
	if [ ! -f ${SETTINGS} ]; then cp ${PARENT_ROOT}/${SITES_DIR}/default.settings.php ${SETTINGS}; fi;
	chmod 777 ${SETTINGS}
	echo "\$$local_settings = __DIR__ . '/settings.docker.local.php';\nif (file_exists(\$$local_settings) && !empty(\$$_SERVER['WODBY_DIR_FILES'])) {\n  include \$$local_settings;\n}" >> ${SETTINGS}
	chmod 444 ${SETTINGS}
	cp ${SETTINGS_LOCAL} ${PARENT_ROOT}/${SITES_DIR}/settings.docker.local.php
	if [ ! -d ${PARENT_ROOT}/${FILES_DIR} ]; then mkdir -p ${PARENT_ROOT}/${FILES_DIR}; fi;
	chmod -R g+w ${PARENT_ROOT}/${FILES_DIR}
	chmod 2775 ${PARENT_ROOT}/${FILES_DIR}
	# Druah 9-style alias
	if [ ! -d ${CURRENT_DIR}/d8/drush ]; then mkdir ${CURRENT_DIR}/d8/drush; fi;
	if [ ! -d ${CURRENT_DIR}/d8/drush/sites ]; then mkdir ${CURRENT_DIR}/d8/drush/sites; fi;
	cp ${CURRENT_DIR}/drush/sites/docker.site.yml ${CURRENT_DIR}/d8/drush/sites/docker.site.yml

# Set up D7 site
# Run when creating parent repository. If these changes are not committed to
# D7 repository, run each time containers are created.
initialize7:
	if [ ! -f ${SETTINGS7} ]; then cp ${PARENT_ROOT7}/${SITES_DIR}/default.settings.php ${SETTINGS7}; fi;
	cp ${SETTINGS_LOCAL7} ${PARENT_ROOT7}/${SITES_DIR}/settings.docker.local.php
	chmod 777 ${SETTINGS7}
	echo "\$$local_settings = __DIR__ . '/settings.docker.local.php';\nif (file_exists(\$$local_settings) && !empty(\$$_SERVER['WODBY_DIR_FILES'])) {\n  include \$$local_settings;\n}" >> ${SETTINGS7}
	chmod 444 ${SETTINGS7}
	if [ ! -d ${PARENT_ROOT7}/${FILES_DIR} ]; then mkdir -p ${PARENT_ROOT7}/${FILES_DIR}; fi;
	chmod -R g+w ${PARENT_ROOT7}/${FILES_DIR}
	chmod 2775 ${PARENT_ROOT7}/${FILES_DIR}
	# Drush 8-style alias
	if [ ! -d ${CURRENT_DIR}/d7/drush ]; then mkdir ${CURRENT_DIR}/d7/drush; fi;
	if [ ! -d ${CURRENT_DIR}/d7/drush/site-aliases ]; then mkdir ${CURRENT_DIR}/d7/drush/site-aliases; fi;
	cp ${CURRENT_DIR}/drush/site-aliases/docker7.aliases.drushrc.php ${CURRENT_DIR}/d7/drush/site-aliases/docker7.aliases.drushrc.php

# Create empty D8 site from stored configuration.
# Assumes drupal/config_installer is included in the D8 composer.json and
# that a basic site install was done, modules enabled, etc before saving config.
install:
	composer install -d=${CURRENT_DIR}/d8
	${DRUSH} si --verbose config_installer config_installer_sync_configure_form.sync_directory=${CONFIG_DIR} --yes

# Initial setup of D8 site
modules:
	${DRUSH} en media ctools entity_browser entity_reference_revisions paragraphs field_group htmlpurifier markdown migrate migrate_drupal migrate_plus migrate_tools migrate_upgrade pathauto token tzfield -y
	${DRUSH} pm-uninstall automated_cron rdf quick_edit comment -y

# Adjustments needed to make the D8 site usable locally.
localize:
	${DRUSH} user:password admin admin

# Store configuration
storeconfig:
	${DRUSH} cex

# Run as needed.
updatedb7:
	${DRUSH7} sql-sync ${DRUSH_ALIAS7} @docker7.docker -y
	${DRUSH7} updb -y
	${DRUSH7} cc all

# Run as needed.
updatefiles7:
	${DRUSH7} rsync ${DRUSH_ALIAS7}:%files/ @docker7.docker:%files -y
	${DRUSH7} cc all

# Adjustments needed to make the D7 site usable locally.
localize7:
	${DRUSH7} upwd admin --password=admin
	${DRUSH7} pm-disable lullabot_edit_exporter -y
	${DRUSH7} en field_ui views_ui -y

# Run as needed.
update:
	${DRUSH} cache-rebuild
	${DRUSH} updb -y

# Run as needed.
migrateconfig:
	${DRUSH} en media -y
	${DRUSH} migrate-upgrade --legacy-db-key="drupal_7" --legacy-root="${SOURCE7}" --configure-only
	${DRUSH} ms

# Run as needed.
migrate:
	${DRUSH} ms
	${DRUSH} migrate:import --all
	${DRUSH} ms

# Start the containers and watch the logs to see when they're ready.
# Exit logs with ctl-c.
start:
	docker-compose up -d
	docker-compose logs -f
 
# Stop the containers without destroying data. 
stop:
	docker-compose stop
 
# Stop the containers and destroy all the data.
destroy:
	docker-compose down -v

# Stop the containers and destroy all the data.
dockerclean:
	docker system prune

# Shortcuts
create: initialize install localize initialize7 localize7
update7: updatedb7 localize7 updatefiles7

