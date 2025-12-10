#!/usr/bin/env sh

set -e

# This script is based on TangoMan Shoe Shell Microframework
#
# This file is distributed under to the MIT license.
#
# Copyright (c) 2025 "Matthias Morin" <mat@tangoman.io>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Source code is available here: https://github.com/TangoMan75/shoe

## Rick and Morty
##
## This is the main entrypoint for RickAndMortyApi project
##
## @author  "Matthias Morin" <mat@tangoman.io>
## @version 1.0.0
## @license MIT
## @link    https://github.com/TangoMan75/rick-and-morty

#--------------------------------------------------
# Place your constants after this line
#--------------------------------------------------

## Script alias
ALIAS=rick

#--------------------------------------------------
# Place your options after this line
#--------------------------------------------------

## Environment /^(dev|prod|test)$/
env=dev

## Default port /^[0-9]+$/
port=8000

## File to test /^~?[a-zA-Z0-9.\/_-]+$/
file=''

#--------------------------------------------------
# Place your flags after this line
#--------------------------------------------------

## Force
force=false

#--------------------------------------------------
# Place your private constants after this line
#--------------------------------------------------

#--------------------------------------------------
# Place your global variables after this line
#--------------------------------------------------

#--------------------------------------------------
# Place your functions after this line
#--------------------------------------------------

##################################################
### App
##################################################

## Export data
##
## {
##   "namespace": "app",
##   "depends": [
##     "_console",
##     "_echo_info"
##   ]
## }
export_data() {
    for entity in \
        Character \
        Location \
        Episode \
    ; do
        _echo_info "$(_console) app:export ${entity}\n"
        $(_console) app:export ${entity}
    done
}

## Import data
##
## {
##   "namespace": "app",
##   "depends": [
##     "_console",
##     "_echo_info"
##   ]
## }
import_data() {
    for file in \
        data/characters.json \
        data/locations.json \
        data/episodes.json \
    ; do
        _echo_info "$(_console) app:import ${file}\n"
        $(_console) app:import ${file}
    done
}

## Scrape data
##
## {
##   "namespace": "app",
##   "depends": [
##     "_console"
##   ]
## }
scrape() {
    _echo_info "$(_console) app:scrape --env ${env}\n"
    $(_console) app:scrape --env ${env}
}

##################################################
### Install
##################################################

## Composer install, create DB, set env and clear cache
##
## {
##   "namespace": "install",
##   "depends": [
##     "_alert_primary",
##     "_composer_install",
##     "_db_schema",
##     "_sf_cache",
##     "create_db",
##     "set_env"
##   ]
## }
install() {
    _alert_primary "Installing project with \"${env}\" environment"
    _composer_install
    create_db
    _db_schema "${env}"
    set_env
    _sf_cache "${env}"
}

## Uninstall
##
## {
##   "namespace": "install",
##   "depends": [
##     "_echo_error",
##     "_echo_info"
##   ]
## }
uninstall() {
    for _file in \
        ./var/*.db \
        .env.dev.local \
        .env.local \
        .env.prod.local \
        .php-cs-fixer.cache \
        .php_cs.cache \
        .phpcs-cache \
        .phpunit.result.cache \
    ; do
        _echo_info "rm -f \"${_file}\"\n"
        rm -f "${_file}"
    done

    if [ "${force}" = true ]; then
        _echo_info "rm -f composer.lock\n"
        rm -f composer.lock

        _echo_info "rm -f symfony.lock\n"
        rm -f symfony.lock
    fi

    for _folder in \
        ./bin/.phpunit \
        ./coverage \
        ./logs/* \
        ./node_modules \
        ./public/bundles \
        ./var/cache \
        ./var/log \
        ./vendor \
        ./volumes/postgres_data \
    ; do
        _echo_info "rm -rf \"${_folder}\"\n"
        rm -rf "${_folder}"
    done
}

## Check requirements
##
## {
##   "namespace": "install",
##   "depends": [
##     "_check_installed"
##   ]
## }
requirements() {
    _error=0

    if ! _check_installed awk; then
        _error=1
    fi

    if ! _check_installed sed; then
        _error=1
    fi

    return "${_error}"
}

## Remove ".env.local" and ".env.dev.local" files
##
## {
##   "namespace": "install",
##   "depends": [
##     "_echo_info"
##   ]
## }
rm_env() {
    _echo_info "rm -f .env.local\n"
    rm -f .env.local

    _echo_info "rm -f .env.dev.local\n"
    rm -f .env.dev.local
}

## Create ".env.local" file
##
## {
##   "namespace": "install",
##   "depends": [
##     "_echo_info",
##     "generate_app_secret"
##   ]
## }
set_env() {
    _echo_info "cp -f .env.${env} .env.local\n"
    cp -f .env.${env} .env.local

    generate_app_secret
}

##################################################
### CI CD
##################################################

## Run linter (sniff)
##
## {
##   "namespace": "ci_cd",
##   "requires": [
##     "php"
##   ],
##   "depends": [
##     "_alert_secondary",
##     "_echo_info"
##   ]
## }
lint() {
    _alert_secondary 'Check composer validity'
    _echo_info 'composer validate\n'
    composer validate

    _alert_secondary 'Check local requirements'
    _echo_info "./vendor/bin/requirements-checker\n"
    ./vendor/bin/requirements-checker

    _alert_secondary 'Check php files syntax'
    _echo_info "php -l -d memory-limit=-1 -d display_errors=0 \"...\"\n"
    find ./src ./tests -type f -name '*.php' | while read -r FILE; do
        php -l -d memory-limit=-1 -d display_errors=0 "${FILE}"
    done

    _alert_secondary 'PHP CS Fixer'
    # PHP CS Fixer https://cs.symfony.com/doc/usage.html
    _echo_info './vendor/bin/php-cs-fixer fix --dry-run --diff --allow-risky=yes --verbose --show-progress=dots\n'
    ./vendor/bin/php-cs-fixer fix --dry-run --diff --allow-risky=yes --verbose --show-progress=dots

    _alert_secondary 'Console Lint Container'
    _echo_info "./bin/console lint:container\n"
    ./bin/console lint:container

    if [ -d ./templates ]; then
        _alert_secondary 'Console Lint Twig'
        _echo_info "./bin/console lint:twig ./templates --show-deprecations\n"
        ./bin/console lint:twig ./templates --show-deprecations
    fi

    _alert_secondary 'Console Lint Yaml'
    _echo_info "./bin/console lint:yaml ./config\n"
    ./bin/console lint:yaml ./config
}

## Run linter (php-cs-fixer fix)
##
## {
##   "namespace": "ci_cd",
##   "requires": [
##     "php"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
lint_fix() {
    # PHP CS Fixer https://cs.symfony.com/doc/usage.html
    _echo_info 'php -d memory-limit=-1 ./vendor/bin/php-cs-fixer fix --allow-risky=yes --verbose --show-progress=dots\n'
    php -d memory-limit=-1 ./vendor/bin/php-cs-fixer fix --allow-risky=yes --verbose --show-progress=dots
}

## Run tests
##
## {
##   "namespace": "ci_cd",
##   "depends": [
##     "_composer_install",
##     "check_drivers",
##     "create_db",
##     "drop",
##     "schema",
##     "tests_functional",
##     "tests_integration",
##     "tests_unit"
##   ]
## }
tests() {
    _composer_install

    tests_unit
    reset_db

    tests_integration

    reset_db
    tests_functional
}

## Run functional tests
##
## {
##   "namespace": "ci_cd",
##   "requires": [
##     "php"
##   ],
##   "depends": [
##     "_echo_info",
##     "_phpunit"
##   ]
## }
tests_functional() {
    # force test environment
    env='test'

    if [ "${file}" ]; then
        _echo_info "php -d memory-limit=-1 \"$(_phpunit)\" --stop-on-failure --testdox --testdox \"${file}\"\n"
        php -d memory-limit=-1 "$(_phpunit)" --stop-on-failure --testdox --testdox "${file}"
        return 0
    fi

    _echo_info "php -d memory-limit=-1 \"$(_phpunit)\" --stop-on-failure --testdox tests/Functional\n"
    php -d memory-limit=-1 "$(_phpunit)" --stop-on-failure --testdox tests/Functional
}

## Run integration tests
##
## {
##   "namespace": "ci_cd",
##   "requires": [
##     "php"
##   ],
##   "depends": [
##     "_echo_info",
##     "_phpunit"
##   ]
## }
tests_integration() {
    # force test environment
    env='test'

    if [ "${file}" ]; then
        _echo_info "php -d memory-limit=-1 \"$(_phpunit)\" --stop-on-failure --testdox --testdox \"${file}\"\n"
        php -d memory-limit=-1 "$(_phpunit)" --stop-on-failure --testdox --testdox "${file}"
        return 0
    fi

    _echo_info "php -d memory-limit=-1 \"$(_phpunit)\" --stop-on-failure --testdox tests/Integration\n"
    php -d memory-limit=-1 "$(_phpunit)" --stop-on-failure --testdox tests/Integration
}

## Run unit tests
##
## {
##   "namespace": "ci_cd",
##   "requires": [
##     "php"
##   ],
##   "depends": [
##     "_echo_info",
##     "_phpunit"
##   ]
## }
tests_unit() {
    # force test environment
    env='test'

    if [ "${file}" ]; then
        _echo_info "php -d memory-limit=-1 \"$(_phpunit)\" --stop-on-failure --testdox \"${file}\"\n"
        php -d memory-limit=-1 "$(_phpunit)" --stop-on-failure --testdox "${file}"
        return 0
    fi

    _echo_info "php -d memory-limit=-1 \"$(_phpunit)\" --stop-on-failure --testdox tests/Unit\n"
    php -d memory-limit=-1 "$(_phpunit)" --stop-on-failure --testdox tests/Unit
}

## Output test coverage (phpunit)
##
## {
##   "namespace": "ci_cd",
##   "requires": [
##     "php"
##   ],
##   "depends": [
##     "_echo_info",
##     "_phpunit"
##   ]
## }
coverage() {
    _echo_info "XDEBUG_MODE=coverage php -d memory-limit=-1 \"$(_phpunit)\" --coverage-html ./coverage\n"
    XDEBUG_MODE=coverage php -d memory-limit=-1 "$(_phpunit)" --coverage-html ./coverage
}

## Check security issues in project dependencies (symfony-cli)
##
## {
##   "namespace": "ci_cd",
##   "requires": [
##     "symfony"
##   ],
##   "depends": [
##     "_check_installed"
##   ]
## }
security() {
    _check_installed symfony

    _echo_info 'symfony security:check\n'
    symfony security:check
}

##################################################
### Database
##################################################

## Reset database
##
## {
##   "namespace": "database",
##   "depends": [
##     "cache",
##     "create_db",
##     "drop",
##     "schema"
##   ]
## }
reset_db() {
    drop
    create_db
    schema
    force=true; cache
}

## Get database type
##
## {
##   "namespace": "database",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_dotenv"
##   ]
## }
_get_database_type() {
    _dotenv

    echo "${DATABASE_URL}" | awk -F ':' '{print $1}'
}

## Check if database is installed
##
## {
##   "namespace": "database",
##   "depends": [
##     "_get_database_type"
##   ]
## }
_is_database_installed() {
    if [ "$(_get_database_type)" = sqlite ] && [ -f ./var/data_${env}.db ]; then
        echo true
        return 0
    fi

    echo false
}

##################################################
### Doctrine
##################################################

## Create database
##
## {
##   "namespace": "database",
##   "requires": [
##     "doctrine/orm"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
create_db() {
    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info "./bin/console doctrine:database:create --env ${env} || true\n"
    ./bin/console doctrine:database:create --env ${env} || true
}

## Drop database
##
## {
##   "namespace": "database",
##   "requires": [
##     "doctrine/orm"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
drop() {
    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info "./bin/console doctrine:database:drop --force --env ${env} || true\n"
    ./bin/console doctrine:database:drop --force --env ${env} || true
}

## Load fixtures
##
## {
##   "namespace": "fixtures",
##   "requires": [
##     "doctrine/orm"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
fixtures() {
    _echo_info "./bin/console doctrine:fixtures:load --no-interaction --env ${env}\n"
    ./bin/console doctrine:fixtures:load --no-interaction --env ${env}
}

## Execute migration
##
## {
##   "namespace": "database",
##   "requires": [
##     "doctrine/orm"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
migrate() {
    # following command prints SQL to be executed in the command line
    _echo_info "./bin/console doctrine:migrations:migrate --no-interaction --env ${env}\n"
    ./bin/console doctrine:migrations:migrate --no-interaction --env ${env}

    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info "./bin/console doctrine:schema:validate --env ${env} || true\n"
    ./bin/console doctrine:schema:validate --env ${env} || true
}

## Generate migration script
##
## {
##   "namespace": "database",
##   "requires": [
##     "doctrine/orm"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
migration_diff() {
    _echo_info "./bin/console doctrine:migrations:diff --no-interaction --env ${env}\n"
    ./bin/console doctrine:migrations:diff --no-interaction --env ${env}
}

## Create schema with Doctrine
##
## {
##   "namespace": "database",
##   "requires": [
##     "doctrine/orm"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
schema() {
    # following command prints SQL to be executed in the terminal
    _echo_info "./bin/console doctrine:schema:create --dump-sql --env ${env}\n"
    ./bin/console doctrine:schema:create --dump-sql --env ${env}

    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info "./bin/console doctrine:schema:create --env ${env} || true\n"
    ./bin/console doctrine:schema:create --env ${env} || true
}

##################################################
### Development
##################################################

## Generate schema from yaml (api-platform)
##
## {
##   "namespace": "development",
##   "requires": [
##     "api-platform/schema-generator",
##     "php"
##   ],
##   "depends": [
##     "_echo_error",
##     "_echo_info"
##   ]
## }
generate_schema() {
    if [ -f ./vendor/bin/schema ]; then
        _echo_info "php -d memory-limit=-1 ./vendor/bin/schema generate \"$(pwd)/src/\" ./config/schema.yaml\n"
        php -d memory-limit=-1 ./vendor/bin/schema generate "$(pwd)/src/" ./config/schema.yaml

        return 0
    fi

    if [ -x "$(command -v schema.phar)" ]; then
        _echo_info "schema.phar generate \"$(pwd)/src/\" ./config/schema.yaml\n"
        schema.phar generate "$(pwd)/src/" ./config/schema.yaml

        return 0
    fi

    _echo_error 'schema-generator executable not found\n'
    return 1
}

## Check if symfony app is installed
##
## {
##   "namespace": "development"
## }
_are_vendors_installed() {
    if [ -d ./vendor ]; then

        return 0
    fi

    return 1
}

## Load .env variables
##
## {
##   "namespace": "development",
##   "requires": [
##     "cat",
##     "eval"
##   ],
##   "depends": [
##     "_echo_error"
##   ]
## }
_dotenv() {
    if [ -f ".env.${env}.local" ]; then
        eval "$(cat ".env.${env}.local")"
        return 0
    fi

    if [ -f ".env.${env}" ]; then
        eval "$(cat ".env.${env}")"
        return 0
    fi

    if [ -f ".env.local" ]; then
        eval "$(cat ".env.local")"
        return 0
    fi

    if [ -f .env ]; then
        eval "$(cat .env)"
        return 0
    fi

    _echo_error '".env" file not found\n'
    exit 1
}

## Serve locally with PHP or symfony-cli
##
## {
##   "namespace": "development",
##   "requires": [
##     "php",
##     "symfony"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
serve() {
    if _check_installed symfony; then
        _echo_info "symfony serve --port=${port} --no-tls\n"
        symfony serve --port=${port} --no-tls
    else
        _echo_info "php -d memory-limit=-1 -S 127.0.0.1:${port} -t ./public\n"
        php -d memory-limit=-1 -S 127.0.0.1:${port} -t ./public
    fi
}

## Print version infos
##
## {
##   "namespace": "development",
##   "requires": [
##     "grep",
##     "php",
##     "sed"
##   ],
##   "depends": [
##     "_echo_primary",
##     "_echo_success",
##     "_get_database_type",
##     "_is_database_installed"
##   ]
## }
version() {
    # get correct console executable
    _console=$(if [ -f ./app/console ]; then echo './app/console'; elif [ -f ./bin/console ]; then echo './bin/console'; fi)
    # get correct public folder
    _public=$(if [ -d ./web ]; then echo './web'; elif [ -d ./public ]; then echo './public'; else echo './'; fi)
    # get current php version
    _php_version=$(php -v | grep -oE 'PHP\s\d+\.\d+.\d+' | sed s/'PHP '//)
    # symfony version
    _symfony_version=$(${_console} --version --env ${env})

    _echo_success 'env'       2 10; _echo_primary "${env}\n"
    _echo_success 'console'   2 10; _echo_primary "${_console}\n"
    _echo_success 'public'    2 10; _echo_primary "${_public}\n"
    _echo_success 'php'       2 10; _echo_primary "${_php_version}\n"
    _echo_success 'symfony'   2 10; _echo_primary "${_symfony_version}\n"
    _echo_success 'database'  2 10; _echo_primary "$(_get_database_type)\n"
    _echo_success 'installed' 2 10; _echo_primary "$(_is_database_installed)\n"
    echo
}

##################################################
### Docker
##################################################

## Build containers
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_docker_compose_build"
##   ]
## }
build() {
    _docker_compose_build "./compose.${env}.yaml"
}

## Create "traefik" network
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
network() {
    _check_installed docker

    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info 'docker network create traefik || true\n'
    docker network create traefik || true
}

## Remove "traefik" network
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
network_remove() {
    _check_installed docker

    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info 'docker network rm traefik || true\n'
    docker network rm traefik || true
}

## Open container in default browser
##
## {
##   "namespace": "docker",
##   "depends": [
##     "_echo_error",
##     "_find_container_name",
##     "_open_in_default_browser"
##   ]
## }
open() {
    _container_name="$(_find_container_name nginx)"
    if [ -z "${_container_name}" ]; then
        _echo_error 'nginx container not found\n'

        return 1
    fi

    _container_ip="$(_get_container_ip "${_container_name}")"
    if [ -z "${_container_ip}" ]; then
        _echo_error 'container ip not found\n'

        return 1
    fi

    _open_in_default_browser "${_container_ip}"
}

## Start docker stack
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_docker_compose_start"
##   ]
## }
start() {
    _docker_compose_start "./compose.${env}.yaml"
}

## Stop docker stack
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_docker_compose_stop"
##   ]
## }
stop() {
    _docker_compose_stop "./compose.${env}.yaml"
}

## Create network, start container, composer install, import data, open in browser
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_echo_error",
##     "_echo_info",
##     "build",
##     "network",
##     "open",
##     "start"
##   ]
## }
up() {
    _alert_primary "Spawning project with \"${env}\" environment"

    if [ -z "$(docker compose -v)" ]; then
        _echo_error "\"$(basename "${0}")\" requires docker compose plugin\n"
        return 1
    fi

    network
    build
    start

    _echo_info "docker compose --file \"./compose.${env}.yaml\" exec php sh -c \"sh entrypoint.sh install --env ${env}\"\n"
    docker compose --file "./compose.${env}.yaml" exec php sh -c "sh entrypoint.sh install --env ${env}"

    _echo_info "docker compose --file \"./compose.${env}.yaml\" exec php sh -c \"sh entrypoint.sh import_data --env ${env}\"\n"
    docker compose --file "./compose.${env}.yaml" exec php sh -c "sh entrypoint.sh import_data --env ${env}"

    open
}

##################################################
### Symfony
##################################################

## Clear cache
##
## {
##   "namespace": "symfony",
##   "depends": [
##     "_sf_cache"
##   ]
## }
cache() {
    _sf_cache "${env}"
}

## Generate APP_SECRET
##
## {
##   "namespace": "symfony",
##   "requires": [
##     "openssl",
##     "sed"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
generate_app_secret() {
    _check_installed openssl

    if [ -f .env.local ]; then
        _echo_info "sed -i -r \"/APP_SECRET=/s/[a-z0-9]+/\$(openssl rand -hex 16)/\" \".env.local\"\n"
        sed -i -r "/APP_SECRET=/s/[a-z0-9]+/$(openssl rand -hex 16)/" ".env.local"
    fi
}

##################################################
### Self Install
##################################################

## Install script and enable completion
##
## {
##   "namespace": "install",
##   "depends": [
##     "_install"
##   ],
##   "assumes": [
##     "ALIAS",
##     "global"
##   ]
## }
self_install() {
    _install "$0" "${ALIAS}" "${global:-false}"
}

## Uninstall script from system
##
## {
##   "namespace": "install",
##   "depends": [
##     "_uninstall"
##   ],
##   "assumes": [
##     "ALIAS"
##   ]
## }
self_uninstall() {
    _uninstall "$0" "${ALIAS}"
}

##################################################
### Help
##################################################

## Print this help
##
## {
##   "namespace": "help",
##   "depends": [
##     "_help"
##   ]
## }
help() {
    _help "$0"
}

#--------------------------------------------------
#_ Hooks
#--------------------------------------------------

## Place here commands you need executed by default (optional)
##
## {
##   "namespace": "hooks"
## }
_default() {
    help
}

# Place here commands you need executed first every time
_before() {
    if ! requirements; then
        return 1
    fi

    # this will resolve to current project directory
    # or to "pwd" when script is installed globally via copy
    # remove if you don't need script to change to project directory
    cd "$(_pwd)" || return 1
}

## Place here commands you need executed last every time (optional)
##
## {
##   "namespace": "hooks"
## }
_after() {
    return 0
}

###################################################
# TangoMan Shoe Shell Microframework
###################################################

#--------------------------------------------------
# Generated code : Do not edit below this line
#--------------------------------------------------

#--------------------------------------------------
#_ Colors
#--------------------------------------------------

## shellcheck disable=SC2034

## bright white text
_PRIMARY='\033[97m'

## bright blue text
_SECONDARY='\033[94m'

## bright green text
_SUCCESS='\033[32m'

## red text
_DANGER='\033[31m'

## orange text
_WARNING='\033[33m'

## bright purple text
_INFO='\033[95m'

## reset formatting
_DEFAULT='\033[0m'

## reset formatting and carriage return
_EOL='\033[0m\n'

## shellcheck disable=SC2034

## bold white text over bright blue background
_ALERT_PRIMARY='\033[1;104;97m'

## bold white text over bright purple background
_ALERT_SECONDARY='\033[1;45;97m'

## bold white text over bright green background
_ALERT_SUCCESS='\033[1;42;97m'

## bold white text over bright red background
_ALERT_DANGER='\033[1;41;97m'

## bold white text over bright orange background
_ALERT_WARNING='\033[1;43;97m'

## bold white text over bright blue background
_ALERT_INFO='\033[1;44;97m'

## Print primary text with optional indentation and padding
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_DEFAULT",
##     "_PRIMARY"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "INDENTATION",
##       "type": "int",
##       "description": "Indentation level.",
##       "default": 0
##     },
##     {
##       "position": 3,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 0
##     }
##   ]
## }
_echo_primary() {
    # Synopsis: _echo_primary <STRING> [INDENTATION] [PADDING]
    #  STRING:      Text to display.
    #  INDENTATION: Indentation level (default: 0).
    #  PADDING:     Padding length (default: 0).
    #  note:        Older versions of printf supports a more limited set of format specifiers (eg: "%-*b"),
    #               this is why we're calculating the PADDING length on each execution.

    set -- "$1" "${2:-0}" "$((${3:-0}-${#1}))"
    if [ "$3" -lt 0 ]; then set -- "$1" "$2" 0; fi
    printf "%*s${_PRIMARY}%b${_DEFAULT}%*s" "$2" '' "$1" "$3" ''
}

## Print secondary text with optional indentation and padding
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_DEFAULT",
##     "_SECONDARY"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "INDENTATION",
##       "type": "int",
##       "description": "Indentation level.",
##       "default": 0
##     },
##     {
##       "position": 3,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 0
##     }
##   ]
## }
_echo_secondary() {
    # Synopsis: _echo_secondary <STRING> [INDENTATION] [PADDING]
    #  STRING:       Text to display.
    #  INDENTATION:  Indentation level (default: 0).
    #  PADDING:      Padding length (default: 0).

    set -- "$1" "${2:-0}" "$((${3:-0}-${#1}))"
    if [ "$3" -lt 0 ]; then set -- "$1" "$2" 0; fi
    printf "%*s${_SECONDARY}%b${_DEFAULT}%*s" "$2" '' "$1" "$3" ''
}

## Print success text with optional indentation and padding
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_DEFAULT",
##     "_SUCCESS"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "INDENTATION",
##       "type": "int",
##       "description": "Indentation level.",
##       "default": 0
##     },
##     {
##       "position": 3,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 0
##     }
##   ]
## }
_echo_success() {
    # Synopsis: _echo_success <STRING> [INDENTATION] [PADDING]
    #  STRING:       Text to display.
    #  INDENTATION:  Indentation level (default: 0).
    #  PADDING:      Padding length (default: 0).

    set -- "$1" "${2:-0}" "$((${3:-0}-${#1}))"
    if [ "$3" -lt 0 ]; then set -- "$1" "$2" 0; fi
    printf "%*s${_SUCCESS}%b${_DEFAULT}%*s" "$2" '' "$1" "$3" ''
}

## Print danger text with optional indentation and padding
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_DANGER",
##     "_DEFAULT"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "INDENTATION",
##       "type": "int",
##       "description": "Indentation level.",
##       "default": 0
##     },
##     {
##       "position": 3,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 0
##     }
##   ]
## }
_echo_danger() {
    # Synopsis: _echo_danger <STRING> [INDENTATION] [PADDING]
    #  STRING:       Text to display.
    #  INDENTATION:  Indentation level (default: 0).
    #  PADDING:      Padding length (default: 0).

    set -- "$1" "${2:-0}" "$((${3:-0}-${#1}))"
    if [ "$3" -lt 0 ]; then set -- "$1" "$2" 0; fi
    printf "%*s${_DANGER}%b${_DEFAULT}%*s" "$2" '' "$1" "$3" ''
}

## Print warning text with optional indentation and padding
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_DEFAULT",
##     "_WARNING"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "INDENTATION",
##       "type": "int",
##       "description": "Indentation level.",
##       "default": 0
##     },
##     {
##       "position": 3,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 0
##     }
##   ]
## }
_echo_warning() {
    # Synopsis: _echo_warning <STRING> [INDENTATION] [PADDING]
    #  STRING:       Text to display.
    #  INDENTATION:  Indentation level (default: 0).
    #  PADDING:      Padding length (default: 0).

    set -- "$1" "${2:-0}" "$((${3:-0}-${#1}))"
    if [ "$3" -lt 0 ]; then set -- "$1" "$2" 0; fi
    printf "%*s${_WARNING}%b${_DEFAULT}%*s" "$2" '' "$1" "$3" ''
}

## Print info text with optional indentation and padding
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_DEFAULT",
##     "_INFO"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "INDENTATION",
##       "type": "int",
##       "description": "Indentation level.",
##       "default": 0
##     },
##     {
##       "position": 3,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 0
##     }
##   ]
## }
_echo_info() {
    # Synopsis: _echo_info <STRING> [INDENTATION] [PADDING]
    #  STRING:       Text to display.
    #  INDENTATION:  Indentation level (default: 0).
    #  PADDING:      Padding length (default: 0).

    set -- "$1" "${2:-0}" "$((${3:-0}-${#1}))"
    if [ "$3" -lt 0 ]; then set -- "$1" "$2" 0; fi
    printf "%*s${_INFO}%b${_DEFAULT}%*s" "$2" '' "$1" "$3" ''
}

## Print primary alert
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_ALERT_PRIMARY",
##     "_EOL"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     }
##   ]
## }
_alert_primary()   {
    # Synopsis: _alert_primary <STRING>
    #   STRING: Text to display.

    printf "${_EOL}%b%64s${_EOL}%b %-63s${_EOL}%b%64s${_EOL}\n" "${_ALERT_PRIMARY}" '' "${_ALERT_PRIMARY}" "$1" "${_ALERT_PRIMARY}" ''
}

## Print secondary alert
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_ALERT_SECONDARY",
##     "_EOL"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     }
##   ]
## }
_alert_secondary() {
    # Synopsis: _alert_secondary <STRING>
    #   STRING: Text to display.

    printf "${_EOL}%b%64s${_EOL}%b %-63s${_EOL}%b%64s${_EOL}\n" "${_ALERT_SECONDARY}" '' "${_ALERT_SECONDARY}" "$1" "${_ALERT_SECONDARY}" ''
}

## Print success alert
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_ALERT_SUCCESS",
##     "_EOL"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     }
##   ]
## }
_alert_success()   {
    # Synopsis: _alert_success <STRING>
    #   STRING: Text to display.

    printf "${_EOL}%b%64s${_EOL}%b %-63s${_EOL}%b%64s${_EOL}\n" "${_ALERT_SUCCESS}" '' "${_ALERT_SUCCESS}" "$1" "${_ALERT_SUCCESS}" ''
}

## Print danger alert
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_ALERT_DANGER",
##     "_EOL"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     }
##   ]
## }
_alert_danger()    {
    # Synopsis: _alert_danger <STRING>
    #   STRING: Text to display.

    printf "${_EOL}%b%64s${_EOL}%b %-63s${_EOL}%b%64s${_EOL}\n" "${_ALERT_DANGER}" '' "${_ALERT_DANGER}" "$1" "${_ALERT_DANGER}" ''
}

## Print warning alert
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_ALERT_WARNING",
##     "_EOL"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     }
##   ]
## }
_alert_warning()   {
    # Synopsis: _alert_warning <STRING>
    #   STRING: Text to display.

    printf "${_EOL}%b%64s${_EOL}%b %-63s${_EOL}%b%64s${_EOL}\n" "${_ALERT_WARNING}" '' "${_ALERT_WARNING}" "$1" "${_ALERT_WARNING}" ''
}

## Print info alert
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_ALERT_INFO",
##     "_EOL"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "Text to display.",
##       "nullable": false
##     }
##   ]
## }
_alert_info()      {
    # Synopsis: _alert_info <STRING>
    #   STRING: Text to display.

    printf "${_EOL}%b%64s${_EOL}%b %-63s${_EOL}%b%64s${_EOL}\n" "${_ALERT_INFO}" '' "${_ALERT_INFO}" "$1" "${_ALERT_INFO}" ''
}

## Print error message to STDERR, prefixed with "error: "
##
## {
##   "namespace": "colors",
##   "assumes": [
##     "_DANGER",
##     "_DEFAULT"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "MESSAGE",
##       "type": "str",
##       "description": "Error message to display.",
##       "nullable": false
##     }
##   ]
## }
_echo_error() {
    # Synopsis: _echo_error <MESSAGE>
    #   MESSAGE: Error message to display.

    printf "${_DANGER}error: %s${_DEFAULT}\n" "$1" >&2
}

#--------------------------------------------------
#_ Compatibility
#--------------------------------------------------

## Open with default system handler
##
## {
##   "namespace": "compatibility",
##   "requires": [
##     "uname"
##   ]
## }
_open() {
    # Synopsis: _open

    if [ "$(uname)" = 'Darwin' ]; then
        echo 'open'

        return 0
    fi

    echo 'xdg-open'
}

## Return sed -i system flavour
##
## {
##   "namespace": "compatibility",
##   "requires": [
##     "command",
##     "sed",
##     "uname"
##   ]
## }
_sed_i() {
    # Synopsis: _sed_i

    if [ "$(uname)" = 'Darwin' ] && [ -n "$(command -v sed)" ] && [ -z "$(sed --version 2>/dev/null)" ]; then
        echo "sed -i ''"

        return 0
    fi

    echo 'sed -i'
}

#--------------------------------------------------
#_ Docker
#--------------------------------------------------

## Build container stack with docker compose
##
## {
##   "namespace": "docker",
##   "depends": [
##     "_get_docker_compose",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the compose.yaml file."
##     }
##   ]
## }
_docker_compose_build() {
    # Synopsis: _docker_compose_build [FILE_PATH]
    #   FILE_PATH: (optional) The path to the compose.yaml file.

    if [ $# -gt 1 ]; then _echo_danger "error: _docker_compose_build: too many arguments ($#)\n"; return 1; fi

    if [ -z "$1" ]; then
        _echo_info "$(_get_docker_compose) build\n"
        $(_get_docker_compose) build

        return 0
    fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _docker_compose_build: \"$1\" file not found\n"; return 1; fi

    _echo_info "$(_get_docker_compose) --file \"$1\" build\n"
    $(_get_docker_compose) --file "$1" build
}

## Build and start container stack with docker compose
##
## {
##   "namespace": "docker",
##   "depends": [
##     "_get_docker_compose",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the compose.yaml file."
##     }
##   ]
## }
_docker_compose_start() {
    # Synopsis: _docker_compose_start [FILE_PATH]
    #   FILE_PATH: (optional) The path to the compose.yaml file.

    if [ $# -gt 1 ]; then _echo_danger "error: _docker_compose_start: too many arguments ($#)\n"; return 1; fi

    if [ -z "$1" ]; then
        _echo_info "$(_get_docker_compose) up --detach --remove-orphans\n"
        $(_get_docker_compose) up --detach --remove-orphans

        return 0
    fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _docker_compose_start: \"$1\" file not found\n"; return 1; fi

    _echo_info "$(_get_docker_compose) --file \"$1\" up --detach --remove-orphans\n"
    $(_get_docker_compose) --file "$1" up --detach --remove-orphans
}

## Stop container stack with docker compose
##
## {
##   "namespace": "docker",
##   "depends": [
##     "_get_docker_compose",
##     "_echo_info"
##   ]
## }
_docker_compose_stop() {
    # Synopsis: _docker_compose_stop

    _echo_info "$(_get_docker_compose) stop\n"
    $(_get_docker_compose) stop
}

## Execute command in the given docker container
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_NAME",
##       "type": "str",
##       "description": "The name of the container to run.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "COMMAND",
##       "type": "str",
##       "description": "The command to execute.",
##       "nullable": false
##     },
##     {
##       "position": 3,
##       "name": "USER",
##       "type": "str",
##       "description": "The user name."
##     }
##   ]
## }
_docker_exec() {
    # Synopsis: _docker_exec <CONTAINER_NAME> <COMMAND> [USER]
    #   CONTAINER_NAME: The name of the container to run.
    #   COMMAND:        The command to execute.
    #   USER:           (optional) The user name.

    _check_installed docker

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _docker_exec: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 3 ]; then _echo_danger "error: _docker_exec: too many arguments ($#)\n"; return 1; fi

    if [ -z "$3" ]; then
        _echo_info "docker exec --interactive --tty \"$1\" $2\n"
        # shellcheck disable=SC2086
        docker exec --interactive --tty "$1" $2

        return 0
    fi

    _echo_info "docker exec --interactive --tty --user \"$3\" \"$1\" $2\n"
    # shellcheck disable=SC2086
    docker exec --interactive --tty --user "$3" "$1" $2
}

## Kill all running containers with docker
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
_docker_kill_all() {
    # Synopsis: _docker_kill_all

    _check_installed docker

    _echo_info "docker kill $(docker ps --quiet --format '{{.Names}}' | tr -s "\n" ' ')\n"
    # shellcheck disable=SC2046
    docker kill $(docker ps --quiet --format '{{.Names}}')
}

## Remove given docker container
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_NAME",
##       "type": "str",
##       "description": "The name of the container to run.",
##       "nullable": false
##     }
##   ]
## }
_docker_rm() {
    # Synopsis: _docker_rm <CONTAINER_NAME>
    #   CONTAINER_NAME: The name of the container to remove.

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _docker_rm: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _docker_rm: too many arguments ($#)\n"; return 1; fi

    _echo_info "docker rm \"$1\"\n"
    docker rm "$1"
}

## Run local atmoz_sftp server
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "USERNAME",
##       "type": "str",
##       "description": "The name of the container to run.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "PASSWORD",
##       "type": "str",
##       "description": "The password for the sftp server access.",
##       "nullable": false
##     },
##     {
##       "position": 3,
##       "name": "NETWORK_MODE",
##       "type": "str",
##       "description": "The user name.",
##       "constraint": "/^(bridge|host)$/"
##     },
##     {
##       "position": 4,
##       "name": "FOLDER_PATH",
##       "type": "folder",
##       "description": "The path to the volume folder."
##     }
##   ]
## }
_docker_run_atmoz_sftp() {
    # Synopsis: _docker_run_atmoz_sftp <USERNAME> <PASSWORD> [NETWORK_MODE] [FOLDER_PATH]
    #   USERNAME:     The username for the sftp server access.
    #   PASSWORD:     The password for the sftp server access.
    #   NETWORK_MODE: (optional) Set network mode (bridge|host). Defaults to "bridge".
    #   FOLDER_PATH:  (optional) The path to the volume folder.
    #   note:         atmoz_sftp documentation: https://github.com/atmoz/sftp

    _check_installed docker

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _docker_run_atmoz_sftp: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 4 ]; then _echo_danger "error: _docker_run_atmoz_sftp: too many arguments ($#)\n"; return 1; fi

    set -- "$1" "$2" "${3:-bridge}" "$4"

    if [ -z "$4" ]; then
        _echo_info "docker run --network \"${3:-bridge}\" --publish 22:22 --detach --rm --name atmoz_sftp atmoz/sftp \"$1:$2\"\n"
        docker run --network "${3:-bridge}" --publish 22:22 --detach --rm --name atmoz_sftp atmoz/sftp "$1:$2"

        return 0
    fi

    set -- "$1" "$2" "$3" "$(realpath "$4")"
    if [ ! -d "$4" ]; then _echo_danger "error: _docker_run_atmoz_sftp: \"$4\" folder not found\n"; return 1; fi

    _echo_info "docker run --volume=\"$4:/home/shared\" --network \"${3:-bridge}\" --publish 22:22 --detach --rm --name atmoz_sftp atmoz/sftp \"$1:$2\"\n"
    docker run --volume="$4:/home/shared" --network "${3:-bridge}" --publish 22:22 --detach --rm --name atmoz_sftp atmoz/sftp "$1:$2"
}

## Spawn a new container with given image, name, command and volume
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "IMAGE",
##       "type": "str",
##       "description": "The name of the container image to run.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "NAME",
##       "type": "str",
##       "description": "Assign a name to the container.",
##       "nullable": false
##     },
##     {
##       "position": 3,
##       "name": "COMMAND",
##       "type": "str",
##       "description": "The command to run inside provided container.",
##       "nullable": false
##     },
##     {
##       "position": 4,
##       "name": "FOLDER_PATH",
##       "type": "folder",
##       "description": "The path to the volume folder."
##     }
##   ]
## }
_docker_run() {
    # Synopsis: _docker_run <IMAGE> <NAME> <COMMAND> [FOLDER_PATH]
    #   IMAGE:       The name of the container image to run.
    #   NAME:        Assign a name to the container.
    #   COMMAND:     The command to run inside provided container.
    #   FOLDER_PATH: (optional) The path to the volume folder.

    _check_installed docker

    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then _echo_danger 'error: _docker_run: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 4 ]; then _echo_danger "error: _docker_run: too many arguments ($#)\n"; return 1; fi

    if [ -z "$4" ]; then
        _echo_info "docker run --detach --rm --interactive --tty --name \"$2\" \"$1\" $3\n"
        # shellcheck disable=SC2086
        docker run --detach --rm --interactive --tty --name "$2" "$1" $3

        return 0
    fi

    set -- "$1" "$2" "$3" "$(realpath "$4")"
    if [ ! -d "$4" ]; then _echo_danger "error: _docker_run: \"$3\" folder not found\n"; return 1; fi

    _echo_info "docker run --detach --rm --interactive --tty --volume=\"$4:/home\" --workdir=\"/home\" --name \"$2\" \"$1\" $3\n"
    # shellcheck disable=SC2086
    docker run --detach --rm --interactive --tty --volume="$4:/home" --workdir="/home" --name "$2" "$1" $3
}

## Run local whoami server
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
_docker_run_whoami() {
    # Synopsis: _docker_run_whoami
    #   note: traefik_whoami documentation: https://github.com/traefik/whoami

    _check_installed docker

    if [ $# -gt 0 ]; then _echo_danger "error: _docker_run_whoami: too many arguments ($#)\n"; return 1; fi

    _echo_info "docker run --detach --publish-all --rm --name whoami traefik/whoami\n"
    docker run --detach --publish-all --rm --name whoami traefik/whoami
}

## Print docker status
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
_docker_status() {
    # Synopsis: _docker_status

    _check_installed docker

    _echo_info "docker inspect --format '{{truncate .ID 13}} {{slice .Name 1}} {{range .NetworkSettings.Networks}}{{if .IPAddress}}http://{{.IPAddress}} {{end}}{{end}}{{range \$p, \$c := .NetworkSettings.Ports}}{{\$p}} {{end}}' \$(docker ps --all --quiet) | column -t\n"
    # shellcheck disable=SC2046
    docker inspect --format '{{truncate .ID 13}} {{slice .Name 1}} {{range .NetworkSettings.Networks}}{{if .IPAddress}}http://{{.IPAddress}} {{end}}{{end}}{{range $p, $c := .NetworkSettings.Ports}}{{$p}} {{end}}' $(docker ps --all --quiet) | column -t
}

## Find container name from string
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "STRING",
##       "type": "str",
##       "description": "The string to find among running containers.",
##       "nullable": false
##     }
##   ]
## }
_find_container_name() {
    # Synopsis: _find_container_name <STRING>
    #   STRING: The string to find among running containers.

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _find_container_name: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _find_container_name: too many arguments ($#)\n"; return 1; fi

    # sanitize input
    set -- "$(printf '%s' "$1" | sed 's/[^a-zA-Z0-9_-]//g')"

    # get container names
    # shellcheck disable=SC2046
    docker inspect --format '{{slice .Name 1}}' $(docker ps --all --quiet) | grep "$1" | head -n1
}

## Get container id from name
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_NAME",
##       "type": "str",
##       "description": "The name of the container to run.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "TRUNCATE",
##       "type": "bool",
##       "description": "Truncate id to 12 characters long.",
##       "default": true
##     }
##   ]
## }
_get_container_id() {
    # Synopsis: _get_container_id <CONTAINER_NAME> [TRUNCATE]
    #   CONTAINER_NAME: The container name.
    #   TRUNCATE:       Truncate id to 12 characters long. Defaults to "true".

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _get_container_id: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_container_id: too many arguments ($#)\n"; return 1; fi

    set -- "$1" "${2:-true}"

    if [ "$2" = false ]; then
        docker inspect "$1" --format='{{.Id}}' || return 1

        return 0
    fi

    docker inspect "$1" --format='{{truncate .Id 13}}'
}

## Get running container ip
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_NAME|CONTAINER_ID",
##       "type": "str",
##       "description": "The name or the id of the docker container.",
##       "nullable": false
##     }
##   ]
## }
_get_container_ip() {
    # Synopsis: _get_container_ip <CONTAINER_NAME|CONTAINER_ID>
    #   CONTAINER_NAME: The name of the docker container.
    #   CONTAINER_ID:   The id of the docker container.

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _get_container_ip: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_container_ip: too many arguments ($#)\n"; return 1; fi

    if [ "$(docker inspect "$1" --format '{{.State.Running}}' 2>/dev/null)" != true ]; then

        return 1
    fi

    set -- "$1" "$(docker inspect "$1" --format '{{.NetworkSettings.Networks.IPAddress}}' 2>/dev/null)"

    if [ "$2" = '<no value>' ]; then
        set -- "$1" "$(docker inspect "$1" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)"
    fi

    if [ -z "$2" ]; then
        printf '%s' 127.0.0.1

        return 0
    fi

    printf '%s' "$2"
}

## Get container name from id
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_ID",
##       "type": "str",
##       "description": "The container id.",
##       "nullable": false
##     }
##   ]
## }
_get_container_name() {
    # Synopsis: _get_container_name <CONTAINER_ID>
    #   CONTAINER_ID: The container id.

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _get_container_name: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_container_name: too many arguments ($#)\n"; return 1; fi

    docker inspect "$1" --format '{{slice .Name 1}}'
}

## Return docker compose command
##
## {
##   "namespace": "docker",
##   "requires": [
##     "command",
##     "docker"
##   ],
##   "depends": [
##     "_echo_danger"
##   ]
## }
_get_docker_compose() {
    # Synopsis: _get_docker_compose

    if [ "$(docker compose >/dev/null 2>&1)" ]; then
        echo 'docker compose'

        return 0
    fi

    if [ -x "$(command -v docker-compose)" ]; then
        echo 'docker-compose'

        return 0
    fi

    _echo_danger "error: \"$(basename "${0}")\" requires docker-compose or docker compose plugin\n"

    exit 1
}

## Checks if given container is running
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_NAME|CONTAINER_ID",
##       "type": "str",
##       "description": "The name or the id of the docker container.",
##       "nullable": false
##     }
##   ]
## }
_is_container_running() {
    # Synopsis: _is_container_running <CONTAINER_NAME|CONTAINER_ID>
    #   CONTAINER_NAME: The name of the docker container.
    #   CONTAINER_ID:   The id of the docker container.

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _is_container_running: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _is_container_running: too many arguments ($#)\n"; return 1; fi

    if [ "$(docker inspect "$1" --format '{{.State.Running}}' 2>/dev/null)" = true ]; then

        return 0
    fi

    return 1
}

## Wait for postgresql container to start with docker
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_spin",
##     "_echo_danger",
##     "_echo_success",
##     "_echo_warning"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_NAME",
##       "type": "str",
##       "description": "The name of the docker container.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "USERNAME",
##       "type": "str",
##       "description": "The psql username.",
##       "default": ""
##     }
##   ]
## }
_wait_for_postgres() {
    # Synopsis: _wait_for_postgres <CONTAINER_NAME> [USERNAME]
    #   CONTAINER_NAME: The name of the postgresql docker container.
    #   USERNAME:       (optional) The psql username. Defaults to "".

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _wait_for_postgres: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _wait_for_postgres: too many arguments ($#)\n"; return 1; fi

    if [ -n "$2" ]; then
        set -- "$1" "--username $2"
    fi

    _echo_warning "Waiting for \"$1\" database to start."

    while [ ! "$(docker exec "$1" psql "$2" -l 2>/dev/null)" ]; do
        _spin 600
    done

    _echo_success "\n\"$1\" is runnning.\n"
}

## Wait for rabbitmq container to start with docker
##
## {
##   "namespace": "docker",
##   "requires": [
##     "docker"
##   ],
##   "depends": [
##     "_check_installed",
##     "_spin",
##     "_echo_danger",
##     "_echo_success",
##     "_echo_warning"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "CONTAINER_NAME",
##       "type": "str",
##       "description": "The name of the docker container.",
##       "nullable": false
##     }
##   ]
## }
_wait_for_rabbit() {
    # Synopsis: _wait_for_rabbit <CONTAINER_NAME>
    #   CONTAINER_NAME: The name of the rabbitmq docker container.

    _check_installed docker

    if [ -z "$1" ]; then _echo_danger 'error: _wait_for_rabbit: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _wait_for_rabbit: too many arguments ($#)\n"; return 1; fi

    _echo_warning "Waiting for \"$1\" to start."

    while ! docker exec "$1" rabbitmqctl wait --pid 1 --timeout 1 2>/dev/null | grep -q "Applications 'rabbit_and_plugins' are running"; do
        _spin 600
    done

    _echo_success "\n\"$1\" is runnning.\n"
}

#--------------------------------------------------
#_ Help
#--------------------------------------------------

## Print help for provider shoe script
##
## {
##   "namespace": "help",
##   "depends": [
##     "_alert_primary",
##     "_echo_danger",
##     "_get_constants",
##     "_get_flags",
##     "_get_function_shoedoc",
##     "_get_options",
##     "_get_padding",
##     "_get_script_shoedoc",
##     "_get_shoedoc_description",
##     "_get_shoedoc_title",
##     "_print_commands",
##     "_print_constants",
##     "_print_description",
##     "_print_flags",
##     "_print_infos",
##     "_print_options",
##     "_print_synopsis",
##     "_print_usage"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "FUNCTION_NAME",
##       "type": "str",
##       "description": "The function name to get help for.",
##     }
##   ]
## }
_help() {
    # Synopsis: _help <FILE_PATH>
    #   FILE_PATH: The path to the input file.
    #   FUNCTION_NAME: The function name to get help for.

    if [ -z "$1" ]; then _echo_danger 'error: _help: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _help: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2"
    if [ ! -f "$1" ]; then _echo_danger "error: _help: \"$1\" file not found\n"; return 1; fi

    if [ -z "$2" ]; then
        __padding__=$(_get_padding "$1")
        __annotations__=$(_get_script_shoedoc "$1")

        _alert_primary "$(_get_shoedoc_title "${__annotations__}")"

        _print_infos "$1"
        _print_description "$(_get_shoedoc_description "${__annotations__}")"
        _print_usage "$1"

        if [ -n "$(_get_constants "$1")" ]; then
            _print_constants "$1" "${__padding__}"
        fi

        if [ -n "$(_get_flags "$1")" ]; then
            _print_flags "$1" "${__padding__}"
        fi

        if [ -n "$(_get_options "$1")" ]; then
            _print_options "$1" "${__padding__}"
        fi

        _print_commands "$1" "${__padding__}"
        exit 0
    fi

    _alert_primary "$2"
    if [ -x "$(command -v jq)" ]; then
        __json__="$(_parse_shoedoc "$1" "$2")"
        if [ -n "${__json__}" ]; then
            _echo_primary "$(printf '%s' "${__json__}" | jq -r '.summary')\n\n"
            _echo_secondary "$(_print_synopsis "${__json__}")\n"
            exit 0
        fi
    fi
    _echo_info "$(_get_function_shoedoc "$0" "$2")\n"
}

## List commands of the provided shoe script (used by "help" command)
##
## {
##   "namespace": "help",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger",
##     "_echo_warning"
##   ],
##   "assumes": [
##     "PRIMARY",
##     "SUCCESS",
##     "WARNING"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 12
##     }
##   ]
## }
_print_commands() {
    # Synopsis: _print_commands <FILE_PATH> [PADDING]
    #   FILE_PATH: The path to the input file.
    #   PADDING:   (optional) Padding length (default: 12)
    #   note:      "awk: %*x formats are not supported"

    if [ -z "$1" ]; then _echo_danger 'error: _print_commands: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _print_commands: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-12}"
    if [ ! -f "$1" ]; then _echo_danger "error: _print_commands: \"$1\" file not found\n"; return 1; fi

    _echo_warning 'Commands:\n'
    awk -v WARNING="${_WARNING}" -v SUCCESS="${_SUCCESS}" -v PRIMARY="${_PRIMARY}" \
    '/^### /{printf"\n%s%s:%s\n",WARNING,substr($0,5),PRIMARY}
    /^## /{if (annotation=="") annotation=substr($0,4)}
    /^(function +)?[a-zA-Z0-9_]+ *\(\)/ {            # matches a function (ignoring curly braces)
        function_name=substr($0,1,index($0,"(")-1);  # truncate string at opening round bracket
        sub("^function ","",function_name);          # remove leading "function " if present
        gsub(" +","",function_name);                 # trim whitespaces
        if (annotation!="" && substr($0,1,1) != "_") # ignore private functions
        printf "%s  %-'"$2"'s %s%s\n",SUCCESS,function_name,PRIMARY,annotation;
    } !/^## */{annotation=""}' "$1"
    printf '\n'

}

## List constants of the provided shoe script (used by "help" command)
##
## {
##   "namespace": "help",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger",
##     "_echo_warning"
##   ],
##   "assumes": [
##     "EOL",
##     "INFO",
##     "PRIMARY",
##     "SUCCESS",
##     "WARNING"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 12
##     }
##   ]
## }
_print_constants() {
    # Synopsis: _print_constants <FILE_PATH> [PADDING]
    #   FILE_PATH: The path to the input file.
    #   PADDING:   (optional) Padding length (default: 12)
    #   note:      "awk: %*x formats are not supported"

    if [ -z "$1" ]; then _echo_danger 'error: _print_constants: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _print_constants: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-12}"
    if [ ! -f "$1" ]; then _echo_danger "error: _print_constants: \"$1\" file not found\n"; return 1; fi

    _echo_warning 'Constants:\n'
    awk -F '=' -v SUCCESS="${_SUCCESS}" -v PRIMARY="${_PRIMARY}" -v INFO="${_INFO}" -v WARNING="${_WARNING}" -v EOL="${_EOL}" \
    '/^[A-Z0-9_]+=.+$/ {
        if (substr(PREV,1,3) == "## " && substr($0,1,1) != "_")
        printf "%s  %-'"$2"'s %s%s%s (value: %s%s%s)%s",SUCCESS,$1,PRIMARY,substr(PREV,4),INFO,WARNING,$2,INFO,EOL
    } { PREV = $0 }' "$1"
    printf '\n'
}

## Print provided text formatted as a description (used by "help" command)
##
## {
##   "namespace": "help",
##   "depends": [
##     "_echo_primary",
##     "_echo_warning"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "DESCRIPTION",
##       "type": "str",
##       "description": "A string containing script description.",
##       "nullable": false
##     }
##   ]
## }
_print_description() {
    # Synopsis: _print_description <DESCRIPTION>
    #   DESCRIPTION: A string containing script description.

    _echo_warning 'Description:\n'
    _echo_primary "$(printf '%s' "$1" | fold -w 64 -s)\n\n" 2
}

## List flags of the provided shoe script (used by "help" command)
##
## {
##   "namespace": "help",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger",
##     "_echo_warning"
##   ],
##   "assumes": [
##     "PRIMARY",
##     "SUCCESS"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 12
##     }
##   ]
## }
_print_flags() {
    # Synopsis: _print_flags <FILE_PATH> [PADDING]
    #   FILE_PATH: The path to the input file.
    #   PADDING:   (optional) Padding length (default: 12)
    #   note:      "awk: %*x formats are not supported"

    if [ -z "$1" ]; then _echo_danger 'error: _print_flags: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _print_flags: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" $((${2:-12}-2))
    if [ ! -f "$1" ]; then _echo_danger "error: _print_flags: \"$1\" file not found\n"; return 1; fi

    _echo_warning 'Flags:\n'
    awk -F '=' -v SUCCESS="${_SUCCESS}" -v PRIMARY="${_PRIMARY}" '/^[a-zA-Z0-9_]+=false$/ {
        if (substr(PREV, 1, 3) == "## " && $1 != toupper($1) && substr($0, 1, 1) != "_")
        printf "%s  --%-'"$2"'s %s%s\n",SUCCESS,$1,PRIMARY,substr(PREV,4)
    } { PREV = $0 }' "$1"
    printf '\n'
}

## Print infos of the provided shoe script (used by "help" command)
##
## {
##   "namespace": "help",
##   "depends": [
##     "_get_script_shoedoc",
##     "_get_shoedoc_tag",
##     "_echo_danger",
##     "_echo_primary",
##     "_echo_success",
##     "_echo_warning"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     }
##   ]
## }
_print_infos() {
    # Synopsis: _print_infos <FILE_PATH>
    #   FILE_PATH: The path to the input file.

    if [ -z "$1" ]; then _echo_danger 'error: _print_infos: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _print_infos: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _print_infos: \"$1\" file not found\n"; return 1; fi

    __annotations__=$(_get_script_shoedoc "$1")

    _echo_warning 'Infos:\n'
    _echo_success 'author'  2 8; _echo_primary "$(_get_shoedoc_tag "${__annotations__}" 'author')\n"
    _echo_success 'version' 2 8; _echo_primary "$(_get_shoedoc_tag "${__annotations__}" 'version')\n"
    _echo_success 'link'    2 8; _echo_primary "$(_get_shoedoc_tag "${__annotations__}" 'link')\n"
    printf '\n'
}

## List options of the provided shoe script (used by "help" command)
##
## {
##   "namespace": "help",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger",
##     "_echo_warning"
##   ],
##   "assumes": [
##     "DEFAULT",
##     "EOL",
##     "INFO",
##     "SUCCESS",
##     "WARNING"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "PADDING",
##       "type": "int",
##       "description": "Padding length.",
##       "default": 12
##     }
##   ]
## }
_print_options() {
    # Synopsis: _print_options <FILE_PATH> [PADDING]
    #   FILE_PATH: The path to the input file.
    #   PADDING:   (optional) Padding length (default: 12)
    #   note:      "awk: %*x formats are not supported"

    if [ -z "$1" ]; then _echo_danger 'error: _print_options: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _print_options: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" $((${2:-12}-2))
    if [ ! -f "$1" ]; then _echo_danger "error: _print_options: \"$1\" file not found\n"; return 1; fi

    _echo_warning "Options:\n"
    awk  -F '=' -v WARNING="${_WARNING}" -v SUCCESS="${_SUCCESS}" -v INFO="${_INFO}" -v DEFAULT="${_DEFAULT}" -v EOL="${_EOL}" \
    '/^[a-zA-Z0-9_]+=.+$/ {
        if (substr(PREV,1,3) == "## " && $1 != toupper($1) && $2 != "false" && substr($0,1,1) != "_") {
            if (match(PREV,/ \/.+\//)) {
                # if option has constaint
                CONSTRAINT=substr(PREV,RSTART,RLENGTH);
                ANNOTATION=substr(PREV,4,length(PREV)-length(CONSTRAINT)-3);
                printf "%s  --%-'"$2"'s %s%s%s %s%s (default: %s%s%s)%s",SUCCESS,$1,DEFAULT,ANNOTATION,SUCCESS,CONSTRAINT,INFO,WARNING,$2,INFO,EOL
            } else {
                ANNOTATION=substr(PREV,4);
                printf "%s  --%-'"$2"'s %s%s%s (default: %s%s%s)%s",SUCCESS,$1,DEFAULT,ANNOTATION,INFO,WARNING,$2,INFO,EOL
            }
        }
    } { PREV = $0 }' "$1"
    printf '\n'
}

## Print usage of the provided shoe script (used by "help" command)
##
## {
##   "namespace": "help",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger",
##     "_echo_info",
##     "_echo_success",
##     "_echo_warning"
##   ],
##   "assumes": [
##     "DEFAULT",
##     "INFO",
##     "SUCCESS",
##     "WARNING"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     }
##   ]
## }
_print_usage() {
    # Synopsis: _print_usage <FILE_PATH>
    #   FILE_PATH: The path to the input file.

    if [ -z "$1" ]; then _echo_danger 'error: _print_usage: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _print_usage: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _print_usage: \"$1\" file not found\n"; return 1; fi

    _echo_warning 'Usage:\n'
    _echo_info "sh $(basename "$1") <" 2; _echo_success 'command'; _echo_info '> '
    # options
    awk -F '=' -v INFO="${_INFO}" -v SUCCESS="${_SUCCESS}" -v WARNING="${_WARNING}" -v DEFAULT="${_DEFAULT}" \
    '/^[a-zA-Z0-9_]+=.+$/ {
        if (substr(PREV,1,3) != "## " || $1 == toupper($1) || substr($1,1,1) == "_") next;
        if ($2 == "false") {printf "%s[%s--%s%s]%s ",INFO,SUCCESS,$1,INFO,DEFAULT;next}
        printf "%s[%s--%s %s%s%s]%s ",INFO,SUCCESS,$1,WARNING,$2,INFO,DEFAULT
    } {PREV = $0} END {print "\n"}' "$1"
}

#--------------------------------------------------
#_ Install
#--------------------------------------------------

## Install script via copy
##
## {
##   "namespace": "install",
##   "depends": [
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     }
##   ]
## }
_copy_install() {
    # Synopsis: _copy_install <FILE_PATH> [ALIAS]
    #   FILE_PATH: The path to the input file.
    #   ALIAS:     (optional) The alias of the script to install. Defaults to the basename of the provided file
    #   note:      Creates a symbolic link in the /usr/local/bin/ directory.

    if [ -z "$1" ]; then _echo_danger 'error: _copy_install: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _copy_install: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-"$(basename "$1" .sh)"}"
    if [ ! -f "$1" ]; then _echo_danger "error: _copy_install: \"$1\" file not found\n"; return 1; fi

    _echo_info "sudo cp -a \"$1\" \"/usr/local/bin/$2\"\n"
    sudo cp -a "$1" "/usr/local/bin/$2"
}

## Generates an autocomplete script for the provided file
##
## {
##   "namespace": "install",
##   "depends": [
##     "_get_comspec",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     }
##   ]
## }
_generate_autocomplete() {
    # Synopsis: _generate_autocomplete <FILE_PATH> [ALIAS]
    #   FILE_PATH: The path to the input file.
    #   ALIAS:     (optional) The alias of the script to autocomplete. Defaults to the basename of the provided file
    #   note:      This function creates a completion script named "<ALIAS>-completion.sh" in the same directory as the script itself.
    #              Refer to https://iridakos.com/programming/2018/03/01/bash-programmable-completion-tutorial for details on how to configure shell autocompletions.
    #              Or read the official docmentation for "complete" https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html#Programmable-Completion-Builtins

    if [ -z "$1" ]; then _echo_danger 'error: _generate_autocomplete: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _generate_autocomplete: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-"$(basename "$1" .sh)"}"
    if [ ! -f "$1" ]; then _echo_danger "error: _generate_autocomplete: \"$1\" file not found\n"; return 1; fi

    _echo_info "printf '#!/bin/bash\\\ncomplete -f -d -W \"%s\" \"%s\"' \"$(_get_comspec "$1")\" \"$2\" > \"$(dirname "$1")/$2-completion.sh\"\n"
    printf '#!/bin/bash\ncomplete -f -d -W "%s" "%s"' "$(_get_comspec "$1")" "$2" > "$(dirname "$1")/$2-completion.sh"
}

## Creates a system-wide autocomplete script for the provided file
##
## {
##   "namespace": "install",
##   "depends": [
##     "_get_comspec",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     }
##   ]
## }
_generate_global_autocomplete() {
    # Synopsis: _generate_global_autocomplete <FILE_PATH> [ALIAS]
    #   FILE_PATH: The path to the input file.
    #   ALIAS:     (optional) The alias of the script to autocomplete. Defaults to the basename of the provided file
    #   note:      This function creates a completion script named "<ALIAS>" (where "<ALIAS>" is the basename of the provided file)
    #              in the /etc/bash_completion.d/ directory, enabling autocompletion for all users on the system.
    #              It uses sudo for file creation in a system directory, requiring root privileges.

    if [ -z "$1" ]; then _echo_danger 'error: _generate_global_autocomplete: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _generate_global_autocomplete: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-"$(basename "$1" .sh)"}"
    if [ ! -f "$1" ]; then _echo_danger "error: _generate_global_autocomplete: \"$1\" file not found\n"; return 1; fi

    _echo_info "printf '#!/bin/bash\\\ncomplete -W \"%s\" \"%s\"' \"$(_get_comspec "$1")\" \"$2\" | sudo tee \"/etc/bash_completion.d/$2\"\n"
    printf '#!/bin/bash\ncomplete -W "%s" "%s"' "$(_get_comspec "$1")" "$2" | sudo tee "/etc/bash_completion.d/$2"
}

## Generate comspec string for the provided file
##
## {
##   "namespace": "install",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     }
##   ]
## }
_get_comspec() {
    # Synopsis: _get_comspec <FILE_PATH>
    #   FILE_PATH: The path to the input file.

    if [ -z "$1" ]; then _echo_danger 'error: _get_comspec: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_comspec: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_comspec: \"$1\" file not found\n"; return 1; fi

    awk '/^(function *)?[a-zA-Z0-9_]+ *\(\) *\{/ {
        sub("^function ",""); gsub("[ ()]","");
        FUNCTION = substr($0,1,index($0,"{"));
        sub("{$","",FUNCTION);
        if (substr(PREV,1,3) == "## " && substr($0,1,1) != "_")
        printf "%s ",FUNCTION,substr(PREV,4)
    } {PREV = $0}' "$1"

    awk -F '=' '/^[a-zA-Z0-9_]+=.+$/ {
        if (substr(PREV,1,3) == "## " && $1 != toupper($1) && substr($0,1,1) != "_") {
            printf "--%s ",$1
        }
    } {PREV = $0}' "$1"
}

## Install script and enable completion
##
## {
##   "namespace": "install",
##   "depends": [
##     "_copy_install",
##     "_generate_autocomplete",
##     "_generate_global_autocomplete",
##     "_is_installed",
##     "_set_completion_autoload",
##     "_symlink_install",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     },
##     {
##       "position": 3,
##       "name": "GLOBAL",
##       "type": "bool",
##       "description": "Install globally.",
##       "default": false
##     }
##   ]
## }
_install() {
    # Synopsis: _install <FILE_PATH> [ALIAS] [GLOBAL]
    #   FILE_PATH: The path to the input file.
    #   ALIAS:     (optional) The alias of the script to install. Defaults to the basename of the provided script.
    #   GLOBAL:    (optional) Install globally. Defaults to "false".

    if [ -z "$1" ]; then _echo_danger 'error: _install: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 3 ]; then _echo_danger "error: _install: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-"$(basename "$1" .sh)"}" "${3:-false}"
    if [ ! -f "$1" ]; then _echo_danger "error: _install: \"$1\" file not found\n"; return 1; fi

    if [ "$3" = true ]; then
        _copy_install "$1" "$2"
        _generate_global_autocomplete "$1" "$2"
    else
        _symlink_install "$1" "$2"
        _generate_autocomplete "$1" "$2"
    fi

    if _is_installed zsh; then
        # https://superuser.com/questions/886132/where-is-the-zshrc-file-on-mac
        if [ "$(uname)" = 'Darwin' ]; then
            touch ~/.zshrc
        fi
        _set_completion_autoload ~/.zshrc "$1" "$2" || true
    fi

    if _is_installed bash; then
        # set default bash profile
        if [ ! -f ~/.bashrc ] || [ "$(uname)" = 'Darwin' ]; then
            _set_completion_autoload ~/.profile "$1" "$2"
        else
            _set_completion_autoload ~/.bashrc "$1" "$2"
        fi
    fi
}

## Remove completion script autoload
##
## {
##   "namespace": "install",
##   "depends": [
##     "_sed_i",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SHELL_CONFIG_FILE",
##       "type": "file",
##       "description": "The path to the shell configuration file to update (e.g., ~/.bashrc, ~/.zshrc).",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     }
##   ]
## }
_remove_completion_autoload() {
    # Synopsis: _remove_completion_autoload <SHELL_CONFIG_FILE> [ALIAS]
    # Removes an autoload line for a completion script from a shell configuration file.
    #   SHELL_CONFIG_FILE: The path to the shell configuration file to update (e.g., ~/.bashrc, ~/.zshrc).
    #   ALIAS:             (optional) The alias of the script to remove. Defaults to the basename of the provided file

    if [ $# -lt 1 ]; then _echo_danger 'error: _remove_completion_autoload: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _remove_completion_autoload: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-"$(basename "$1" .sh)"}"
    if [ ! -f "$1" ]; then _echo_danger "error: _remove_completion_autoload: \"$1\" file not found\n"; return 1; fi

    _echo_info "$(_sed_i) \"/^###> $2$/,/^###< $2$/d\" \"$1\"\n"
    $(_sed_i) "/^###> $2$/,/^###< $2$/d" "$1"

    # collapse blank lines
    # The N command reads the next line into the pattern space (the line being processed).
    # The remaining expression checks if the pattern space now consists of two empty lines (^\n$).
    $(_sed_i) '/^$/{N;s/^\n$//;}' "$1"
}

## Adds an autoload line for completion script to a shell configuration file
##
## {
##   "namespace": "install",
##   "depends": [
##     "_collapse_blank_lines",
##     "_sed_i",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SHELL_CONFIG_FILE",
##       "type": "file",
##       "description": "The path to the shell configuration file to update (e.g., ~/.bashrc, ~/.zshrc).",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "SCRIPT_FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 3,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     }
##   ]
## }
_set_completion_autoload() {
    # Synopsis: _set_completion_autoload <SHELL_CONFIG_FILE_PATH> <SCRIPT_FILE_PATH> [ALIAS]
    #   SHELL_CONFIG_FILE_PATH: The path to the shell configuration file to be modified (e.g., ~/.bashrc, ~/.zshrc).
    #   SCRIPT_FILE_PATH:       The path to the input file.
    #   ALIAS:                  (optional) The alias of the input script. Defaults to the basename of the provided file

    if [ -z "$1" ]  || [ -z "$2" ]; then _echo_danger 'error: _set_completion_autoload: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 3 ]; then _echo_danger "error: _set_completion_autoload: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$(realpath "$2")" "${3:-"$(basename "$2" .sh)"}"
    if [ ! -f "$1" ]; then _echo_danger "error: _set_completion_autoload: \"$1\" file not found\n"; return 1; fi
    if [ ! -f "$2" ]; then _echo_danger "error: _set_completion_autoload: \"$2\" file not found\n"; return 1; fi

    # declare inner function
    __set_completion_autoload() {
        # Synopsis: __set_completion_autoload <SHELL_CONFIG_FILE_PATH> <COMPLETION_FILE_PATH> <ALIAS>
        # remove previous install if any
        $(_sed_i) "/^###> $3$/,/^###< $3$/d" "$1"

        _echo_info "printf '\\\n###> %s\\\nsource %s\\\n###< %s\\\n' \"$3\" \"$2\" \"$3\" >> \"$1\"\n"
        printf '\n###> %s\nsource %s\n###< %s\n' "$3" "$2" "$3" >> "$1"

        _collapse_blank_lines "$1"
    }

    # set global completion file path
    if [ -f "/etc/bash_completion.d/$3" ]; then
        __set_completion_autoload "$1" "/etc/bash_completion.d/$3" "$3"
    fi

    # set completion file path
    if [ -f "$(dirname "$2")/$3-completion.sh" ]; then
        __set_completion_autoload "$1" "$(dirname "$2")/$3-completion.sh" "$3"
    fi
}

## Install script via symlink
##
## {
##   "namespace": "install",
##   "depends": [
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     }
##   ]
## }
_symlink_install(){
    # Synopsis: _symlink_install <FILE_PATH> [ALIAS]
    #   FILE_PATH: The path to the input file.
    #   ALIAS:     (optional) The alias of the script to install. Defaults to the basename of the provided file
    #   note:      Creates a symbolic link in the /usr/local/bin/ directory.

    if [ -z "$1" ]; then _echo_danger 'error: _symlink_install some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _symlink_install too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-"$(basename "$1" .sh)"}"
    if [ ! -f "$1" ]; then _echo_danger "error: _symlink_install \"$1\" file not found\n"; return 1; fi

    _echo_info "sudo ln -s \"$1\" \"/usr/local/bin/$2\"\n"
    sudo ln -s "$1" "/usr/local/bin/$2"
}

## Uninstall script from system
##
## {
##   "namespace": "install",
##   "depends": [
##     "_remove_completion_autoload",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     }
##   ]
## }
_uninstall() {
    # Synopsis: _uninstall <FILE_PATH> [ALIAS]
    #   FILE_PATH: The path to the input file.
    #   ALIAS:     (optional) The alias of the script to uninstall. Defaults to the basename of the provided script.

    if [ -z "$1" ]; then _echo_danger 'error: _uninstall: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _uninstall: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-"$(basename "$1" .sh)"}"
    if [ ! -f "$1" ]; then _echo_danger "error: _uninstall: \"$1\" file not found\n"; return 1; fi

    _remove_completion_autoload ~/.zshrc "$2"
    _remove_completion_autoload ~/.bashrc "$2"
    _remove_completion_autoload ~/.profile "$2"

    _echo_info "rm -f \"$(dirname "$1")/$2-completion.sh\"\n"
    rm -f "$(dirname "$1")/$2-completion.sh"

    if [ -f "$1" ]; then
        _echo_info "sudo rm -f \"/usr/local/bin/$2\"\n"
        sudo rm -f "/usr/local/bin/$2"
    fi

    if [ -f "/etc/bash_completion.d/$2" ]; then
        _echo_info "sudo rm -f /etc/bash_completion.d/$2\n"
        sudo rm -f /etc/bash_completion.d/"$2"
    fi
}

## Updates given script from the provided URL
##
## {
##   "namespace": "install",
##   "requires": [
##     "curl",
##     "wget"
##   ],
##   "depends": [
##     "_copy_install",
##     "_generate_autocomplete",
##     "_generate_global_autocomplete",
##     "_install",
##     "_is_installed",
##     "_set_completion_autoload",
##     "_symlink_install",
##     "_uninstall",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "URL",
##       "type": "str",
##       "description": "The URL of the script to download and install.",
##       "nullable": false
##     },
##     {
##       "position": 3,
##       "name": "ALIAS",
##       "type": "str",
##       "description": "The alias of the script to install. Defaults to the basename of the provided file."
##     },
##     {
##       "position": 4,
##       "name": "GLOBAL",
##       "type": "bool",
##       "description": "Install globally.",
##       "default": false
##     }
##   ]
## }
_update() {
    # Synopsis: _update <FILE_PATH> <URL> [ALIAS] [GLOBAL]
    #   FILE_PATH: The path to the input file.
    #   URL:       The URL of the script to download and install.
    #   ALIAS:     (optional) The alias of the script to install. Defaults to the basename of the provided script.
    #   GLOBAL:    (optional) Install globally. Defaults to "false".

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _update: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 4 ]; then _echo_danger "error: _update: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2" "${3:-"$(basename "$1" .sh)"}" "${4:-false}"
    if [ ! -f "$1" ]; then _echo_danger "error: _update: \"$1\" file not found\n"; return 1; fi

    if _is_installed curl; then
        _echo_info "curl -sSL \"$2\" > \"$1\"\n"
        curl -sSL "$2" > "$1"

    elif _is_installed  wget; then
        _echo_info "wget -qO - \"$2\" > \"$1\"\n"
        wget -qO - "$2" > "$1"

    else
        _echo_danger "error: \"$0)\" requires curl, try: \"sudo apt-get install -y curl\"\n"
        return 1
    fi

    _uninstall "$1" "$3"
    _install "$1" "$3" "$4"
}

#--------------------------------------------------
#_ Network
#--------------------------------------------------

## Open in default browser
##
## {
##   "namespace": "network",
##   "depends": [
##     "_open",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "IP",
##       "type": "str",
##       "description": "Target IP address or domain.",
##       "default": "127.0.0.1"
##     },
##     {
##       "position": 2,
##       "name": "PORT",
##       "type": "int",
##       "description": "Destination port.",
##       "default": "8080",
##       "constraint": "/^[0-9]{1,5}$/"
##     },
##     {
##       "position": 3,
##       "name": "SCHEME",
##       "type": "str",
##       "description": "scheme - e.g. http.",
##       "default": "http"
##     }
##   ]
## }
_open_in_default_browser() {
    # Synopsis: _open_in_default_browser [IP] [PORT] [SCHEME]
    #   IP:     (optional) Target IP address or domain. (default=127.0.0.1)
    #   PORT:   (optional) Destination port. (default=8080)
    #   SCHEME: (optional) scheme - e.g. http. (default=http)

    if [ $# -gt 3 ]; then _echo_danger "error: _open_in_default_browser: too many arguments ($#)\n"; return 1; fi

    # set default values
    set -- "${1:-127.0.0.1}" "${2:-80}" "${3:-http}"

    _echo_info "nohup \"$(_open)\" \"$3://$1:$2\" >/dev/null 2>&1\n"
    nohup "$(_open)" "$3://$1:$2" >/dev/null 2>&1
}

## Serve given local directory with PHP
##
## {
##   "namespace": "network",
##   "requires": [
##     "php"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "DOCROOT",
##       "type": "folder",
##       "description": "The path to the root directory.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "IP",
##       "type": "str",
##       "description": "Target IP address or domain.",
##       "default": "127.0.0.1"
##     },
##     {
##       "position": 3,
##       "name": "PORT",
##       "type": "int",
##       "description": "Destination port.",
##       "default": "8080",
##       "constraint": "/^[0-9]{1,5}$/"
##     }
##   ]
## }
_php_serve() {
    # Synopsis: _php_serve <DOCROOT> [IP] [PORT]
    #   DOCROOT: The root directory.
    #   IP:      (optional) Local IP address. (default=127.0.0.1)
    #   PORT:    (optional) Destination port. (default=8080)

    _check_installed php

    if [ -z "$1" ]; then _echo_danger 'error: _php_serve: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 3 ]; then _echo_danger "error: _php_serve: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-127.0.0.1}" "${3:-8080}"
    if [ ! -d "$1" ]; then _echo_danger "error: _php_serve: \"$1\" folder not found\n"; return 1; fi

    _echo_info "php -d memory-limit=-1 -S \"$2:$3\" -t \"$1\"\n"
    php -d memory-limit=-1 -S "$2:$3" -t "$1"
}

## Serve given local directory with Python 3
##
## {
##   "namespace": "network",
##   "requires": [
##     "python3"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "DOCROOT",
##       "type": "folder",
##       "description": "The path to the root directory.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "IP",
##       "type": "str",
##       "description": "Target IP address or domain.",
##       "default": "127.0.0.1"
##     },
##     {
##       "position": 3,
##       "name": "PORT",
##       "type": "int",
##       "description": "Destination port.",
##       "default": "8080",
##       "constraint": "/^[0-9]{1,5}$/"
##     }
##   ]
## }
_py_serve() {
    # Synopsis: _py_serve <DOCROOT> [IP] [PORT]
    #   DOCROOT: The root directory.
    #   IP:      (optional) Local IP address. (default=127.0.0.1)
    #   PORT:    (optional) Destination port. (default=8080)

    _check_installed python3

    if [ -z "$1" ]; then _echo_danger 'error: _py_serve: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 3 ]; then _echo_danger "error: _py_serve: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-127.0.0.1}" "${3:-8080}"
    if [ ! -d "$1" ]; then _echo_danger "error: _php_serve: \"$1\" folder not found\n"; return 1; fi

    _echo_info "python3 -m http.server --directory \"$1\" --bind \"$2\" \"$3\"\n"
    python3 -m http.server --directory "$1" --bind "$2" "$3"
}

## Remove hostname from /etc/hosts
##
## {
##   "namespace": "network",
##   "depends": [
##     "_sed_i",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "HOSTNAME",
##       "type": "str",
##       "description": "The hostame to unset locally.",
##       "nullable": false
##     }
##   ]
## }
_remove_host() {
    # Synopsis: remove_host <HOSTNAME>
    #   HOSTNAME: The hostame to unset locally.

    if [ -z "$1" ]; then _echo_danger 'error: _remove_host: some mandatory parameter is missing\n'; return 1; fi

    _echo_info "sudo $(_sed_i) \"/$1/d\" /etc/hosts\n"
    eval "sudo $(_sed_i) \"/$1/d\" /etc/hosts"
}

## Set new host in /etc/hosts
##
## {
##   "namespace": "network",
##   "depends": [
##     "_remove_host",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "HOSTNAME",
##       "type": "str",
##       "description": "The hostame to set locally.",
##       "nullable": false
##     }
##   ]
## }
_set_host() {
    # Synopsis: set_host <HOSTNAME>
    #   HOSTNAME: The hostame to set locally.

    if [ -z "$1" ]; then _echo_danger 'error: _set_host: some mandatory parameter is missing\n'; return 1; fi

    _remove_host "$1"

    _echo_info "sudo /bin/sh -c \"echo \\\"127.0.0.1    $1\\\" >> /etc/hosts\"\n"
    sudo /bin/sh -c "echo \"127.0.0.1    $1\" >> /etc/hosts"
}

#--------------------------------------------------
#_ Reflexion
#--------------------------------------------------

## List constants from provided shoe script
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "GET_PRIVATE",
##       "type": "bool",
##       "description": "If set to \"true\", retrieves private constants as well.",
##       "default": false
##     }
##   ]
## }
_get_constants() {
    # Synopsis: _get_constants <SCRIPT_PATH> [GET_PRIVATE]
    #   SCRIPT_PATH: The path to the input script.
    #   GET_PRIVATE: (Optional) If set to 'true', retrieves private constants as well. (default=false)

    if [ -z "$1" ]; then _echo_danger 'error: _get_constants: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_constants: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-false}"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_constants: \"$1\" file not found\n"; return 1; fi

    awk -F '=' -v GET_PRIVATE="$2" \
    '/^[A-Z0-9_]+=.+$/ {
        if (GET_PRIVATE == "true") {
            print $1
        } else {
            if (substr(PREV,1,3) == "## " && substr($0,1,1) != "_") print $1
        }
    } {PREV = $0}' "$1"
}

## Get constaint for given variable from provided shoe script
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "VARIABLE_NAME",
##       "type": "str",
##       "description": "The variable to validate.",
##       "nullable": false
##     }
##   ]
## }
_get_constraint() {
    # Synopsis: _get_constraint <SCRIPT_PATH> <VARIABLE_NAME>
    #   SCRIPT_PATH:   The path to the input script.
    #   VARIABLE_NAME: The variable to validate.

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _get_constraint: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_constraint: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_constraint: \"$1\" file not found\n"; return 1; fi

    awk -F '=' -v NAME="$2" \
    '/^## /{if (annotation=="") annotation=substr($0,4)}
    /^[a-zA-Z0-9_]+=.+$/ {
        if (annotation!="" && $1 == NAME) {
            match(annotation, /\/.+\//); print substr(annotation, RSTART, RLENGTH)
        }
    } !/^## */{annotation=""}' "$1"
}

## List flags from provided shoe script
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     }
##   ]
## }
_get_flags() {
    # Synopsis: _get_flags <SCRIPT_PATH>
    #   SCRIPT_PATH: The path to the input script.

    if [ -z "$1" ]; then _echo_danger 'error: _get_flags: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_flags: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_flags: \"$1\" file not found\n"; return 1; fi

    awk -F '=' '/^[a-zA-Z0-9_]+=false$/ {
        if (substr(PREV,1,3) == "## " && $1 != toupper($1) && substr($0,1,1) != "_") print $1
    } {PREV = $0}' "$1"
}

## Get function by name
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "FUNCTION_NAME",
##       "type": "str",
##       "description": "The name of the function to retrieve.",
##       "nullable": false
##     }
##   ]
## }
_get_function() {
    # Synopsis: _get_function <SCRIPT_PATH> <FUNCTION_NAME>
    #   SCRIPT_PATH:   The path to the input file.
    #   FUNCTION_NAME: The name of the function to retrieve.

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _get_function: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_function: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_function: \"$1\" file not found\n"; return 1; fi

    awk -v FUNCTION_NAME="$2" '
    function count_occurrences(str,char) {
        gsub("\\.","",str); # remove escaped characters
        gsub(/"[^"]*"/,""); # remove quoted string
        return gsub(char,char,str);
    }
    /^#/ { annotation=annotation"\n"$0 }
    in_function {
        print $0;
        count=count_occurrences($0,"{")-count_occurrences($0,"}");
        # count+=gsub("{","&")-gsub("}","&");
        if (count==0) exit
    }
    /^(function +)?[a-zA-Z0-9_]+ *\(\)/ {           # matches a function (ignoring curly braces)
        function_name=substr($0,1,index($0,"(")-1); # truncate string at opening round bracket
        sub("^function ","",function_name);         # remove leading "function " if present
        gsub(" +","",function_name);                # trim whitespaces
        if (function_name==FUNCTION_NAME) {
            if (annotation!="") print substr(annotation,2); # print annotation (without leading "\n")
            print $0;
            in_function=1;
            count=count_occurrences($0,"{")-count_occurrences($0,"}"); # count opened and closed curly braces on current line
            # count=gsub("{","&")-gsub("}","&"); # count opened and closed curly braces on current line
        }
    }
    !/^#/ { annotation="" }' "$1"
}

## List functions names from provided shoe script
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "GET_PRIVATE",
##       "type": "bool",
##       "description": "If set to \"true\", retrieves private functions as well.",
##       "default": false
##     }
##   ]
## }
_get_functions_names() {
    # Synopsis: _get_functions_names <SCRIPT_PATH> [GET_PRIVATE]
    #   SCRIPT_PATH: The path to the input script.
    #   GET_PRIVATE: (Optional) If set to 'true', retrieves private functions as well. Defaults to "false".

    if [ -z "$1" ]; then _echo_danger 'error: _get_functions_names: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_functions_names: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-false}"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_functions_names: \"$1\" file not found\n"; return 1; fi

    # this regular expression matches functions with either bash or sh syntax
    awk -v GET_PRIVATE="$2" \
    '/^(function +)?[a-zA-Z0-9_]+ *\(\)/ {          # matches a function (ignoring curly braces)
        function_name=substr($0,1,index($0,"(")-1); # truncate string at opening round bracket
        sub("^function ","",function_name);         # remove leading "function " if present
        gsub(" +","",function_name);                # trim whitespaces
        if (GET_PRIVATE == "true") {
            print function_name
        } else {
            if (substr($0,1,1) != "_") print function_name
        }
    } {PREV = $0}' "$1"
}

## List options from provided shoe script
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "GET_PRIVATE_ONLY",
##       "type": "bool",
##       "description": "If set to \"true\", retrieves private options only.",
##       "default": false
##     }
##   ]
## }
_get_options() {
    # Synopsis: _get_options <SCRIPT_PATH> [GET_PRIVATE_ONLY]
    #   SCRIPT_PATH:      The path to the input script.
    #   GET_PRIVATE_ONLY: (Optional) If set to 'true', retrieves private options only. Defaults to "false".

    if [ -z "$1" ]; then _echo_danger 'error: _get_options: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_options: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "${2:-false}"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_options: \"$1\" file not found\n"; return 1; fi

    awk -F '=' -v GET_PRIVATE_ONLY="$2" \
    '/^[a-zA-Z0-9_]+=.+$/ {
        if (GET_PRIVATE_ONLY == "true") {
            if ($1 != toupper($1) && $2 != "false" && substr($1,1,1) == "_") print $1
        } else {
            if (substr(PREV,1,3) == "## " && $1 != toupper($1) && $2 != "false" && substr($1,1,1) != "_") print $1
        }
    } {PREV = $0}' "$1"
}

## Guess padding length from longest constant, option, flag or command of the provided shoe script
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     }
##   ]
## }
_get_padding() {
    # Synopsis: _get_padding <SCRIPT_PATH>
    #   SCRIPT_PATH: The path to the input script.

    if [ -z "$1" ]; then _echo_danger 'error: _get_padding: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_padding: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_padding: \"$1\" file not found\n"; return 1; fi

    awk -F '=' '
        /^[a-zA-Z0-9_]+=.+$/ { MATCH=$1 }       # matches constants, options and flags
        /^(function +)?[a-zA-Z0-9_]+ *\(\)/ {   # matches a function (ignoring curly braces)
            MATCH=substr($0,1,index($0,"(")-1); # truncate string at opening round bracket
            sub("^function ","",MATCH);         # remove leading "function " if present
            gsub(" +","",MATCH);                # trim whitespaces
        } { if (substr(PREV,1,3) == "## " && substr(MATCH,1,1) != "_" && length(MATCH) > LENGTH) LENGTH = length(MATCH) }
        {PREV = $0} END {print LENGTH}
    ' "$1"
}

## Get value for given parameter from provided ".env" or ".sh" file
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "sed"
##   ],
##   "depends": [
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "KEY",
##       "type": "str",
##       "description": "The variable name to get from provided file.",
##       "nullable": false
##     }
##   ]
## }
_get_parameter() {
    # Synopsys : _get_parameter <FILE_PATH> <KEY>
    #   FILE_PATH: The path to the input file.
    #   KEY:       The variable name to get from provided file.

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _get_parameter: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_parameter: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_parameter: \"$1\" file not found\n"; return 1; fi

    _echo_info "sed -n \"s/^$2=\(.*\)/\1/p\" \"$1\"\n"
    sed -n "s/^$2=\(.*\)/\1/p" "$1"
}

## Print function synopsis from a JSON string.
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "jq"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "JSON",
##       "type": "json",
##       "description": "The input string containing raw JSON.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "MARKDOWN_FORMAT",
##       "type": "bool",
##       "description": "If set to \"true\", returns result as markdown.",
##       "default": false
##     }
##   ]
## }
_print_synopsis() {
    # Synopsis: _print_synopsis <JSON> [MARKDOWN_FORMAT]
    #   JSON: The input string containing raw JSON.
    #   MARKDOWN_FORMAT: (Optional) If set to 'true', returns result as markdown. Defaults to "false".

    if [ -z "$1" ]; then _echo_danger 'error: _print_synopsis: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _print_synopsis: too many arguments ($#)\n"; return 1; fi
    if ! printf '%s' "$1" | jq empty >/dev/null 2>&1; then _echo_danger "error: _print_synopsis: invalid JSON input\n"; return 1; fi

    if [ "${2:-false}" = "true" ]; then
        printf '> Synopsis:\n> '
    else
        printf 'Synopsis: '
    fi

    printf '%s' "$1" | jq -rj '.name'

    if [ "${2:-false}" = "true" ]; then
        printf '%s' "$1" | jq -rj '[.parameters // [] | .[] | if (.nullable|tostring) == "false" then " &lt;\(.name)&gt;" else " [\(.name)]" end] | join("")'
        printf '\n'
        printf '%s' "$1" | jq -r '.parameters // [] | .[] | "`\(.name)`: \(if .type then "_(type: \"\(.type)\")_ " else "" end)\(if (.nullable|tostring) == "false" then "" else "(optional) " end)\(if .description then .description else "" end)\(if has("default") then " _Defaults to \"\(.default|tostring)\"._" else "" end)"' | while read -r line; do
            printf '%s\n' "- ${line}"
        done
        printf '\n'
        printf '%s' "$1" | jq -rj '[.requires // [] | .[] | "`\(.)`"] | if length > 0 then "- ⚠️ Requires: \(.|join(", "))\n" else "" end'
        printf '%s' "$1" | jq -rj '[.depends // [] | .[] | "`\(.)`"] | if length > 0 then "- 🔗 Depends: \(.|join(", "))\n" else "" end'
        printf '\n'
        return 0
    fi

    printf '%s' "$1" | jq -rj 'if .scope then " (\(.scope)) " else "" end'
    printf '%s' "$1" | jq -rj '[.parameters // [] | .[] | if (.nullable|tostring) == "false" then "<\(.name)>" else "[\(.name)]" end] | join(" ")'
    printf '\n'
    printf '%s' "$1" | jq -r '.parameters // [] | .[] | "\(.name): \(if .type then "(\(.type)) " else "" end)\(if (.nullable|tostring) == "false" then "" else "(optional) " end)\(if .description then .description else "" end)\(if has("default") then " Defaults to \"\(.default|tostring)\"." else "" end)"' | while read -r line; do
        printf '    %s\n' "${line}"
    done
    printf '%s' "$1" | jq -rj '[.requires // [] | .[]] | if length > 0 then "    Requires: \(.|join(", "))\n" else "" end'
    printf '%s' "$1" | jq -rj '[.depends // [] | .[]] | if length > 0 then "    Depends: \(.|join(", "))\n" else "" end'
    printf '\n'
}

## Set value for given parameter into provided file ".env" or ".sh" file
##
## {
##   "namespace": "reflexion",
##   "requires": [
##     "sed"
##   ],
##   "depends": [
##     "_sed_i",
##     "_echo_danger",
##     "_echo_info",
##     "_echo_warning"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "KEY",
##       "type": "str",
##       "description": "The variable name to get from provided file.",
##       "nullable": false
##     },
##     {
##       "position": 3,
##       "name": "VALUE",
##       "type": "str",
##       "description": "The value to be set to provided file.",
##       "nullable": false
##     }
##   ]
## }
_set_parameter() {
    # Synopsys : _set_parameter <FILE_PATH> <KEY> <VALUE>
    #   FILE_PATH: The path to the input script.
    #   KEY:       The variable name to set to provided file
    #   VALUE:     The value to be set to provided file

    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then _echo_danger 'error: _set_parameter: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 3 ]; then _echo_danger "error: _set_parameter: too many arguments ($#)\n"; return 1; fi

    # set default values
    set -- "$(realpath "$1")" "$2" "$3"

    if [ ! -f "$1" ]; then _echo_danger "error: _set_parameter: \"$1\" file not found\n"; return 1; fi

    if [ -z "$(_get_parameter "$1")" ]; then
        _echo_danger "error: _set_parameter: \"$1\" parameter not found\n"

        return 1
    fi

    if [ "$(_get_parameter "$1")" = "$2" ]; then
        _echo_warning "warning: _set_parameter: \"$2\" parameter unchanged\n"

        return 0
    fi

    _echo_info "$(_sed_i) -E \"s/^$2=.*/$2=$3/\" \"$1\"\n"
    $(_sed_i) -E "s/^$2=.*/$2=$3/" "$1"
}

#--------------------------------------------------
#_ Shoedoc
#--------------------------------------------------

## Get function shedoc annotation by name
##
## {
##   "namespace": "shoedoc",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "FUNCTION_NAME",
##       "type": "str",
##       "description": "The name of the function to retrieve.",
##       "nullable": false
##     }
##   ]
## }
_get_function_shoedoc() {
    # Synopsis: _get_function_shoedoc <SCRIPT_PATH> <FUNCTION_NAME>
    #   SCRIPT_PATH:   The path to the input file.
    #   FUNCTION_NAME: The name of the function to retrieve.

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _get_function_shoedoc: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_function_shoedoc: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_function_shoedoc: \"$1\" file not found\n"; return 1; fi

    awk -v FUNCTION_NAME="$2" '
        /^##/ { annotation=annotation$0"\n" }                   # concatenates annotations
        /^(function +)?[a-zA-Z0-9_]+ *\(\)/ {                   # matches a function (ignoring curly braces)
            function_name=substr($0,1,index($0,"(")-1);         # truncate string at opening round bracket
            sub("^function ","",function_name);                 # remove leading "function " if present
            gsub(" +","",function_name);                        # trim whitespaces
            if (function_name==FUNCTION_NAME) print annotation; # print annotation
        }
        !/^##/ { annotation="" }
    ' "$1"
}

## Get top-level shoedoc annotation of the provided shoe script file
##
## {
##   "namespace": "shoedoc",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     }
##   ]
## }
_get_script_shoedoc() {
    # Synopsis: _get_script_shoedoc <SCRIPT_PATH>
    #   SCRIPT_PATH: The path to the input script.

    if [ -z "$1" ]; then _echo_danger 'error: _get_script_shoedoc: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_script_shoedoc: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")"
    if [ ! -f "$1" ]; then _echo_danger "error: _get_script_shoedoc: \"$1\" file not found\n"; return 1; fi

    awk '
        /^##/ { annotation=annotation$0"\n" }
        !/^##/ {
            if (annotation != "") {
                if ($0 == "") {
                    print annotation
                }
                exit
            }
        }
    ' "$1"
}

## Get shoedoc annotation
##
## {
##   "namespace": "shoedoc",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "TEXT",
##       "type": "str",
##       "description": "The input shoedoc annotation bloc.",
##       "nullable": false
##     }
##   ]
## }
_get_shoedoc() {
    # Synopsis: _get_shoedoc <TEXT>
    #   TEXT: The input shoedoc annotation bloc.
    #   note: Remove every line that does not start with a pound character or contains a tag
    #         Returns string without leading pound characters

    if [ -z "$1" ]; then _echo_danger 'error: _get_shoedoc: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_shoedoc: too many arguments ($#)\n"; return 1; fi

    printf '%s' "$1" | awk '/^## .*/ {
        if (substr($2,1,1) != "@") {
            RESULT=substr($0,length($1)+2); # remove leading pound character(s)
            print RESULT
        }
    }'
}

## Get shoedoc description
##
## {
##   "namespace": "shoedoc",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "TEXT",
##       "type": "str",
##       "description": "The input shoedoc annotation bloc.",
##       "nullable": false
##     }
##   ]
## }
_get_shoedoc_description() {
    # Synopsis: _get_shoedoc_description <TEXT>
    #   TEXT: The input shoedoc annotation bloc.

    if [ -z "$1" ]; then _echo_danger 'error: _get_shoedoc_description: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_shoedoc_description: too many arguments ($#)\n"; return 1; fi

    printf '%s' "$1" | awk '/^## .*/ {
        if (substr($2,1,1) != "@") {
            RESULT=substr($0,length($1)+2); # remove leading pound character(s)
            if (index($0, "{") > 0) exit;
            count+=1;
            if (count==2 && RESULT=="") next;
            if (count>1) print RESULT
        }
    }'
}

## Return given tag values from shoedoc annotation
##
## {
##   "namespace": "shoedoc",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "TEXT",
##       "type": "str",
##       "description": "The input shoedoc annotation bloc.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "TAG_NAME",
##       "type": "str",
##       "description": "The name of tag to return.",
##       "nullable": false
##     }
##   ]
## }
_get_shoedoc_tag() {
    # Synopsis: _get_shoedoc_tag <TEXT> <TAG_NAME>
    #   TEXT:     The input shoedoc annotation bloc.
    #   TAG_NAME: The name of tag to return.

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _get_shoedoc_tag: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _get_shoedoc_tag: too many arguments ($#)\n"; return 1; fi

    printf '%s' "$1" | awk -v TAG="$2" '/^## .*/ {
        if ($2=="@"TAG) {
            gsub(" +"," "); sub("^ +",""); sub(" +$",""); # trim input
            RESULT=substr($0,length($1)+length($2)+3);    # remove leading pound character(s)
            print RESULT
        }
    }'
}

## Get shoedoc title
##
## {
##   "namespace": "shoedoc",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "TEXT",
##       "type": "str",
##       "description": "The input shoedoc annotation bloc.",
##       "nullable": false
##     }
##   ]
## }
_get_shoedoc_title() {
    # Synopsis: _get_shoedoc_title <TEXT>
    #   TEXT: The input shoedoc annotation bloc.
    #   note: Returns the first line that does not contain a tag

    if [ -z "$1" ]; then _echo_danger 'error: _get_shoedoc_title: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_shoedoc_title: too many arguments ($#)\n"; return 1; fi

    printf '%s' "$1" | awk '/^## .*/ {
        if (substr($2,1,1) != "@") {
            RESULT=substr($0,length($1)+2); # remove leading pound character(s)
            print RESULT; exit
        }
    }'
}

## Return function shoedoc as json
##
## {
##   "namespace": "shoedoc",
##   "requires": [
##     "jq",
##     "sed"
##   ],
##   "depends": [
##     "_echo_danger",
##     "_get_function_shoedoc"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SCRIPT_PATH",
##       "type": "file",
##       "description": "The path to the input script.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "FUNCTION_NAME",
##       "type": "str",
##       "description": "The name of the function to retrieve.",
##       "nullable": false
##     }
##   ]
## }
_parse_shoedoc() {
    # Synopsis: _parse_shoedoc <SCRIPT_PATH> <FUNCTION_NAME>
    #   SCRIPT_PATH:   The path to the input file.
    #   FUNCTION_NAME: The name of the function to retrieve.

    if [ -z "$1" ] || [ -z "$2" ]; then _echo_danger 'error: _parse_shoedoc: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _parse_shoedoc: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2"
    if [ ! -f "$1" ]; then _echo_danger "error: _parse_shoedoc: \"$1\" file not found\n"; return 1; fi

    set -- "$1" "$2" "$(printf '%s' "$(_get_function_shoedoc "$1" "$2" | sed -nE 's/^ *#+ *//p')")"
    set -- "$1" "$2" "$3" "$(printf '%s' "$3" | sed -n '/^{/,$p')" "$(printf '%s' "$3" | head -n 1)"

    if [ "$(printf '%s' "$2" | cut -c1)" = "_" ]; then
        set -- "$1" "$2" "$3" "$4" "$5" 'private'
    else
        set -- "$1" "$2" "$3" "$4" "$5" 'public'
    fi
    # $1: SCRIPT_PATH, $2: FUNCTION_NAME, $3: annotation, $4 json, $5: summary, $6: scope

    if [ -z "$4" ]; then
        jq --null-input \
            --arg name "$2" \
            --arg summary "$5" \
            --arg scope "$6" \
            '$ARGS.named'

        return 0
    fi

    jq --null-input \
    --arg name "$2" \
    --arg summary "$5" \
    --arg scope "$6" \
    '$ARGS.named + '"$4"
}

#--------------------------------------------------
#_ Strings
#--------------------------------------------------

## Collapse blank lines with "sed"
##
## {
##   "namespace": "strings",
##   "depends": [
##     "_sed_i",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     }
##   ]
## }
_collapse_blank_lines() {
    # Synopsis: _collapse_blank_lines <FILE_PATH>
    #   FILE_PATH: The path to the input file.

    if [ -z "$1" ]; then _echo_danger 'error: _collapse_blank_lines: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _collapse_blank_lines: too many arguments ($#)\n"; return 1; fi
    if [ ! -f "$1" ]; then _echo_danger "error: _collapse_blank_lines: \"$1\" file not found\n"; return 1; fi
    set -- "$(realpath "$1")"

    # The N command reads the next line into the pattern space.
    # The remaining expression checks if the pattern space now consists of two empty lines (^\n$).
    _echo_info "$(_sed_i) '/^$/{N;s/^\\\n$//;}' \"$1\"\n"
    $(_sed_i) '/^$/{N;s/^\n$//;}' "$1"
}

## Generate random 32 bit string
##
## {
##   "namespace": "strings",
##   "requires": [
##     "openssl"
##   ],
##   "depends": [
##     "_echo_info"
##   ]
## }
_generate_key() {
    # Synopsis: _generate_key

    _check_installed openssl

    _echo_info 'openssl rand -hex 16\n'
    openssl rand -hex 16
}

#--------------------------------------------------
#_ Symfony
#--------------------------------------------------

## Install project dependencies with composer
##
## {
##   "namespace": "symfony",
##   "requires": [
##     "composer"
##   ],
##   "depends": [
##     "_check_installed",
##     "_pwd",
##     "_echo_info"
##   ]
## }
_composer_install() {
    _check_installed composer

    _echo_info "composer install --no-interaction --prefer-dist --optimize-autoloader --working-dir=\"$(_pwd)\"\n"
    composer install --no-interaction --prefer-dist --optimize-autoloader --working-dir="$(_pwd)"
}

## Get correct Symfony console binary path
##
## {
##   "namespace": "symfony",
##   "depends": [
##     "_echo_danger"
##   ]
## }
_console() {
    if [ -x "$(command -v symfony)" ]; then
        echo 'symfony console'

        return 0
    fi

    if [ -f ./app/console ]; then
        echo './app/console'

        return 0
    fi

    if [ -f ./bin/console ]; then
        echo './bin/console'

        return 0
    fi

    _echo_danger "error: \"$(basename "${0}")\" symfony console not found, try: 'composer install'\n"
    exit 1
}

## Create Symfony database with Doctrine
##
## {
##   "namespace": "symfony",
##   "depends": [
##     "_console",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "ENV",
##       "type": "str",
##       "description": "Environment.",
##       "constraint": "/^(dev|prod|test)$/"
##     }
##   ]
## }
_db_create() {
    if [ -z "$1" ]; then _echo_danger 'error: _db_create: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _db_create: too many arguments ($#)\n"; return 1; fi

    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info "$(_console) doctrine:database:create --env \"$1\" || true\n"
    $(_console) doctrine:database:create --env "$1" || true
}

## Drop database with Doctrine
##
## {
##   "namespace": "symfony",
##   "depends": [
##     "_console",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "ENV",
##       "type": "str",
##       "description": "Environment.",
##       "constraint": "/^(dev|prod|test)$/"
##     }
##   ]
## }
_db_drop() {
    if [ -z "$1" ]; then _echo_danger 'error: _db_drop: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _db_drop: too many arguments ($#)\n"; return 1; fi

    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info "$(_console) doctrine:database:drop --force --env \"$1\" || true\n"
    $(_console) doctrine:database:drop --force --env "$1" || true
}

## Executes arbitrary SQL directly from the command line
##
## {
##   "namespace": "symfony",
##   "depends": [
##     "_console",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "SQL",
##       "type": "str",
##       "description": "SQL query.",
##       "constraint": "/.+/"
##     }
##   ]
## }
_db_query() {
    if [ -z "$1" ]; then _echo_danger 'error: _db_query: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _db_query: too many arguments ($#)\n"; return 1; fi

    _echo_info "$(_console) doctrine:query:sql \"$1\"\n"
    $(_console) doctrine:query:sql "$1"
}

## Create schema with Doctrine
##
## {
##   "namespace": "symfony",
##   "depends": [
##     "_console",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "ENV",
##       "type": "str",
##       "description": "Environment.",
##       "constraint": "/^(dev|prod|test)$/"
##     }
##   ]
## }
_db_schema() {
    if [ -z "$1" ]; then _echo_danger 'error: _db_create: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _db_create: too many arguments ($#)\n"; return 1; fi

    _echo_info "$(_console) doctrine:schema:create --dump-sql --env \"$1\"\n"
    $(_console) doctrine:schema:create --dump-sql --env "$1"

    # following command will not break script execution on failure even with `-e` option enabled
    _echo_info "$(_console) doctrine:schema:create --env \"$1\" || true\n"
    $(_console) doctrine:schema:create --env "$1" || true
}

## Get correct PHPUnit binary path
##
## {
##   "namespace": "ci_cd",
##   "depends": [
##     "_echo_danger"
##   ]
## }
_phpunit() {
    if [ -f ./vendor/bin/phpunit ]; then
        echo ./vendor/bin/phpunit

        return 0
    fi

    if [ -f ./vendor/bin/simple-phpunit ]; then
        echo ./vendor/bin/simple-phpunit

        return 0
    fi

    if [ -f ./vendor/symfony/phpunit-bridge/bin/simple-phpunit ]; then
        echo './vendor/symfony/phpunit-bridge/bin/simple-phpunit'

        return 0
    fi

    if [ -f ./bin/phpunit ]; then
        echo './bin/phpunit'

        return 0
    fi

    _echo_danger "error: \"$(basename "${0}")\" requires phpunit, try: 'composer install'\n"

    return 1
}

## Clear Symfony cache
##
## {
##   "namespace": "symfony",
##   "depends": [
##     "_console",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "ENV",
##       "type": "str",
##       "description": "Environment.",
##       "constraint": "/^(dev|prod|test)$/"
##     }
##   ]
## }
_sf_cache() {
    if [ -z "$1" ]; then _echo_danger 'error: _sf_cache: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _sf_cache: too many arguments ($#)\n"; return 1; fi

    _echo_info "$(_console) cache:clear --env \"$1\"\n"
    $(_console) cache:clear --env "$1"

    _echo_info "$(_console) cache:warmup --env \"$1\"\n"
    $(_console) cache:warmup --env "$1"
}

## Run linter (sniff)
##
## {
##   "namespace": "symfony",
##   "requires": [
##     "composer",
##     "php"
##   ],
##   "depends": [
##     "_check_installed",
##     "_console",
##     "_echo_info"
##   ]
## }
_sf_lint() {
    _check_installed php
    _check_installed composer

    # check composer validity
    _echo_info 'composer validate\n'
    composer validate

    # check php files syntax
    _echo_info "php -l -d memory-limit=-1 -d display_errors=0 \"...\"\n"
    find ./src ./tests -type f -name '*.php' | while read -r __file__; do
        php -l -d memory-limit=-1 -d display_errors=0 "${__file__}"
    done

    _echo_info "$(_console) lint:container\n"
    $(_console) lint:container

    _echo_info "$(_console) lint:twig ./templates --show-deprecations\n"
    $(_console) lint:twig ./templates --show-deprecations

    _echo_info "$(_console) lint:yaml ./compose.yaml ./compose.*.yaml"
    $(_console) lint:yaml ./compose.yaml ./compose.*.yaml
}

## Check security issues in project dependencies (symfony-cli)
##
## {
##   "namespace": "symfony",
##   "requires": [
##     "composer",
##     "symfony"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
_security() {
    if "$(_is_installed symfony)"; then
        _echo_info 'symfony security:check\n'
        symfony security:check

        return 0
    fi

    if "$(_is_installed composer)"; then
        _echo_info 'composer audit\n'
        composer audit

        return 0
    fi

    _echo_danger "error: \"$0\" requires symfony or composer.\n"
    return 1
}

## Run a local web server with Symfony CLI
##
## {
##   "namespace": "symfony",
##   "requires": [
##     "symfony"
##   ],
##   "depends": [
##     "_check_installed",
##     "_echo_info"
##   ]
## }
_sf_serve() {
    _check_installed symfony

    _echo_info 'symfony local:server:start --no-tls\n'
    symfony local:server:start --no-tls
}

#--------------------------------------------------
#_ System
#--------------------------------------------------

## Print error message if provided command is missing
##
## {
##   "namespace": "system",
##   "depends": [
##     "_get_package_name",
##     "_is_installed",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "COMMAND",
##       "type": "str",
##       "description": "A string containing the command name to find.",
##       "nullable": false
##     }
##   ]
## }
_check_installed() {
    # Synopsis: _check_installed <COMMAND>
    #   COMMAND: A string containing the command name to find.

    if [ -z "$1" ]; then _echo_danger 'error: _check_installed: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _check_installed: too many arguments ($#)\n"; return 1; fi

    if _is_installed "$1"; then
        return 0
    fi

    # set default values
    set -- "$1" "$(_get_package_name "$1")"

    _echo_danger "error: \"$(basename "${0}")\" requires $1, try: 'sudo apt-get install -y $2'\n"

    exit 1
}

## Find package name for given command
##
## {
##   "namespace": "system",
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "COMMAND",
##       "type": "str",
##       "description": "A string containing the command name to find.",
##       "nullable": false
##     }
##   ]
## }
_get_package_name() {
    # Synopsis: _get_package_name <COMMAND>
    #   COMMAND: A string containing the command name to find.

    if [ -z "$1" ]; then _echo_danger 'error: _get_package_name: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _get_package_name: too many arguments ($#)\n"; return 1; fi

    # debian packages
    if [ "$1" = aapt ];     then echo android-tools-adb;      return 0; fi
    if [ "$1" = adb ];      then echo android-tools-adb;      return 0; fi
    if [ "$1" = fastboot ]; then echo android-tools-fastboot; return 0; fi
    if [ "$1" = snap ];     then echo snapd;                  return 0; fi

    for __package__ in \
        arp \
        ifconfig \
        ipmaddr \
        iptunnel \
        mii-tool \
        nameif \
        plipconfig \
        rarp \
        route \
        slattach \
    ; do
        if [ "$1" = "${__package__}" ]; then
            echo net-tools

            return 0
        fi
    done

    echo "$1"
}

## Validate a file checksum
##
## {
##   "namespace": "system",
##   "requires": [
##     "awk",
##     "sha256sum"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "FILE_PATH",
##       "type": "file",
##       "description": "The path to the input file.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "SHA256SUM",
##       "type": "str",
##       "description": "A string containing file checksum.",
##       "nullable": false
##     }
##   ]
## }
_is_checksum_valid() {
    # Synopsis: _is_checksum_valid <FILE_PATH> <SHA256SUM>
    #   FILE_PATH: The path to the input file.
    #   SHA256SUM: A string containing file checksum.

    _check_installed sha256sum

    if [ $# -lt 2 ]; then _echo_danger 'error: _is_checksum_valid: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _is_checksum_valid: too many arguments ($#)\n"; return 1; fi

    set -- "$(realpath "$1")" "$2"
    if [ ! -f "$1" ]; then _echo_danger "error: _is_checksum_valid: \"$1\" file not found\n"; return 1; fi

    sha256sum "$1" | awk '{print $1}' | grep -q "$2"
}

## Check current desktop is gnome
##
## {
##   "namespace": "system",
##   "assumes": [
##     "XDG_CURRENT_DESKTOP"
##   ]
## }
_is_gnome() {
    # Synopsis: _is_gnome

    if [ "${XDG_CURRENT_DESKTOP}" != 'ubuntu:GNOME' ]; then

        return 1
    fi

    return 0
}

## Check provided command is installed
##
## {
##   "namespace": "system",
##   "requires": [
##     "dpkg"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "COMMAND",
##       "type": "str",
##       "description": "A string containing the command name to find.",
##       "nullable": false
##     }
##   ]
## }
_is_installed() {
    # Synopsis: _is_installed <COMMAND>
    #   COMMAND: A string containing the command name to find.

    if [ -z "$1" ]; then _echo_danger 'error: _is_installed: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _is_installed: too many arguments ($#)\n"; return 1; fi

    if [ -x "$(command -v "$1")" ]; then

        return 0
    fi

    # maybe it's a debian package
    if dpkg -s "$1" 2>/dev/null | grep -q 'Status: install ok installed'; then

        return 0
    fi

    # or maybe it's a linuxbrew package
    if [ -x "/home/linuxbrew/.linuxbrew/bin/$1" ]; then

        return 0
    fi

    return 1
}

## Check current user is root
##
## {
##   "namespace": "system",
##   "requires": [
##     "awk",
##     "id"
##   ]
## }
_is_root() {
    # Synopsis: _is_root

    if [ "$(id | awk '{print $1}')" = 'uid=0(root)' ];then
        return 0
    fi

    return 1
}

## Return current project directory realpath, or "pwd" when installed globally
##
## {
##   "namespace": "system",
##   "returns": "str"
## }
_pwd() {
    # Synopsis: _pwd

    if [ "$(dirname "$(realpath "$0")")" = '/usr/local/bin' ]; then
        pwd

        return 0
    fi

    dirname "$(realpath "$0")"
}

## Install required package globally
##
## {
##   "namespace": "system",
##   "requires": [
##     "apt"
##   ],
##   "depends": [
##     "_get_package_manager",
##     "_get_package_name",
##     "_is_installed",
##     "_echo_danger",
##     "_echo_info"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "PACKAGE",
##       "type": "str",
##       "description": "The command/package to remove.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "PACKAGE_MANAGER",
##       "type": "str",
##       "description": "The package manager required to remove the package with.",
##       "default": "apt"
##     }
##   ]
## }
_require() {
    # Synopsis: _require <PACKAGE> [PACKAGE_MANAGER]
    #   PACKAGE:         The command/package to install.
    #   PACKAGE_MANAGER: (optional) The package manager required to install the package with.
    #   note:            eg: `_require curl` will install "curl" with "sudo apt install --yes curl".
    #                    eg: `_require adb` will install "android-tools-adb" package.

    if [ -z "$1" ]; then _echo_danger 'error: _require: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _require: too many arguments ($#)\n"; return 1; fi

    if _is_installed "$1"; then
        return 0
    fi

    # set default values
    set -- "$(_get_package_name "$1")" "${2:-$(_get_package_manager)}"

    if ! _is_installed "$2"; then
        _echo_danger "error: _require \"$2\" package manager not found!\n"
        exit 1
    fi

    if [ "$2" = apk ]; then
        _echo_info "sudo apk add \"$1\"\n"
        sudo apk add "$1"

    elif [ "$2" = apt ]; then
        _echo_info "sudo apt install --yes \"$1\"\n"
        sudo apt install --yes "$1"

    elif [ "$2" = apt-get ]; then
        _echo_info "sudo apt-get install --assume-yes \"$1\"\n"
        sudo apt-get install --assume-yes "$1"

    elif [ "$2" = aptitude ]; then
        _echo_info "sudo aptitude install --yes \"$1\"\n"
        sudo aptitude install --yes "$1"

    elif [ "$2" = dnf ]; then
        _echo_info "sudo dnf install --assumeyes --nogpgcheck -y \"$1\"\n"
        sudo dnf install --assumeyes --nogpgcheck -y "$1"

    elif [ "$2" = flatpak ]; then
        _echo_info "flatpak install --non-interactive flathub \"$1\"\n"
        flatpak install --non-interactive flathub "$1"

    elif [ "$2" = nala ]; then
        _echo_info "sudo nala install --assume-yes \"$1\"\n"
        sudo nala install --assume-yes "$1"

    elif [ "$2" = pacman ]; then
        _echo_info "sudo pacman -Sy \"$1\"\n"
        sudo pacman -Sy "$1"

    elif [ "$2" = snap ]; then
        _echo_info "sudo snap install \"$1\" --classic\n"
        sudo snap install "$1" --classic

    elif [ "$2" = yum ]; then
        _echo_info "sudo yum install --assumeyes \"$1\"\n"
        sudo yum install --assumeyes "$1"

    elif [ "$2" = zypper ]; then
        _echo_info "sudo zypper install --non-interactive \"$1\"\n"
        sudo zypper install --non-interactive "$1"
    fi
}

## Animate a spinner in the terminal for a given amout of time
##
## {
##   "namespace": "system",
##   "requires": [
##     "awk"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "DURATION",
##       "type": "int",
##       "description": "Animation duration in miliseconds.",
##       "default": 0
##     }
##   ]
## }
_spin() {
    # Synopsis: _spin [DURATION]
    #   DURATION: Animation duration in miliseconds

    set -- "$((${1:-0}/10))" 0 0

    while [ "$1" -gt "$2" ]; do
        printf '\r%s' "$(printf "|/-\\" | awk -v I="$3" '{print substr($0, I, 1)}')"
        set -- "$1" "$(( $2+1 ))" "$(( $3%4+1 ))"
        sleep 0.1
    done
}

## Check provided user exists
##
## {
##   "namespace": "system",
##   "requires": [
##     "awk"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "USERNAME",
##       "type": "str",
##       "description": "The username to check.",
##       "nullable": false
##     }
##   ]
## }
_user_exists() {
    # Synopsis: _user_exists [USERNAME]
    #   USERNAME: The username to check.

    if [ -z "$1" ]; then _echo_danger 'error: _user_exists: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _user_exists: too many arguments ($#)\n"; return 1; fi

    if [ -n "$(id -u "$1" 2>/dev/null)" ]; then

        return 0
    fi

    return 1
}

#--------------------------------------------------
#_ Validation
#--------------------------------------------------

## Checks if variable is valid given regex constraint
##
## {
##   "namespace": "validation",
##   "requires": [
##     "grep",
##     "sed"
##   ],
##   "depends": [
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "VALUE",
##       "type": "str",
##       "description": "The string to be compared to regex pattern.",
##       "nullable": false
##     },
##     {
##       "position": 2,
##       "name": "PATTERN",
##       "type": "str",
##       "description": "The regex parttern to apply.",
##       "nullable": false
##     }
##   ]
## }
_is_valid() {
    # Synopsis: _is_valid <VALUE> <PATTERN>
    #   VALUE:   The string to be compared to regex pattern.
    #   PATTERN: The regex parttern to apply.

    if [ $# -lt 2 ]; then _echo_danger 'error: _is_valid: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 2 ]; then _echo_danger "error: _is_valid: too many arguments ($#)\n"; return 1; fi

    # missing pattern always returns valid status
    if [ -z "$2" ]; then

        return 0
    fi

    # remove leading and ending forward slashes from regular expression
    set -- "$1" "$(printf '%s' "$2" | sed 's@^/@@;s@/$@@')"

    # if [ "$1" != "$(printf '%s' "$1" | awk "$2 {print}")" ]; then
    if [ "$1" != "$(printf '%s' "$1" | grep -E "$2")" ]; then

        return 1
    fi

    return 0
}

## Find constraints and validates a variable
##
## {
##   "namespace": "validation",
##   "requires": [
##     "sed"
##   ],
##   "depends": [
##     "_get_constraint",
##     "_is_valid",
##     "_echo_danger"
##   ],
##   "parameters": [
##     {
##       "position": 1,
##       "name": "VARIABLE",
##       "type": "str",
##       "description": "The variable to validate in the followling format : variable_name=value.",
##       "nullable": false
##     }
##   ]
## }
_validate() {
    # Synopsis: _validate <VARIABLE>
    #   VARIABLE: The variable to validate in the followling format : variable_name=value.

    if [ -z "$1" ]; then _echo_danger 'error: _validate: some mandatory parameter is missing\n'; return 1; fi
    if [ $# -gt 1 ]; then _echo_danger "error: _validate: too many arguments ($#)\n"; return 1; fi

    set -- "$(printf '%s' "$1" | cut -d= -f1)" "$(printf '%s' "$1" | cut -d= -f2)" "$(_get_constraint "$0" "$(printf '%s' "$1" | cut -d= -f1)")"

    if ! _is_valid "$2" "$3"; then
        _echo_danger "error: invalid \"$1\", expected \"$3\", \"$2\" given\n"
        exit 1
    fi
}

#--------------------------------------------------
#_ Kernel
#--------------------------------------------------

## Shoe Kernel
##
## {
##   "namespace": "kernel",
##   "requires": [
##     "awk",
##     "grep"
##   ],
##   "depends": [
##     "_after",
##     "_before",
##     "_default",
##     "_get_flags",
##     "_get_functions_names",
##     "_get_options",
##     "_validate",
##     "_echo_danger"
##   ]
## }
_kernel() {
    # Check for duplicate function definitions
    __functions_names__=$(_get_functions_names "$0" true)
    for __function__ in ${__functions_names__}; do
        if [ "$(printf "%s" "${__functions_names__}" | grep -cx "${__function__}")" -gt 1 ]; then
            _echo_danger "error: function \"${__function__}\" is defined multiple times\n"
            exit 1
        fi
    done

    if [ $# -lt 1 ]; then _default; exit 0; fi

    __execution_stack__=''
    __requires_value__=''

    for __argument__ in "$@"; do
        __is_valid__=false

        # Handle required value for previous option
        if [ -n "${__requires_value__}" ]; then
            _validate "${__requires_value__}=${__argument__}"
            eval "${__requires_value__}=\"${__argument__}\";"
            __requires_value__=''
            continue
        fi

        # Check if argument is a flag or option (starts with - or --)
        if printf '%s' "${__argument__}" | grep -Eq '^--?[a-zA-Z0-9_]+$'; then
            for __type__ in flag option; do
                __parameters__="$(_get_flags "$0")"
                [ "$__type__" = 'option' ] && __parameters__="$(_get_options "$0")"
                for __parameter__ in $__parameters__; do
                    __shorthand__="$(printf '%s' "${__parameter__}" | awk '{print substr($0,1,1)}')"
                    if [ "${__argument__}" = "--${__parameter__}" ] || [ "${__argument__}" = "-${__shorthand__}" ]; then
                        if [ "$__type__" = 'flag' ]; then
                            eval "${__parameter__}=true"
                        else
                            __requires_value__="${__parameter__}"
                        fi
                        __is_valid__=true
                        break 2
                    fi
                done
            done
            if [ "${__is_valid__}" = false ]; then
                _echo_danger "error: \"${__argument__}\" is not a valid parameter\n"
                exit 1
            fi
            continue
        fi

        # Check if argument is a function name or its shorthand
        for __function__ in $(_get_functions_names "$0"); do
            __shorthand__="$(printf '%s' "${__function__}" | awk '{print substr($0,1,1)}')"
            if [ "${__argument__}" = "${__function__}" ] || [ "${__argument__}" = "${__shorthand__}" ]; then
                __execution_stack__="${__execution_stack__} ${__function__}"
                __is_valid__=true
                break
            fi
        done
        if [ "${__is_valid__}" = false ]; then
            _echo_danger "error: \"${__argument__}\" is not a valid command\n"
            exit 1
        fi
    done

    if [ -n "${__requires_value__}" ]; then
        _echo_danger "error: \"--${__requires_value__}\" requires value\n"
        exit 1
    fi

    [ -n "$(command -v _before)" ] && _before

    if printf '%s' "${__execution_stack__}" | grep -qw 'help'; then
       _help "$0" "$(printf '%s' "${__execution_stack__}" | awk '{for(i=1;i<=NF;i++) if($i=="help") print $(i+1); exit}')"
       exit 0
    fi

    if [ -z "${__execution_stack__}" ]; then _default; exit 0; fi

    for __function__ in ${__execution_stack__}; do
        eval "${__function__}"
    done

    [ -n "$(command -v _after)" ] && _after
}

_kernel "$@"

