FROM debian:bullseye


# apt-get update - Update package list (like checking what's in the store)
# install nginx - Web server software
# install openssl - Tool to create SSL certificates (for HTTPS)
# rm -rf /var/lib/apt/lists/* - Delete cache to make image smaller (cleanup)
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

#create self-signed SSL certificate
# req -x509: create self signed cert
# sha256 - hashing algorithm
# days 365 - valid for 1 year
# nodes - no need password everytime server restarts
# out - where to save cert
# keyout - where to save private key
# subj - auto fill up certificate details ( C=FR - Country: France // CN=hheng.42.fr - Domain name)
RUN openssl req  -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
    -out /etc/ssl/certs/nginx.crt \
    -keyout /etc/ssl/private/nginx.key \
    -subj "/C=MY/ST=KL/L=SELANGOR/O=42KL/OU=42/CN=hheng.42.fr"

#Copy  custom nginx configuration file into the container. Tells nginx how to behave
COPY conf/nginx.conf /etc/nginx/sites-available/default

EXPOSE 443

# CMD = command
# nginx - Start the nginx web server
# -g daemon off; - Keep nginx running in the foreground (so the container doesn't stop) until we tell it to stop
# subject rules :NO infinite loops, NO 'tail -f', NO 'sleep infinity
CMD ["nginx", "-g", "daemon off;"]