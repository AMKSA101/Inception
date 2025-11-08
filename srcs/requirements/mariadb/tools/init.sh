#!/bin/bash
set -e

echo "Starting MariaDB initialization..."

# Initialize database if it doesn't exist
if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    echo "First run - initializing database..."
    
    # Install system tables if needed
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "Installing MariaDB system tables..."
        mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    fi

    # Start MariaDB temporarily for setup
    echo "Starting MariaDB for setup..."
    mysqld_safe --skip-networking --socket=/tmp/mysql.sock &
    MYSQL_PID=$!

    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB..."
    for i in {1..30}; do
        if mysqladmin ping --socket=/tmp/mysql.sock --silent 2>/dev/null; then
            echo "MariaDB is ready"
            break
        fi
        sleep 1
    done

    # Configure database
    echo "Configuring database..."
    mysql --socket=/tmp/mysql.sock <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');
FLUSH PRIVILEGES;
EOF

    echo "Database initialization completed!"

    # Stop temporary instance
    echo "Stopping temporary MariaDB..."
    mysqladmin --socket=/tmp/mysql.sock -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
    wait $MYSQL_PID 2>/dev/null || true
    sleep 2
fi

echo "Starting MariaDB..."
exec "$@"
