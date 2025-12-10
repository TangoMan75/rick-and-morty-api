#/**
# * TangoMan symfony-php-fpm-alpine.dockerfile
# *
# * Symfony php-fpm alpine Dockerfile
# *
# * @version  0.1.0
# * @author   "Matthias Morin" <mat@tangoman.io>
# * @license  MIT
# * @link     https://hub.docker.com/_/php
# */

FROM php:8.1-fpm-alpine

WORKDIR /var/www/

# persistent / runtime deps
RUN apk add --no-cache fcgi file gettext vim;

# Install symfony PHP Core extensions dependencies (amqp gd intl pdo_mysql pdo_pgsql xsl zip)
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libzip-dev \
        postgresql-dev \
        zlib-dev \
    ; \
    \
    docker-php-ext-configure zip; \
    docker-php-ext-install -j$(nproc) \
        intl \
        pdo_mysql \
        pdo_pgsql \
        zip \
    ; \
    pecl install \
        xdebug-3.0.4 \
    ; \
    pecl clear-cache; \
    docker-php-ext-enable \
        xdebug \
    ; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .api-phpexts-rundeps $runDeps; \
    \
    apk del .build-deps

# branding and aliases
ENV ENV="/root/.ashrc"
RUN echo -e "\033[33m TangoMan branding and aliases \033[0m" \
    && echo "printf \"\\033[0;32m _____%17s_____\\n|_   _|___ ___ ___ ___|%5s|___ ___\\n  | | | .'|   | . | . | | | | .'|   |\\n  |_| |__,|_|_|_  |___|_|_|_|__,|_|_|\\n%14s|___|%6s\\033[33mtangoman.io\\033[0m\\n\"" >> ~/.ashrc \
    && printf 'alias --="cd --"\nalias ...="cd ..; cd .."\nalias ..="cd .."\nalias cc="clear"\nalias h="history"\nalias hh="history | grep"\nalias l="ls -alFh"\nalias ll="ls -alFh"\nalias sf="./bin/console"\nalias tests="./bin/phpunit"\nalias xx="exit"' >> ~/.ashrc

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY ./conf.d/symfony-prod.ini $PHP_INI_DIR/conf.d/custom.ini

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
# install Symfony Flex globally to speed up download of Composer packages (parallelized prefetching)
RUN composer global require "symfony/flex" --prefer-dist --no-progress --classmap-authoritative; \
    composer clear-cache
ENV PATH="${PATH}:/root/.composer/vendor/bin"

CMD ["sh", "-c", "php-fpm"]
