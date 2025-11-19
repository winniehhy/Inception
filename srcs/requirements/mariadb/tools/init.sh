#!/bin/bash

# Initialize MariaDB data directory if it doesn't exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Check if the database setup is complete
if [ ! -f "/var/lib/mysql/.setup_complete" ]; then
    echo "Running database setup..."
    
    # Start MariaDB in background (bind to all interfaces)
    mysqld --user=mysql --bind-address=0.0.0.0 &
    MYSQL_PID=$!
    
    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to start..."
    while ! mysqladmin ping --silent; do
        sleep 1
    done
    
    echo "Creating database and user..."
    # Run setup SQL
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';
FLUSH PRIVILEGES;
EOF
    
    # Mark setup as complete
    touch /var/lib/mysql/.setup_complete
    
    # Stop the background MariaDB
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    echo "Database setup complete!"
fi

# Start MariaDB normally
echo "Starting MariaDB..."
exec mysqld --user=mysql --bind-address=0.0.0.0
