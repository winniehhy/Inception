# Use Debian Bookworm (penultimate stable version) as base image
FROM debian:bookworm

# Update package list and install MariaDB server
# Clean apt cache to reduce image size
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Create directory for MariaDB runtime files (PID, socket)
RUN mkdir -p /run/mysqld

# Change ownership to mysql user (MariaDB runs as this user for security)
RUN chown -R mysql:mysql /run/mysqld

# Copy database initialization script from host to container
COPY tools/init.sh /tmp/init.sh

# Make the initialization script executable
RUN chmod +x /tmp/init.sh

# Document that MariaDB listens on port 3306 (default MySQL/MariaDB port)
EXPOSE 3306

# Run initialization script when container starts
# Script will initialize database, create users, and start MariaDB in foreground
CMD ["/tmp/init.sh"]