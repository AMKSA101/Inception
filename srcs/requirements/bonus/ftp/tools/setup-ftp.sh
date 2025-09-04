#!/bin/bash

# Exit on error
set -e

# Environment variables needed:
# FTP_USER: Username for ftp access
# FTP_PASSWORD: Password for FTP access

# Check if environment variables are set
if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
	echo "Error: FTP_USER and FTP_PASSWORD environment varialbles must be set"
	exit 1
fi

# Create the FTP user if it doesn't exist
if ! id -u "$FTP_USER" &>/dev/null; then
	adduser --disabled-password --gecos "" "$FTP_USER"
	echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
fi

# ADD user to www-data group (to access Wordpress files)
usermod -aG www-data "$FTP_USER"

# Make sure Wordpress directory exists and set permissions
if [ ! -d /var/www/html ]; then
	mkdir -p /var/www/html
fi

# Set correct permissions
chown -R "$FTP_USER":www-data /var/www/html

# Log message
echo "FTP server is ready with user: $FTP_USER"
echo "Mounted Wordpress directory at: /var/www/html"

# Execute the command passed to the script
exec "$@"
