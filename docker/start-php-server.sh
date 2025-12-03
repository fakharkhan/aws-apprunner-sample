#!/bin/sh
# Use PHP built-in server - simplest possible approach
exec 1>&2

PORT=${PORT:-8000}
echo "Starting PHP server on port ${PORT}"

# Quick .env setup
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

# Set permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Start PHP built-in server (listens on all interfaces by default)
echo "Starting PHP server on 0.0.0.0:${PORT}..."
cd /var/www/html/public
exec php -S 0.0.0.0:${PORT} -t /var/www/html/public

