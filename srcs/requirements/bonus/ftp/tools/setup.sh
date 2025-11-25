#!/bin/bash

# Create FTP user if not exists
if ! id -u ftpuser > /dev/null 2>&1; then
    useradd -m ftpuser
    echo "ftpuser:$(cat /run/secrets/ftp_password)" | chpasswd
    echo "ftpuser" > /etc/vsftpd.userlist
fi

# Give FTP user access to WordPress files
chown -R ftpuser:ftpuser /var/www/wordpress

# Start vsftpd
exec /usr/sbin/vsftpd /etc/vsftpd.conf
