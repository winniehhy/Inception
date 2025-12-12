#!/bin/bash

# if [ ! -d ... ] - Check if directory /var/lib/mysql/mysql Does not exist ( run only first time)
# mysql_install_db - Create the initial database structure
# --user=mysql - Run as mysql user
# --datadir=/var/lib/mysql - Where to store data
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# [!if ...] Check if .setup_complete marker file exists
if [ ! -f "/var/lib/mysql/.setup_complete" ]; then
    echo "Running database setup..."
    
    # mysqld - Start MariaDB server
    # --bind-address=0.0.0.0 (for background setup only -- temporary)
        # 0.0.0.0 = Accept connections from anywhere
        # Allows WordPress container to connect later
        # Without this: Only localhost connections allowed
    # --user=mysql - Run as mysql user
    # & - Run in background
    # $! - Capture the process ID (PID) of background process
    # 
    mysqld --user=mysql --bind-address=0.0.0.0 &
    MYSQL_PID=$!
    
    echo "Waiting for MariaDB to start..."

    # Keep trying to ping MariaDB until it responds
    # --silent - Don't show output
    while ! mysqladmin ping --silent; do
        sleep 1
    done
    
    echo "Creating database and user..."

    #Execute SQL commands as root
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';
FLUSH PRIVILEGES;
EOF
    # Create empty marker file
    # Next time container starts, setup is skipped!
    touch /var/lib/mysql/.setup_complete
    

    # kill - Stop the temporary background MariaDB process
    # wait - Wait for it to fully shut down
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    echo "Database setup complete!"
fi

echo "Starting MariaDB..."

# exec - Replace this script with mysqld (becomes main process)
# --bind-address=0.0.0.0 - Allow connections from other containers (WordPress!)
# Runs in foreground (keeps container alive)
exec mysqld --user=mysql --bind-address=0.0.0.0

#mariadb start background first then foreground. Else cause below
    # mysqld  # Start MariaDB
    # # Script STOPS HERE forever!
    # CREATE DATABASE ...  # Never reaches this! 


# Container starts
#     ↓
# [First time?]
#     ↓ YES
# Install database files
# Start MariaDB temporarily
# Create database + users
# Set passwords
# Stop temporary MariaDB
# Mark as complete
#     ↓
# Start MariaDB permanently (stays running)
#     ↓
# WordPress can now connect! ✅