#!/bin/bash

# Don't start WordPress setup until MariaDB is ready
# mysqladmin ping - Try to connect to database
# -h"mariadb" - Connect to host named "mariadb" (container name)
# $(cat /run/secrets/db_root_password) - Read password from secret file
# sleep 1 - Wait 1 second between attempts
while ! mysqladmin ping -h"mariadb" -u"root" --password="$(cat /run/secrets/db_root_password)" --silent; do
    sleep 1
done

# Install WP-CLI (WP-CLI = Tool to manage WordPress from terminal)
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod +x /usr/local/bin/wp

#  if [ ! -f ... ] - If config file DOESN'T exist (first run only)
# Create wp-config.php (WordPress configuration file)
# Sets database connection details
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --path=/var/www/wordpress \
        --allow-root

    # Install WordPress (create database tables, set up site)
    # Create admin account with username "hheng"
    # Site title: "Inception"
    # Only runs once (protected by the if check)    
    wp core install \
        --url="hheng.42.fr" \
        --title="Inception" \
        --admin_user="hheng" \
        --admin_password="$(cat /run/secrets/wp_password)" \
        --admin_email="admin@hheng.42.fr" \
        --path=/var/www/wordpress \
        --allow-root
fi

# Create second user with author role (can write posts but not admin)
if ! wp user get wpuser2 --path=/var/www/wordpress --allow-root > /dev/null 2>&1; then
    wp user create wpuser2 user@hheng.42.fr \
        --role=author \
        --user_pass="$(cat /run/secrets/db_password)" \
        --path=/var/www/wordpress \
        --allow-root
fi

# (bonus)
# Check if Redis cache plugin is installed
# If not, download and activate it
# Redis = Makes site faster by caching data
if ! wp plugin is-installed redis-cache --path=/var/www/wordpress --allow-root; then
    wp plugin install redis-cache --activate --path=/var/www/wordpress --allow-root
fi

# Check if Redis settings are already in config
# If not, add these lines to wp-config.php:
# WP_REDIS_HOST = 'redis' (container name)
# WP_REDIS_PORT = 6379 (Redis port)
if ! grep -q "WP_REDIS_HOST" /var/www/wordpress/wp-config.php; then
    sed -i "/<?php/a define('WP_REDIS_HOST', 'redis');\ndefine('WP_REDIS_PORT', 6379);" /var/www/wordpress/wp-config.php
fi

# Turn on Redis caching in WordPress
# 2>/dev/null - Ignore error messages
# || true - Don't fail if already enabled
wp redis enable --path=/var/www/wordpress --allow-root 2>/dev/null || true

# Give ownership of all WordPress files to web server user (so PHP-FPM can read/write them)
chown -R www-data:www-data /var/www/wordpress


# Nginx and wordpress currently run in different containers
# PHP-FPM (in WordPress container) listens on port 9000 for PHP requests
# unix socket (default) only works within same container. Cannot cross containers communication
# change PHP-FPM to listen on port 9000 instead
# in nginx.conf, we set fastcgi_pass to wordpress:9000

# Nginx sends to: wordpress:9000 ➡️
# PHP-FPM listens on: 9000 ✅
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sed -i "s|listen = .*|listen = 9000|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

#exec "$@" - Execute the CMD from Dockerfile
exec "$@"