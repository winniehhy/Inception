FROM debian:bookworm

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

RUN mkdir -p /var/www /run/php

RUN wget https://wordpress.org/wordpress-6.4.3.tar.gz -O /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /var/www/ \
    && rm /tmp/wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/wordpress

COPY tools/configure.sh /tmp/configure.sh
RUN chmod +x /tmp/configure.sh

EXPOSE 9000

CMD ["/tmp/configure.sh"]