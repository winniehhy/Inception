#!/bin/bash

# Create FTP user if not exists
if ! id -u ${FTP_USER} > /dev/null 2>&1; then
    useradd -m ${FTP_USER}
    echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
    echo "${FTP_USER}" > /etc/vsftpd.userlist
fi

# Give FTP user access to WordPress files
chown -R ${FTP_USER}:${FTP_USER} /var/www/wordpress

# Start vsftpd
exec /usr/sbin/vsftpd /etc/vsftpd.conf
