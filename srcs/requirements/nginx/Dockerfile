FROM debian:bullseye

# Installing Nginx && OpenSSL

RUN apt update -y && \
	apt install -y nginx openssl \
	&& rm -rf /var/lib/apt/lists/*

# Create a self-signed certificate
RUN openssl req -x509 -nodes -out /etc/ssl/certs/nginx-selfsigned.crt \
	-keyout /etc/ssl/private/nginx-selfsigned.key -subj "/C=MA/ST=State/L=Benguerir/O=UM6P/CN=abamksa.42.fr"

# Copy our custom NGINX configuration
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Expose HTTPS port, static website port, and adminer port
EXPOSE 443 8080 8081

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
