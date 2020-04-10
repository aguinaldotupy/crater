##### STAGE 1 #####

FROM composer as composer

# Copy composer files from project root into composer container's working dir
COPY composer.* /app/

# Copy database directory for autoloader optimization
COPY database /app/database

##### STAGE 2 #####

FROM php:7.3.12-fpm-alpine

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN apk add --no-cache libpng-dev libxml2-dev oniguruma-dev libzip-dev gnu-libiconv && \
    docker-php-ext-install bcmath ctype json gd mbstring pdo pdo_mysql tokenizer xml zip

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Set container's working dir
WORKDIR /app

# Copy everything from project root into php container's working dir
COPY . /app

# Run composer to build dependencies in vendor folder
RUN composer install --no-scripts --no-suggest --no-interaction --prefer-dist --optimize-autoloader

# Copy everything from project root into composer container's working dir
COPY . /app

RUN composer dump-autoload --optimize --classmap-authoritative

# Copy vendor folder from composer container into php container
COPY --from=composer /app/vendor /app/vendor

RUN touch database/database.sqlite && \
    cp .env.example .env && \
    php artisan config:cache && \
    php artisan passport:keys && \
    php artisan key:generate && \
    chown -R www-data:www-data . && \
    chmod -R 755 . && \
    chmod -R 775 storage/framework/ && \
    chmod -R 775 storage/logs/ && \
    chmod -R 775 bootstrap/cache/

EXPOSE 9000

CMD ["php-fpm", "--nodaemonize"]
