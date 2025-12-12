FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Create directory for MariaDB's PID and socket files (similar like php-fpm)
RUN mkdir -p /run/mysqld

#Give ownership to mysql user
RUN chown -R mysql:mysql /run/mysqld

# Copy your database script
COPY tools/init.sh /tmp/init.sh

RUN chmod +x /tmp/init.sh

#standard mariadb port
EXPOSE 3306

# When container starts, run init script
CMD ["/tmp/init.sh"]