FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    php-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*


# /var/www/html - Web root (where Adminer file stored)
# /run/php - PHP runtime files
RUN mkdir -p /var/www/html /run/php


# Download Adminer (single PHP file!)
# Save as index.php
# Give ownership to web server user
RUN wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php -O /var/www/html/index.php && \
    chown -R www-data:www-data /var/www/html

EXPOSE 8080

# php -S - Start PHP's built-in web server
# 0.0.0.0:8080 - Listen on all interfaces, port 8080
# -t /var/www/html - Document root (where files are)
CMD php -S 0.0.0.0:8080 -t /var/www/html
