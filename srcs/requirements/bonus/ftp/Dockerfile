FROM debian:bullseye

# Install vsftpd
RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/run/vsftpd/empty /var/www/html \
    && chown -R ftp:ftp /var/www/html

# Copy configuration and setup script
COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup-ftp.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/sbin/vsftpd", "/etc/vsftpd.conf"]
