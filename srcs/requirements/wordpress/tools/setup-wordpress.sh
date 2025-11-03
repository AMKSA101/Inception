#!/bin/bash

echo "Starting WordPress setup..."

# CRITICAL FIX: Copy WordPress files to shared volume if they don't exist
# This solves the major issue where NGINX couldn't serve WordPress files because
# they were only available in the WordPress container at /var/www/wordpress/
# but the shared volume was mounted at /var/www/html/. By copying the files
# to the shared volume, both WordPress (PHP-FPM) and NGINX can access them.
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Copying WordPress files to shared volume..."
    # Copy all WordPress core files from installation directory to shared volume
    cp -r /var/www/wordpress/* /var/www/html/
    # Set proper ownership for web server access
    chown -R www-data:www-data /var/www/html/
fi

# Change to the shared directory for WP-CLI operations
# All WP-CLI commands must run from the WordPress root directory
cd /var/www/html

# DATABASE CONNECTIVITY FIX: Wait for MariaDB to be ready
# This ensures WordPress doesn't try to connect before MariaDB is fully initialized
# The mysqladmin ping command tests actual database connectivity, not just container status
echo "Waiting for MariaDB to be ready..."
while ! mysqladmin ping -h"mariadb" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    echo "Waiting for database connection..."
    sleep 2
done
echo "MariaDB is ready!"

# Check if WordPress is already configured
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Configuring WordPress for the first time..."
    
    # WORDPRESS CONFIGURATION: Create WordPress configuration file
    # This connects WordPress to the MariaDB database using environment variables
    # --allow-root is necessary because we're running as root in the container
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root

	wp config set WP_CACHE true --type=constant --allow-root
	wp config set WP_CACHE_KEY_SALT "$DOMAIN_NAME" --type=constant --allow-root
	wp config set REDIS_HOST redis --type=constant --allow-root
	wp config set REDIS_PASSWORD "$REDIS_PASSWORD" --type=constant --allow-root
	wp config set REDIS_PORT 6379 --type=constant --allow-root
    
    # WORDPRESS INSTALLATION: Set up WordPress with initial content
    # Creates the admin user and configures basic site settings
    # Note: Username must not contain 'admin', 'Admin', 'administrator', or 'Administrator'
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception WordPress" \
        --admin_user="abamksa" \
        --admin_password="secure_pass_123" \
        --admin_email="abamksa@$DOMAIN_NAME" \
        --allow-root
	
    wp plugin install redis-cache --activate
    # ADDITIONAL USER CREATION: Create a second user for testing
    # Demonstrates multi-user capability as per project requirements
    wp user create wpuser user@$DOMAIN_NAME \
        --user_pass="user123" \
        --role="author" \
        --allow-root
    
    echo "WordPress setup completed!"
else
    echo "WordPress already configured, skipping setup..."
fi

# PHP-FPM STARTUP: Start the PHP-FPM service
# exec "$@" passes control to the CMD specified in Dockerfile (php-fpm7.4 -F)
# The -F flag runs PHP-FPM in foreground mode, keeping the container alive
echo "Starting PHP-FPM..."
exec "$@"
