FROM debian:bullseye

# Install PHP-FPM and required extensions
RUN apt-get update && apt-get install -y \
	php-fpm \
	php-redis \
	php-mysql \
	php-xmlrpc \
	php-gd \
	php-mbstring \
	php-xml \
	php-curl \
	php-soap \
	php-intl \
	php-zip \
	wget \
	curl \
	netcat \
	default-mysql-client \
	&& rm -rf /var/lib/apt/lists/*

# Download WordPress
RUN wget https://wordpress.org/latest.tar.gz -P /var/www/ \
	&& cd /var/www && tar -xzf latest.tar.gz \
	&& rm latest.tar.gz \
	&& chown -R www-data:www-data /var/www/wordpress

# Download and install WP-CLI
RUN curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar -o wp-cli.phar \
	&& php wp-cli.phar --info \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Copy configuration files
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/setup-wordpress.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create necessary directories
RUN mkdir -p /run/php /var/www/html \
	&& chown -R www-data:www-data /var/www/html

EXPOSE 9000

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm7.4", "-F"]
