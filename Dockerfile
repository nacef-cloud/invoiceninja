# Backend-only Dockerfile for Invoice Ninja
# No frontend build - use Flutter desktop app for UI

FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    mysql-client \
    linux-headers \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    oniguruma-dev \
    icu-dev \
    libxml2-dev \
    && rm -rf /var/cache/apk/*

# Install build dependencies for PECL
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS

# Install PHP extensions (MySQL only, no PostgreSQL)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        gd \
        zip \
        bcmath \
        opcache \
        intl \
        pcntl \
        sockets \
        soap \
        exif \
        mbstring

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Remove build dependencies
RUN apk del .build-deps

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY --chown=www-data:www-data . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Create necessary directories
RUN mkdir -p storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy configuration files
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/fix-nginx-permissions.sh /usr/local/bin/fix-nginx-permissions.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/fix-nginx-permissions.sh

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start supervisor
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
