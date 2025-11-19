#!/bin/bash

# Wait for database to be ready
while ! mysqladmin ping -h"mariadb" -u"root" --password="$(cat /run/secrets/db_root_password)" --silent; do
    sleep 1
done

# Download wp-cli
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod +x /usr/local/bin/wp

# Create wp-config.php if it doesn't exist
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --path=/var/www/wordpress \
        --allow-root
        
    # Install WordPress
    wp core install \
        --url="hheng.42.fr" \
        --title="Inception" \
        --admin_user="admin" \
        --admin_password="$(cat /run/secrets/db_password)" \
        --admin_email="admin@hheng.42.fr" \
        --path=/var/www/wordpress \
        --allow-root
fi

chown -R www-data:www-data /var/www/wordpress

# Configure PHP-FPM to listen on all interfaces
sed -i 's/listen = .*/listen = 9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Start PHP-FPM
php-fpm7.4 -F

# Start PHP-FPM
php-fpm7.4 -F