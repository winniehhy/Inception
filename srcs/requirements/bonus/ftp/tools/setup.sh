#!/bin/bash

if ! id -u ftpuser > /dev/null 2>&1; then
    useradd -d /var/www/wordpress ftpuser
    FTP_PASS=$(cat /run/secrets/ftp_password.txt 2>/dev/null || cat /run/secrets/ftp_password 2>/dev/null || echo "defaultpass")
    echo "ftpuser:${FTP_PASS}" | chpasswd
    echo "ftpuser" > /etc/vsftpd.userlist
fi

chown -R ftpuser:ftpuser /var/www/wordpress

exec /usr/sbin/vsftpd /etc/vsftpd.conf
