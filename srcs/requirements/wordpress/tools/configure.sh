#!/bin/bash

# Wait for database to be ready
while ! mysqladmin ping -h"mariadb" -u"root" --password="$(cat /run/secrets/db_root_password)" --silent; do
    sleep 1
done

# Copy WordPress files if they don't exist
if [ ! -f /var/www/html/wp-config.php ]; then
    cp -r /var/www/wordpress/* /var/www/html/
    chown -R www-data:www-data /var/www/html
fi

# Start PHP-FPM
php-fpm7.4 -F