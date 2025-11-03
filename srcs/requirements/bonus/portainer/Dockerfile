# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: your_username <your_email@student.42>     +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/11/01                           #+#    #+#                  #
#    Updated: 2025/11/01                          ###   ########.fr            #
#                                                                              #
# **************************************************************************** #

# # TODO: Choose the base image
# # Hint: We'll use Alpine Linux for a lightweight container
# # Alpine is perfect because Portainer provides a pre-built binary for it
# FROM alpine:3.19

# # TODO: Install necessary packages
# # Hint: Portainer needs 'ca-certificates' for HTTPS connections
# RUN apk update && apk add --no-cache \
# 	ca-certificates \
# 	curl \
# 	&& rm -rf /var/cache/apk/*

# # TODO: Download Portainer binary
# # Hint: Get it from GitHub releases - portainer-ce (Community Edition)
# # URL pattern: https://github.com/portainer/portainer/releases/download/VERSION/portainer-linux-amd64.tar.gz
# RUN curl -L https://github.com/portainer/portainer/releases/download/2.19.4/portainer-linux-amd64.tar.gz | tar -xz -C /tmp \
# 	&& mv /tmp/portainer/portainer /usr/local/bin \
# 	&& chmod +x /usr/local/bin/portainer \
# 	&& rm -rf /tmp/portainer

# # TODO: Create a directory for Portainer data
# # Hint: Portainer stores its database in /data
# RUN mkdir -p /data

# # TODO: Expose the web interface port
# # Hint: Portainer uses port 9000 for HTTP and 9443 for HTTPS
# EXPOSE 9443

# # TODO: Set the startup command
# # Hint: Run /portainer with the appropriate flags
# # Use --bind :9443 for HTTPS and --ssl for secure connections
# CMD ["/usr/local/bin/portainer", "--bind", ":9443", "--ssl"]
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# PORTAINER CE (Community Edition) - Docker Management UI
# Using official Alpine-based Portainer image for reliability
# This is the RECOMMENDED approach over manual binary downloads
FROM portainer/portainer-ce:2.19.4-alpine

# EXPLANATION: Why use the official image?
# 1. Pre-built and tested by Portainer team
# 2. Includes all dependencies and proper configuration
# 3. Regular security updates
# 4. Smaller final image size
# 5. No need to manually download/extract binaries

# The official image already:
# - Exposes port 9443 (HTTPS) and 9000 (HTTP)
# - Creates /data directory for persistent storage
# - Sets up the correct entrypoint
# - Includes CA certificates

# We just need to ensure volumes are mounted:
# - /var/run/docker.sock for Docker API access
# - /data for persistent configuration

# No additional configuration needed!
# The CMD is already set in the base image

