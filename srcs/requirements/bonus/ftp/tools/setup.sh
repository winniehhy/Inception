#!/bin/bash

# Create FTP user if not exists
if ! id -u ftpuser > /dev/null 2>&1; then
    # Create user with WordPress as home directory (no -m to avoid creating /home/ftpuser)
    useradd -d /var/www/wordpress ftpuser
    # Read password from secret file
    FTP_PASS=$(cat /run/secrets/ftp_password.txt 2>/dev/null || cat /run/secrets/ftp_password 2>/dev/null || echo "defaultpass")
    echo "ftpuser:${FTP_PASS}" | chpasswd
    echo "ftpuser" > /etc/vsftpd.userlist
fi

# Give FTP user access to WordPress files
chown -R ftpuser:ftpuser /var/www/wordpress

# Start vsftpd
exec /usr/sbin/vsftpd /etc/vsftpd.conf
