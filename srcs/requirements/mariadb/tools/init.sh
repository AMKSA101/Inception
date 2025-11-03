#!/bin/bash

echo "Starting MariaDB initialization script..."

# DATABASE INITIALIZATION CHECK: Prevent duplicate initialization
# Check if our custom database exists to determine if this is first run
# This prevents re-running initialization on container restarts
if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
	echo "First run - initializing database..."
	
	# MARIADB SYSTEM TABLES: Install base MySQL system tables if needed
	# This creates the basic mysql.* tables required for MariaDB operation
	if [ ! -d "/var/lib/mysql/mysql" ]; then
		echo "Installing MariaDB system tables..."
		mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
	fi

	# TEMPORARY STARTUP: Start MariaDB in setup mode
	# --skip-networking prevents external connections during setup
	# --socket=/tmp/mysql.sock creates a local socket for configuration
	echo "Starting MariaDB for setup..."
	mysqld_safe --skip-networking --socket=/tmp/mysql.sock &
	MYSQL_PID=$!
	echo "MariaDB started with PID: $MYSQL_PID"

	# STARTUP VERIFICATION: Wait for MariaDB to accept connections
	# Uses mysqladmin ping to test actual database connectivity
	# Timeout after 30 seconds to prevent infinite waiting
	echo "Waiting for MariaDB to be ready..."
	for i in {1..30}; do
		if mysqladmin ping --socket=/tmp/mysql.sock --silent 2>/dev/null; then
			echo "MariaDB is ready after $i seconds"
			break;
		fi
		echo "Waiting... ($i/30)"
		sleep 1
	done

	# DATABASE SETUP: Execute SQL commands for WordPress preparation
	# Creates database, user, and sets up proper permissions
	echo "Executing database setup commands..."
	mysql --socket=/tmp/mysql.sock <<EOF
-- SECURITY CONFIGURATION: Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';

-- WORDPRESS DATABASE: Create dedicated database for WordPress
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;

-- WORDPRESS USER: Create dedicated user for WordPress application
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';

-- PERMISSIONS: Grant WordPress user full access to WordPress database
-- '%' allows connections from any host (required for container networking)
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';

-- SECURITY HARDENING: Remove anonymous users (security best practice)
DELETE FROM mysql.user WHERE User='';

-- SECURITY HARDENING: Remove remote root access (security best practice)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');

-- APPLY CHANGES: Reload privilege tables to activate all changes
FLUSH PRIVILEGES;
EOF

	echo "Database initialization completed!"

	# CLEANUP: Stop the temporary MariaDB instance
	# The process will restart normally after this script completes
	echo "Stopping temporary MariaDB instance..."
	kill $MYSQL_PID
	wait $MYSQL_PID
	echo "Temporary MariaDB instance stopped"
fi

# NORMAL STARTUP: Start MariaDB in production mode
# exec "$@" passes control to the CMD from Dockerfile (mysqld)
# This allows external connections and normal database operations
echo "Starting MariaDB in normal mode..."
exec "$@"
