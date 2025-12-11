# Use Debian Bookworm (penultimate stable version) as base image
FROM debian:bookworm

# Update package list and install PHP with all required extensions
# php: PHP programming language
# php-fpm: FastCGI Process Manager (handles PHP execution for NGINX)
# php-mysql: Allows PHP to connect to MariaDB database
# php-curl: Enables HTTP requests from PHP
# php-json: JSON encoding/decoding in PHP
# php-xml: XML parsing in PHP
# php-mbstring: Multibyte string handling (international characters)
# php-zip: ZIP file handling in PHP
# wget: Download tool for fetching WordPress
# mariadb-client: CLI tools to connect to MariaDB for testing
# Clean apt cache to reduce image size
RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    php-mysql \
    php-curl \
    php-json \
    php-xml \
    php-mbstring \
    php-zip \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Create directories for WordPress files and PHP-FPM runtime files
RUN mkdir -p /var/www /run/php

# Download WordPress version 6.4.3 (specific version, not "latest" - required by subject)
# Extract to /var/www/, remove tarball to save space
# Change ownership to www-data user (web server user)
RUN wget https://wordpress.org/wordpress-6.4.3.tar.gz -O /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /var/www/ \
    && rm /tmp/wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/wordpress

# Copy WordPress configuration script from host to container
COPY tools/configure.sh /tmp/configure.sh

# Make the configuration script executable
RUN chmod +x /tmp/configure.sh

# Document that PHP-FPM listens on port 9000 (FastCGI default port)
# NGINX will connect to this port to process PHP files
EXPOSE 9000

# Run configuration script when container starts
# Script will wait for MariaDB, install wp-cli, configure WordPress, create users,
# and start PHP-FPM in foreground mode
CMD ["/tmp/configure.sh"]