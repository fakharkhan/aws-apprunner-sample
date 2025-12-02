#!/bin/sh

# Set PORT from environment variable or default to 8000
PORT=${PORT:-8000}
export PORT

# Replace PORT in nginx.conf with the actual port
sed -i "s/listen 8000;/listen ${PORT};/g" /etc/nginx/nginx.conf

# Set permissions
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Create .env file if it doesn't exist
if [ ! -f /var/www/html/.env ]; then
    cp /var/www/html/.env.example /var/www/html/.env
    php artisan key:generate --force || true
fi

# Cache configuration for better performance (only if .env exists)
if [ -f /var/www/html/.env ]; then
    php artisan config:cache || true
    php artisan route:cache || true
    php artisan view:cache || true
fi

# Start supervisor (which manages PHP-FPM and Nginx)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

