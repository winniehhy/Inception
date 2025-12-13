#!/bin/bash

echo "Starting FTP setup..."

if ! id -u ftpuser > /dev/null 2>&1; then
    echo "Creating ftpuser..."
    useradd -m -d /var/www/wordpress -G www-data ftpuser
    echo "ftpuser:${FTP_PASSWORD}" | chpasswd
    echo "ftpuser" > /etc/vsftpd.userlist
    echo "User ftpuser created successfully"
fi

echo "Setting up permissions..."
chown -R www-data:www-data /var/www/wordpress 2>/dev/null || true
if [ -d /var/www/wordpress/wp-content/uploads ]; then
    chmod -R 775 /var/www/wordpress/wp-content/uploads
fi

echo "Starting vsftpd in foreground mode..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
