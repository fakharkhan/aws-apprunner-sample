#!/bin/sh
# Optimized startup script for Laravel on AWS App Runner
# Starts services quickly to pass health checks

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
sed -i "s/listen 0\.0\.0\.0:[0-9]\+ default_server/listen 0.0.0.0:${PORT} default_server/g" /etc/nginx/nginx.conf
sed -i "s/listen [0-9]\+ default_server/listen 0.0.0.0:${PORT} default_server/g" /etc/nginx/nginx.conf
sed -i "s/\[::\]:[0-9]\+ default_server/[::]:${PORT} default_server/g" /etc/nginx/nginx.conf

# Create necessary directories
mkdir -p /var/log/nginx /var/log/supervisor /var/run

# Set permissions for Laravel (minimal, fast)
echo "Setting Laravel permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Create minimal .env file quickly (don't wait for key generation)
if [ ! -f /var/www/html/.env ]; then
    echo "Creating minimal .env file..."
    cat > /var/www/html/.env <<EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=${APP_KEY:-base64:tempkey}
APP_DEBUG=false
LOG_CHANNEL=stderr
EOF
    # Generate APP_KEY in background if not provided
    if [ -z "$APP_KEY" ]; then
        (php artisan key:generate --force 2>/dev/null || true) &
    fi
fi

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
# Supervisor will start nginx and PHP-FPM quickly
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf -n
