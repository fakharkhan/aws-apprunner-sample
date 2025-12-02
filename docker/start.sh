#!/bin/sh
# Simplified startup script for Laravel on AWS App Runner
# Based on best practices from Laravel App Runner deployment guides

# All output to stderr so App Runner captures it
exec 1>&2

echo "=========================================="
echo "Starting Laravel Application on App Runner"
echo "=========================================="

# Get PORT from environment (App Runner sets this)
PORT=${PORT:-8000}
echo "PORT environment variable: ${PORT}"

# Update nginx to listen on the PORT from environment variable
echo "Configuring nginx to listen on 0.0.0.0:${PORT}..."
# Replace any existing listen directives with the new port
sed -i "s/listen 0\.0\.0\.0:[0-9]\+ default_server/listen 0.0.0.0:${PORT} default_server/g" /etc/nginx/nginx.conf
sed -i "s/listen [0-9]\+ default_server/listen 0.0.0.0:${PORT} default_server/g" /etc/nginx/nginx.conf
sed -i "s/\[::\]:[0-9]\+ default_server/[::]:${PORT} default_server/g" /etc/nginx/nginx.conf

# Create necessary directories
mkdir -p /var/log/nginx /var/log/supervisor /var/run

# Set permissions for Laravel
echo "Setting Laravel permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Handle .env file
if [ ! -f /var/www/html/.env ]; then
    echo "Creating .env file..."
    if [ -f /var/www/html/.env.example ]; then
        cp /var/www/html/.env.example /var/www/html/.env
    else
        echo "Warning: .env.example not found, creating minimal .env"
        cat > /var/www/html/.env <<EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
LOG_CHANNEL=stderr
EOF
    fi
    
    # Generate APP_KEY if not provided via environment variable
    if [ -z "$APP_KEY" ]; then
        echo "Generating APP_KEY..."
        php artisan key:generate --force
    fi
fi

# Optimize Laravel for production (non-blocking)
# Skip route:cache to avoid health check endpoint issues
echo "Optimizing Laravel..."
php artisan config:cache || true
# Skip route:cache - it can cause health check endpoint to fail
# php artisan route:cache || true
php artisan view:cache || true

# Test nginx configuration
echo "Testing nginx configuration..."
if ! nginx -t; then
    echo "ERROR: nginx configuration test failed!"
    exit 1
fi

echo "=========================================="
echo "Starting services with Supervisor..."
echo "=========================================="

# Start supervisor in foreground mode (critical for container to stay alive)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf -n
