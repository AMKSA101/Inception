FROM debian:bullseye

# PACKAGE INSTALLATION: Install PHP-FPM and required extensions
# CRITICAL FIX: Changed 'mysql-client' to 'default-mysql-client' 
# The original 'mysql-client' package doesn't exist in Debian Bullseye
# 'default-mysql-client' provides mysqladmin for database connectivity testing
RUN apt-get update -y && apt-get install -y \
	php-fpm \
	php-redis\
	php-mysql \
	php-xmlrpc \
	php-gd 		\
	php-mbstring \
	php-xml 	  \
	php-curl 	   \
	php-soap 		\
	php-intl 		 \
	php-zip 		  \
	wget 			   \
	curl				\
	default-mysql-client \
	&& rm -rf /var/lib/apt/lists/*

# WORDPRESS DOWNLOAD: Get latest WordPress core files
# Downloads and extracts WordPress to /var/www/wordpress/
# This serves as the source for copying files to the shared volume
RUN wget https://wordpress.org/latest.tar.gz -P /var/www/ \
	&& cd /var/www && tar -xzf latest.tar.gz \
	&& rm latest.tar.gz \
	&& chown -R www-data:www-data /var/www/wordpress

# WP-CLI DOWNLOAD: Install WordPress Command Line Interface
# CRITICAL FIX: Changed URL from wp-cli.org/builds to GitHub releases
# The original URL (wp-cli.org/builds/wp-cli-2.8.1.phar) returned 404 errors
# GitHub releases URL is more reliable and provides the latest stable version
RUN curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar -o wp-cli.phar \
	&& php wp-cli.phar --info \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp
# WP-CLI PURPOSE:
# - Automates WordPress installation without web interface
# - Creates database configuration (wp-config.php)
# - Sets up admin and additional users programmatically
# - Enables headless WordPress deployment in containers

# PHP-FPM CONFIGURATION: Copy custom pool configuration
# The www.conf file contains fixed PHP-FPM pool settings
# This file was modified to resolve PHP-FPM startup errors
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# SETUP SCRIPT: Copy and prepare WordPress initialization script
# This script handles database connectivity, WordPress setup, and file management
COPY tools/setup-wordpress.sh /usr/local/bin/setup-wordpress.sh
RUN chmod +x /usr/local/bin/setup-wordpress.sh

# PHP-FPM REQUIREMENTS: Create socket directory
# PHP-FPM needs /run/php for socket files and PID files
RUN mkdir -p /run/php

# Expose PHP-FPM port
EXPOSE 9000

# Set working directory
WORKDIR /var/www/wordpress

# Start setup script
ENTRYPOINT ["/usr/local/bin/setup-wordpress.sh"]
CMD ["php-fpm7.4", "-F"]
