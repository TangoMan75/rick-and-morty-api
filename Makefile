## Rick and Morty
##
## This is the main entrypoint for RickAndMortyApi project 
##
## @version 1.0.0
## @author  "Matthias Morin" <mat@tangoman.io>
## @license MIT
## @link    https://github.com/TangoMan75/rick-and-morty

.PHONY: help export_data import_data scrape install uninstall requirements rm_env set_env lint lint_fix tests tests_functional tests_integration tests_unit coverage security reset_db create_db drop fixtures migrate migration_diff schema generate_schema serve version build network network_remove open start stop up cache generate_app_secret self_install self_uninstall

##################################################
## Colors
##################################################

_PRIMARY   = \033[97m
_SECONDARY = \033[94m
_SUCCESS   = \033[32m
_DANGER    = \033[31m
_WARNING   = \033[33m
_INFO      = \033[95m
_DEFAULT   = \033[0m
_EOL       = \033[0m\n

_ALERT_PRIMARY   = \033[1;104;97m
_ALERT_SECONDARY = \033[1;45;97m
_ALERT_SUCCESS   = \033[1;42;97m
_ALERT_DANGER    = \033[1;41;97m
_ALERT_WARNING   = \033[1;43;97m
_ALERT_INFO      = \033[1;44;97m

##################################################
## Color Functions
##################################################

define _echo_primary
	@printf "${_PRIMARY}%b${_EOL}" $(1)
endef
define _echo_secondary
	@printf "${_SECONDARY}%b${_EOL}" $(1)
endef
define _echo_success
	@printf "${_SUCCESS}%b${_EOL}" $(1)
endef
define _echo_danger
	@printf "${_DANGER}%b${_EOL}" $(1)
endef
define _echo_warning
	@printf "${_WARNING}%b${_EOL}" $(1)
endef
define _echo_info
	@printf "${_INFO}%b${_EOL}" $(1)
endef

define _alert_primary
	@printf "${_EOL}${_ALERT_PRIMARY}%64s${_EOL}${_ALERT_PRIMARY} %-63s${_EOL}${_ALERT_PRIMARY}%64s${_EOL}\n" "" $(1) ""
endef
define _alert_secondary
	@printf "${_EOL}${_ALERT_SECONDARY}%64s${_EOL}${_ALERT_SECONDARY} %-63s${_EOL}${_ALERT_SECONDARY}%64s${_EOL}\n" "" $(1) ""
endef
define _alert_success
	@printf "${_EOL}${_ALERT_SUCCESS}%64s${_EOL}${_ALERT_SUCCESS} %-63s${_EOL}${_ALERT_SUCCESS}%64s${_EOL}\n" "" $(1) ""
endef
define _alert_danger
	@printf "${_EOL}${_ALERT_DANGER}%64s${_EOL}${_ALERT_DANGER} %-63s${_EOL}${_ALERT_DANGER}%64s${_EOL}\n" "" $(1) ""
endef
define _alert_warning
	@printf "${_EOL}${_ALERT_WARNING}%64s${_EOL}${_ALERT_WARNING} %-63s${_EOL}${_ALERT_WARNING}%64s${_EOL}\n" "" $(1) ""
endef
define _alert_info
	@printf "${_EOL}${_ALERT_INFO}%64s${_EOL}${_ALERT_INFO} %-63s${_EOL}${_ALERT_INFO}%64s${_EOL}\n" "" $(1) ""
endef

##################################################
## Help
##################################################

## Print this help
help:
	$(call _alert_primary, "Rick and Morty")

	@printf "${_WARNING}Description:${_EOL}"
	@printf "${_PRIMARY}  This is the main entrypoint for RickAndMortyApi project ${_EOL}\n"

	@printf "${_WARNING}Usage:${_EOL}"
	@printf "${_PRIMARY}  make [command]${_EOL}\n"

	@printf "${_WARNING}Commands:${_EOL}"
	@awk '/^### /{printf"\n${_WARNING}%s${_EOL}",substr($$0,5)} \
	/^[a-zA-Z0-9_-]+:/{HELP="";if( match(PREV,/^## /))HELP=substr(PREV,4); \
		printf "${_SUCCESS}  %-12s  ${_PRIMARY}%s${_EOL}",substr($$1,0,index($$1,":")-1),HELP \
	}{PREV=$$0}' ${MAKEFILE_LIST}

##################################################
### App
##################################################

## Export data
export_data:
	@printf "${_INFO}sh entrypoint.sh export_data${_EOL}"
	@sh entrypoint.sh export_data

## Import data
import_data:
	@printf "${_INFO}sh entrypoint.sh import_data${_EOL}"
	@sh entrypoint.sh import_data

## Scrape data
scrape:
	@printf "${_INFO}sh entrypoint.sh scrape${_EOL}"
	@sh entrypoint.sh scrape

##################################################
### Install
##################################################

## Composer install, create DB, set env and clear cache
install:
	@printf "${_INFO}sh entrypoint.sh install${_EOL}"
	@sh entrypoint.sh install

## Uninstall
uninstall:
	@printf "${_INFO}sh entrypoint.sh uninstall${_EOL}"
	@sh entrypoint.sh uninstall

## Check requirements
requirements:
	@printf "${_INFO}sh entrypoint.sh requirements${_EOL}"
	@sh entrypoint.sh requirements

## Remove ".env.local" and ".env.dev.local" files
rm_env:
	@printf "${_INFO}sh entrypoint.sh rm_env${_EOL}"
	@sh entrypoint.sh rm_env

## Create ".env.local" file
set_env:
	@printf "${_INFO}sh entrypoint.sh set_env${_EOL}"
	@sh entrypoint.sh set_env

##################################################
### CI CD
##################################################

## Run linter (sniff)
lint:
	@printf "${_INFO}sh entrypoint.sh lint${_EOL}"
	@sh entrypoint.sh lint

## Run linter (php-cs-fixer fix)
lint_fix:
	@printf "${_INFO}sh entrypoint.sh lint_fix${_EOL}"
	@sh entrypoint.sh lint_fix

## Run tests
tests:
	@printf "${_INFO}sh entrypoint.sh tests${_EOL}"
	@sh entrypoint.sh tests

## Run functional tests
tests_functional:
	@printf "${_INFO}sh entrypoint.sh tests_functional${_EOL}"
	@sh entrypoint.sh tests_functional

## Run integration tests
tests_integration:
	@printf "${_INFO}sh entrypoint.sh tests_integration${_EOL}"
	@sh entrypoint.sh tests_integration

## Run unit tests
tests_unit:
	@printf "${_INFO}sh entrypoint.sh tests_unit${_EOL}"
	@sh entrypoint.sh tests_unit

## Output test coverage (phpunit)
coverage:
	@printf "${_INFO}sh entrypoint.sh coverage${_EOL}"
	@sh entrypoint.sh coverage

## Check security issues in project dependencies (symfony-cli)
security:
	@printf "${_INFO}sh entrypoint.sh security${_EOL}"
	@sh entrypoint.sh security

##################################################
### Database
##################################################

## Reset database
reset_db:
	@printf "${_INFO}sh entrypoint.sh reset_db${_EOL}"
	@sh entrypoint.sh reset_db

##################################################
### Doctrine
##################################################

## Create database
create_db:
	@printf "${_INFO}sh entrypoint.sh create_db${_EOL}"
	@sh entrypoint.sh create_db

## Drop database
drop:
	@printf "${_INFO}sh entrypoint.sh drop${_EOL}"
	@sh entrypoint.sh drop

## Load fixtures
fixtures:
	@printf "${_INFO}sh entrypoint.sh fixtures${_EOL}"
	@sh entrypoint.sh fixtures

## Execute migration
migrate:
	@printf "${_INFO}sh entrypoint.sh migrate${_EOL}"
	@sh entrypoint.sh migrate

## Generate migration script
migration_diff:
	@printf "${_INFO}sh entrypoint.sh migration_diff${_EOL}"
	@sh entrypoint.sh migration_diff

## Create schema with Doctrine
schema:
	@printf "${_INFO}sh entrypoint.sh schema${_EOL}"
	@sh entrypoint.sh schema

##################################################
### Development
##################################################

## Generate schema from yaml (api-platform)
generate_schema:
	@printf "${_INFO}sh entrypoint.sh generate_schema${_EOL}"
	@sh entrypoint.sh generate_schema

## Serve locally with PHP or symfony-cli
serve:
	@printf "${_INFO}sh entrypoint.sh serve${_EOL}"
	@sh entrypoint.sh serve

## Print version infos
version:
	@printf "${_INFO}sh entrypoint.sh version${_EOL}"
	@sh entrypoint.sh version

##################################################
### Docker
##################################################

## Build containers
build:
	@printf "${_INFO}sh entrypoint.sh build${_EOL}"
	@sh entrypoint.sh build

## Create "traefik" network
network:
	@printf "${_INFO}sh entrypoint.sh network${_EOL}"
	@sh entrypoint.sh network

## Remove "traefik" network
network_remove:
	@printf "${_INFO}sh entrypoint.sh network_remove${_EOL}"
	@sh entrypoint.sh network_remove

## Open container in default browser
open:
	@printf "${_INFO}sh entrypoint.sh open${_EOL}"
	@sh entrypoint.sh open

## Start docker stack
start:
	@printf "${_INFO}sh entrypoint.sh start${_EOL}"
	@sh entrypoint.sh start

## Stop docker stack
stop:
	@printf "${_INFO}sh entrypoint.sh stop${_EOL}"
	@sh entrypoint.sh stop

## Create network, start container, composer install, import data, open in browser
up:
	@printf "${_INFO}sh entrypoint.sh up${_EOL}"
	@sh entrypoint.sh up

##################################################
### Symfony
##################################################

## Clear cache
cache:
	@printf "${_INFO}sh entrypoint.sh cache${_EOL}"
	@sh entrypoint.sh cache

## Generate APP_SECRET
generate_app_secret:
	@printf "${_INFO}sh entrypoint.sh generate_app_secret${_EOL}"
	@sh entrypoint.sh generate_app_secret

##################################################
### Self Install
##################################################

## Install script and enable completion
self_install:
	@printf "${_INFO}sh entrypoint.sh self_install${_EOL}"
	@sh entrypoint.sh self_install

## Uninstall script from system
self_uninstall:
	@printf "${_INFO}sh entrypoint.sh self_uninstall${_EOL}"
	@sh entrypoint.sh self_uninstall


