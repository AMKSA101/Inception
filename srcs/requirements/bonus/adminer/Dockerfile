FROM debian:bullseye

# Install necessary packages
RUN apt-get update -y && apt-get install -y \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-mysqli \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/www/adminer /run/php

# Download Adminer
RUN wget -O /var/www/adminer/index.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

# Configure PHP-FPM
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/adminer

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm7.4", "-F"]
