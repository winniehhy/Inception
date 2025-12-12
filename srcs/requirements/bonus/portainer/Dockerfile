FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/libexec/docker/cli-plugins \
    && curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
       -o /usr/libexec/docker/cli-plugins/docker-compose \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose

RUN curl -fsSL https://github.com/portainer/portainer/releases/download/2.20.3/portainer-2.20.3-linux-amd64.tar.gz \
    | tar -xz -C /usr/local/bin --strip-components=1


EXPOSE 9443

CMD ["portainer", "--http-disabled", "--bind=:9443"]