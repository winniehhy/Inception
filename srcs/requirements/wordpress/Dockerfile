FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    php-mysql \
    php-curl \
    php-json \
    php-xml \
    php-mbstring \
    php-zip \
    php-redis \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*


# -p flag = "Create parent directories if they don't exist, don't error if it already exists"
# /var/www = Stores WordPress website files
# /run/php =Stores PHP-FPM runtime files (socket, PID
RUN mkdir -p /var/www /run/php


# wget - Download WordPress 6.4.3 from official site
# tar -xzf - Extract the .tar.gz file to /var/www/
# rm - Delete the downloaded archive (save space)
# chown www-data:www-data - 
    # Without chown:
    # User uploads image → WordPress (PHP) tries to save → Permission denied 

    # With chown:
    # User uploads image → WordPress (PHP) saves successfully
RUN wget https://wordpress.org/wordpress-6.4.3.tar.gz -O /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /var/www/ \
    && rm /tmp/wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/wordpress



# Copy your custom setup script into the container
COPY tools/configure.sh /tmp/configure.sh

# Make it executable (+x = can run as a program)
RUN chmod +x /tmp/configure.sh

EXPOSE 9000

# ALWAYS runs & setup script (runs first)
ENTRYPOINT ["/tmp/configure.sh"]

# Runs after ENTRYPOINT completes
# php -r '...' - Detects PHP version (e.g., 7.4 )
# Executes: php-fpm7.4 -F 
# -F - Run in foreground (keeps container alive)
CMD ["sh", "-c", "php-fpm$(php -r 'echo PHP_MAJOR_VERSION.\".\".PHP_MINOR_VERSION;') -F"]