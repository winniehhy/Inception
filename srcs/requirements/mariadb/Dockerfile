FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/mysqld

RUN chown -R mysql:mysql /run/mysqld

COPY tools/init.sh /tmp/init.sh

RUN chmod +x /tmp/init.sh

EXPOSE 3306

CMD ["/tmp/init.sh"]