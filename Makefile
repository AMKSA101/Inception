# INCEPTION PROJECT MAKEFILE
# This Makefile was created to solve the missing automation issue
# It provides easy commands to manage the Docker Compose infrastructure

.PHONY: all build up down clean fclean re logs status help

# DEFAULT TARGET: Build and start the entire infrastructure
# This was the missing piece - provides a simple 'make' command to set everything up
all: build up

# Detect docker-compose or Docker CLI plugin 'compose'
DOCKER_COMPOSE := $(shell if command -v docker-compose >/dev/null 2>&1; then echo docker-compose; \
		elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then echo "docker compose"; \
		else echo ""; fi)

ifeq ($(DOCKER_COMPOSE),)
$(error docker-compose or the Docker CLI 'compose' plugin was not found.\
	Install Docker Compose or enable the Docker compose plugin.)
endif

# BUILD TARGET: Create all Docker images from source
# Builds nginx, wordpress, and mariadb containers with custom configurations
build:
	@echo "Building Docker images..."
	@cd srcs && $(DOCKER_COMPOSE) build

# STARTUP TARGET: Launch all services in detached mode
# Starts containers in background, allows web access via port 443
up:
	@echo "Starting services..."
	@cd srcs && $(DOCKER_COMPOSE) up -d

# SHUTDOWN TARGET: Stop all running containers gracefully
# Preserves volumes and networks for quick restart
down:
	@echo "Stopping services..."
	@cd srcs && $(DOCKER_COMPOSE) down

# CLEANUP TARGET: Remove stopped containers and unused resources
# Useful for freeing up disk space without destroying persistent data
clean: down
	@echo "Cleaning up..."
	@docker system prune -f

# FULL CLEANUP TARGET: Complete infrastructure reset
# Removes everything including volumes, images, and persistent data
# Use this for complete fresh start or when debugging volume issues
fclean: down
	@echo "Full cleanup..."
	@cd srcs && $(DOCKER_COMPOSE) down -v --rmi all
	@docker system prune -af --volumes

# REBUILD TARGET: Complete reset and rebuild
# Equivalent to fclean + all, useful for testing changes from scratch
re: fclean all

# LOGGING TARGET: Monitor container output in real-time
# Essential for debugging container startup and runtime issues
logs:
	@cd srcs && $(DOCKER_COMPOSE) logs -f

# STATUS TARGET: Show current container states
# Quick way to verify which containers are running and their health
status:
	@cd srcs && $(DOCKER_COMPOSE) ps

# HELP TARGET: Display all access points and testing information
# Shows URLs, commands, and instructions for accessing/testing the project
help:
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo "  INCEPTION PROJECT - ACCESS & TESTING GUIDE"
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "📋 MANDATORY SERVICES:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🌐 WordPress Site:"
	@echo "     URL: https://abamksa.42.fr"
	@echo "     Admin Panel: https://abamksa.42.fr/wp-admin/"
	@echo "     Credentials: abamksa / secure_pass_123"
	@echo ""
	@echo "  🗄️  MariaDB:"
	@echo "     Connect: docker exec -it mariadb mysql -u wp_user -p"
	@echo "     Password: (check .env file)"
	@echo "     Database: wordpress"
	@echo ""
	@echo "  🔒 NGINX:"
	@echo "     Port: 443 (HTTPS only)"
	@echo "     SSL: TLSv1.2 & TLSv1.3"
	@echo "     Check: openssl s_client -connect abamksa.42.fr:443 -tls1_2"
	@echo ""
	@echo "🎁 BONUS SERVICES:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  ⚡ Redis Cache:"
	@echo "     Connect: docker exec -it redis redis-cli"
	@echo "     Auth: AUTH <password from .env>"
	@echo "     Test: PING (should return PONG)"
	@echo ""
	@echo "  📁 FTP Server:"
	@echo "     Access: Internal network only (no external ports)"
	@echo "     Connect: docker exec -it ftp sh"
	@echo "     Volume: /var/www/html (WordPress files)"
	@echo ""
	@echo "  🎨 Static Website:"
	@echo "     URL: https://static.abamksa.42.fr"
	@echo "     Technology: Pure JavaScript/HTML/CSS"
	@echo ""
	@echo "  🗂️  Adminer (DB Manager):"
	@echo "     URL: https://adminer.abamksa.42.fr"
	@echo "     System: MySQL"
	@echo "     Server: mariadb"
	@echo "     Username: wp_user"
	@echo ""
	@echo "  🐋 Portainer (Docker UI):"
	@echo "     Access: Internal network only"
	@echo "     Connect: docker exec -it portainer sh"
	@echo ""
	@echo "🧪 TESTING COMMANDS:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Check all containers:    make status"
	@echo "  View live logs:          make logs"
	@echo "  Test NGINX TLS:          curl -Ik https://abamksa.42.fr"
	@echo "  Test WordPress:          curl -Ik https://abamksa.42.fr/wp-admin/"
	@echo "  Check volumes:           ls -la /home/joker/data/"
	@echo "  Test auto-restart:       docker stop wordpress && sleep 5 && docker ps"
	@echo "  Check network:           docker network inspect srcs_inception-network"
	@echo "  Redis test:              docker exec -it redis redis-cli PING"
	@echo ""
	@echo "📂 VOLUME LOCATIONS:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  MariaDB data:   /home/joker/data/mariadb"
	@echo "  WordPress data: /home/joker/data/wordpress"
	@echo ""
	@echo "⚠️  IMPORTANT NOTES:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  • Make sure /etc/hosts contains: 127.0.0.1 abamksa.42.fr"
	@echo "  • Add subdomains: 127.0.0.1 static.abamksa.42.fr adminer.abamksa.42.fr"
	@echo "  • Accept self-signed certificate warnings in browser"
	@echo "  • All services use HTTPS only (no HTTP)"
	@echo "  • Passwords are in srcs/.env file"
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════════════════"
