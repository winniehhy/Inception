#!/bin/bash

if ! id -u ftpuser > /dev/null 2>&1; then
  
    useradd -m -d /var/www/wordpress -G www-data ftpuser
    FTP_PASS=$(cat /run/secrets/ftp_password.txt 2>/dev/null || cat /run/secrets/ftp_password 2>/dev/null || echo "defaultpass")
    echo "ftpuser:${FTP_PASS}" | chpasswd
    echo "ftpuser" > /etc/vsftpd.userlist
fi


chown -R www-data:www-data /var/www/wordpress
chmod -R 775 /var/www/wordpress/wp-content/uploads

exec /usr/sbin/vsftpd /etc/vsftpd.conf
