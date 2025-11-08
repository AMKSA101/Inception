#!/bin/bash
set -e

echo "Starting WordPress setup..."

# Copy WordPress files to shared volume if they don't exist
if [ ! -f "/var/www/html/index.php" ]; then
    echo "Copying WordPress files to shared volume..."
    cp -r /var/www/wordpress/* /var/www/html/
    chown -R www-data:www-data /var/www/html/
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;
fi

cd /var/www/html

# Wait for MariaDB
echo "Waiting for MariaDB..."
until nc -z mariadb 3306; do
    echo "MariaDB not ready, retrying..."
    sleep 2
done

# Wait for Redis
echo "Waiting for Redis..."
until nc -z redis 6379; do
    echo "Redis not ready, retrying..."
    sleep 2
done

# Configure WordPress if not already done
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Configuring WordPress..."
    
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root

    # Configure Redis
    wp config set WP_REDIS_CLIENT 'phpredis' --allow-root
    wp config set WP_CACHE_KEY_SALT "$DOMAIN_NAME" --allow-root
    wp config set WP_REDIS_HOST 'redis' --allow-root
    wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp config set WP_REDIS_DATABASE 0 --raw --allow-root
    wp config set WP_REDIS_TIMEOUT 1 --raw --allow-root
    wp config set WP_REDIS_READ_TIMEOUT 1 --raw --allow-root
    wp config set FS_METHOD 'direct' --type=constant --allow-root
    
    sleep 5
    
    # Install WordPress
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception WordPress" \
        --admin_user="abamksa" \
        --admin_password="secure_pass_123" \
        --admin_email="abamksa@$DOMAIN_NAME" \
        --allow-root
    
    # Install Redis Cache plugin
    wp plugin install redis-cache --activate --allow-root
    
    # Create additional user
    wp user create wpuser user@$DOMAIN_NAME \
        --user_pass="user123" \
        --role="author" \
        --allow-root
    
    echo "WordPress setup completed!"
else
    echo "WordPress already configured, skipping setup..."
fi

# Set correct permissions
echo "Setting permissions..."
mkdir -p /var/www/html/wp-content/uploads
mkdir -p /var/www/html/wp-content/cache
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/wp-content
chmod 775 /var/www/html/wp-content/uploads
chmod 775 /var/www/html/wp-content/cache

# Copy Redis object-cache drop-in if available
if [ -f "/var/www/html/wp-content/plugins/redis-cache/includes/object-cache.php" ]; then
    cp /var/www/html/wp-content/plugins/redis-cache/includes/object-cache.php /var/www/html/wp-content/object-cache.php
    chown www-data:www-data /var/www/html/wp-content/object-cache.php
    chmod 644 /var/www/html/wp-content/object-cache.php
    echo "Redis object cache enabled"
fi

echo "Starting PHP-FPM..."
exec "$@"
