FROM debian:bullseye

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Download and install Portainer with web assets
RUN curl -L https://github.com/portainer/portainer/releases/download/2.9.3/portainer-2.9.3-linux-amd64.tar.gz -o portainer.tar.gz && \
    tar xzf portainer.tar.gz -C /tmp && \
    mv /tmp/portainer /usr/local/ && \
    chmod +x /usr/local/portainer/portainer && \
    ln -s /usr/local/portainer/portainer /usr/local/bin/portainer && \
    rm portainer.tar.gz

# Create data directory
RUN mkdir -p /data

EXPOSE 9000 9443

ENV DOCKER_CONFIG=/root/.docker

WORKDIR /usr/local/portainer

CMD ["/usr/local/bin/portainer"]
