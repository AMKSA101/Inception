FROM debian:bullseye

# Install Nginx and OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=MA/ST=State/L=Benguerir/O=UM6P/CN=abamksa.42.fr"

# Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Create necessary directories
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
