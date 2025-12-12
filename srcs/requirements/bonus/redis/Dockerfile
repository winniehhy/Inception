FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# sed -i = stream editor ( find and replace)
    # -i = in-place (modify file directly)
# sed 's/old_text/new_text/g' file.txt

# why channge bind address and protected mode?
# Default settings (security focused)
# bind 127.0.0.1           # Only accept local connections
# protected-mode yes       # Require password/restricted access
# Causing wordrpess container to be unable to connect to redis container

RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf && \
    sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "--protected-mode", "no"]
