#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

if [ ! -f "/var/lib/mysql/.setup_complete" ]; then
    echo "Running database setup..."
    
    mysqld --user=mysql --bind-address=0.0.0.0 &
    MYSQL_PID=$!
    
    echo "Waiting for MariaDB to start..."
    while ! mysqladmin ping --silent; do
        sleep 1
    done
    
    echo "Creating database and user..."
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';
FLUSH PRIVILEGES;
EOF
    
    touch /var/lib/mysql/.setup_complete
    
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    echo "Database setup complete!"
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql --bind-address=0.0.0.0
