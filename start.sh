#!/bin/bash
set -eux

a2dismod mpm_event mpm_worker || true
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.* || true
a2enmod mpm_prefork

sed -ri "s/Listen 80/Listen ${PORT:-80}/g" /etc/apache2/ports.conf
sed -ri "s/:80>/:${PORT:-80}>/g" /etc/apache2/sites-available/000-default.conf

cat > /var/www/html/.env <<EOF
APP_NAME=${APP_NAME:-}
APP_DESC=${APP_DESC:-}
APP_ENV=${APP_ENV:-production}
APP_DEBUG=${APP_DEBUG:-false}
ENCRYPTION_KEY=${ENCRYPTION_KEY:-}
Domain=${Domain:-}
CookieName=${CookieName:-}
R2_BUCKET=${R2_BUCKET:-}
R2_ACCOUNT_ID=${R2_ACCOUNT_ID:-}
R2_KEY_ID=${R2_KEY_ID:-}
R2_SECRET=${R2_SECRET:-}
MAINTENANCE=${MAINTENANCE:-false}
ACTUAL_MAINTENANCE=${ACTUAL_MAINTENANCE:-false}
DB_HOST=${DB_HOST:-}
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
EOF

echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE" > /usr/local/etc/php/conf.d/99-deprecated.ini

apache2-foreground
