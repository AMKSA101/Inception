FROM debian:bullseye

# Install necessary packages
RUN apt-get update -y && apt-get install -y \
	curl && apt-get clean  && \
	rm -rf /var/lib/apt/lists/*

# Create directory for website files
RUN mkdir -p /var/www/static-site

# Copy website files
COPY ./website /var/www/static-site

# Set working directory
WORKDIR /var/www/static-site

# Simple health check command
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 CMD ls -la /var/www/static-site/index.html || exit 1

# Keep container running
CMD ["tail", "-f", "/dev/null"]
