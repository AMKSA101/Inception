FROM debian:bullseye

# Install MariaDB
RUN apt-get update -y && apt-get install -y mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

# Copy configuration file
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Create necessary directories and set permissions
RUN mkdir -p /var/run/mysqld \
	&& chown -R mysql:mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql

# Expose MySQL port
EXPOSE 3306

# Switch to mysql user
USER mysql

# Run our initialization script
ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["mysqld"] 
