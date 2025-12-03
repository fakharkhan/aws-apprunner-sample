#!/bin/sh
# Ultra-minimal startup - get services running ASAP
# All output to stderr for App Runner logs
exec 1>&2

PORT=${PORT:-8000}
echo "=========================================="
echo "Starting on port ${PORT}"
echo "=========================================="

# Update nginx config to use PORT
sed -i "s/listen 0\.0\.0\.0:[0-9]\+ default_server/listen 0.0.0.0:${PORT} default_server/g" /etc/nginx/nginx.conf
sed -i "s/listen [0-9]\+ default_server/listen 0.0.0.0:${PORT} default_server/g" /etc/nginx/nginx.conf
sed -i "s/\[::\]:[0-9]\+ default_server/[::]:${PORT} default_server/g" /etc/nginx/nginx.conf

# Test nginx config
if ! nginx -t 2>&1; then
    echo "ERROR: nginx config test failed!"
    exit 1
fi

# Quick Laravel setup (do AFTER services start, in background)
{
    sleep 2  # Give services time to start first
    if [ ! -f /var/www/html/.env ]; then
        cat > /var/www/html/.env <<EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=${APP_KEY:-base64:temp}
APP_DEBUG=false
LOG_CHANNEL=stderr
EOF
        [ -z "$APP_KEY" ] && php artisan key:generate --force 2>/dev/null || true
    fi
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
} &

# Start PHP-FPM
echo "Starting PHP-FPM..."
php-fpm -D
sleep 1

# Verify PHP-FPM is running
if ! pgrep -f php-fpm > /dev/null; then
    echo "ERROR: PHP-FPM failed to start!"
    exit 1
fi
echo "✅ PHP-FPM started"

# Start nginx in foreground (keeps container alive)
echo "Starting nginx on port ${PORT}..."
echo "=========================================="
exec nginx -g 'daemon off;'

