FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/vsftpd/empty

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh

#20 : Original FTP design where server connects back to client
#21 : Used for sending FTP commands (login, LIST, RETR, STOR, etc.)
        # Persistent connection for the session
        # Only handles commands, not actual data
# The range 21000-21010 allows 11 concurrent data connections:
# Multiple users uploading/downloading simultaneously
# Each transfer needs its own data port
# Prevents port conflicts
EXPOSE 20 21 21000-21010

CMD ["/tmp/setup.sh"]
