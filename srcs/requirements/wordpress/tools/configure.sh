#!/bin/bash

while ! mysqladmin ping -h"mariadb" -u"root" --password="$(cat /run/secrets/db_root_password)" --silent; do
    sleep 1
done

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod +x /usr/local/bin/wp

if [ ! -f /var/www/wordpress/wp-config.php ]; then
    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --path=/var/www/wordpress \
        --allow-root
        
    wp core install \
        --url="hheng.42.fr" \
        --title="Inception" \
        --admin_user="hheng" \
        --admin_password="$(cat /run/secrets/wp_password)" \
        --admin_email="admin@hheng.42.fr" \
        --path=/var/www/wordpress \
        --allow-root
fi

if ! wp user get wpuser2 --path=/var/www/wordpress --allow-root > /dev/null 2>&1; then
    wp user create wpuser2 user@hheng.42.fr \
        --role=author \
        --user_pass="$(cat /run/secrets/db_password)" \
        --path=/var/www/wordpress \
        --allow-root
fi

if ! wp plugin is-installed redis-cache --path=/var/www/wordpress --allow-root; then
    wp plugin install redis-cache --activate --path=/var/www/wordpress --allow-root
fi

if ! grep -q "WP_REDIS_HOST" /var/www/wordpress/wp-config.php; then
    sed -i "/<?php/a define('WP_REDIS_HOST', 'redis');\ndefine('WP_REDIS_PORT', 6379);" /var/www/wordpress/wp-config.php
fi

wp redis enable --path=/var/www/wordpress --allow-root 2>/dev/null || true

chown -R www-data:www-data /var/www/wordpress

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sed -i "s|listen = .*|listen = 9000|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

exec "$@"