FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and install Portainer
RUN wget https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz && \
    tar -xvzf portainer-2.19.4-linux-amd64.tar.gz && \
    mv portainer/portainer /usr/local/bin/portainer && \
    chmod +x /usr/local/bin/portainer && \
    rm -rf portainer portainer-2.19.4-linux-amd64.tar.gz

EXPOSE 9000

CMD ["/usr/local/bin/portainer", "--bind=:9000"]
