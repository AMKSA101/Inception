#!/bin/bash
echo "Starting FTP server setup..."

if id "$FTP_USER" &>/dev/null; then
	echo "user $FTP_USER already exists!"
else
	echo "Adding a user $FTP_USER"
	useradd -m -d /var/www/html -s /bin/bash "$FTP_USER"
	echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
fi

mkdir -p /var/www/html
chown $FTP_USER:$FTP_USER /var/www/html
chmod 755 /var/www/html

echo "FTP server setup completed!"
exec "$@"
