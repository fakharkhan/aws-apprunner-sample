# Use official PHP 8.2 FPM image with Alpine
FROM php:8.2-fpm-alpine

# Install system dependencies and PHP extensions required by Laravel
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    nodejs \
    npm

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies (no dev dependencies for production, skip scripts)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

# Copy application files
COPY . .

# Run composer scripts now that files are in place
RUN composer dump-autoload --optimize --no-dev

# Install Node dependencies and build assets
RUN npm install && npm run build

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy startup script
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Expose port 8000 (App Runner uses PORT environment variable)
EXPOSE 8000

# Use supervisor to manage processes
CMD ["/usr/local/bin/start.sh"]

