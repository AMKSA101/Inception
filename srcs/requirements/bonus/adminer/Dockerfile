FROM debian:bullseye

# Install PHP-FPM and MySQL extension
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-mysqli \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /var/www/adminer /run/php

# Download Adminer
RUN wget -O /var/www/adminer/index.php \
    https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/

# Set permissions
RUN chown -R www-data:www-data /var/www/adminer

EXPOSE 9000

CMD ["php-fpm7.4", "-F"]
