FROM debian:bullseye

# Install Python for simple HTTP server
RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Create website directory
RUN mkdir -p /var/www/static-site

# Copy website files
COPY website /var/www/static-site

WORKDIR /var/www/static-site

# Health check
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
    CMD ls -la /var/www/static-site/index.html || exit 1

CMD ["python3", "-m", "http.server", "8000"]
