# Use Debian Bookworm (penultimate stable version) as base image
FROM debian:bookworm

# Update package list and install NGINX web server and OpenSSL for certificates
# Clean apt cache to reduce image size
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create self-signed SSL/TLS certificate for HTTPS
# -newkey rsa:4096: Generate 4096-bit RSA key (very secure)
# -x509: Create self-signed certificate (not from Certificate Authority)
# -sha256: Use SHA-256 hash algorithm
# -days 365: Valid for 1 year
# -nodes: No password protection (no DES encryption)
# -subj: Certificate subject with domain name (CN = Common Name)
RUN openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
    -out /etc/ssl/certs/nginx.crt \
    -keyout /etc/ssl/private/nginx.key \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=hheng.42.fr www.hheng.42.fr"

# Copy custom NGINX configuration to default site location
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Document that NGINX listens on port 443 (HTTPS with SSL/TLS)
EXPOSE 443

# Start NGINX in foreground mode (required for Docker container to stay alive)
# "daemon off" prevents NGINX from running as background process
CMD ["nginx", "-g", "daemon off;"]