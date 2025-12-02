#!/bin/sh
# Don't exit on error for Laravel commands, but ensure nginx starts

# Log to stderr (App Runner will capture this)
echo "Starting Laravel application..." >&2

# Set PORT from environment variable or default to 8000
PORT=${PORT:-8000}
export PORT
echo "Using PORT: ${PORT}" >&2

# Replace PORT in nginx.conf with the actual port
echo "Configuring nginx to listen on port ${PORT}..." >&2
sed -i "s/listen 8000/listen ${PORT}/g" /etc/nginx/nginx.conf
sed -i "s/\[::\]:8000/[::]:${PORT}/g" /etc/nginx/nginx.conf

# Ensure nginx log directory exists
mkdir -p /var/log/nginx /var/log/supervisor

# Set permissions
echo "Setting permissions..." >&2
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/log/nginx /var/log/supervisor
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Create .env file if it doesn't exist
if [ ! -f /var/www/html/.env ]; then
    echo "Creating .env file from .env.example..." >&2
    cp /var/www/html/.env.example /var/www/html/.env
    php artisan key:generate --force || echo "Warning: Failed to generate APP_KEY" >&2
fi

# Cache configuration for better performance (only if .env exists)
if [ -f /var/www/html/.env ]; then
    echo "Caching Laravel configuration..." >&2
    php artisan config:cache || echo "Warning: Config cache failed" >&2
    php artisan route:cache || echo "Warning: Route cache failed" >&2
    php artisan view:cache || echo "Warning: View cache failed" >&2
fi

# Test nginx configuration
echo "Testing nginx configuration..." >&2
nginx -t || (echo "ERROR: nginx configuration test failed!" >&2 && exit 1)

# Start supervisor (which manages PHP-FPM and Nginx)
echo "Starting supervisor..." >&2
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

