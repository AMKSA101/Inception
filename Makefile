# INCEPTION PROJECT MAKEFILE
# This Makefile was created to solve the missing automation issue
# It provides easy commands to manage the Docker Compose infrastructure

.PHONY: all build up down clean fclean re logs

# DEFAULT TARGET: Build and start the entire infrastructure
# This was the missing piece - provides a simple 'make' command to set everything up
all: build up

# BUILD TARGET: Create all Docker images from source
# Builds nginx, wordpress, and mariadb containers with custom configurations
build:
	@echo "Building Docker images..."
	@cd srcs && docker-compose build

# STARTUP TARGET: Launch all services in detached mode
# Starts containers in background, allows web access via port 443
up:
	@echo "Starting services..."
	@cd srcs && docker-compose up -d

# SHUTDOWN TARGET: Stop all running containers gracefully
# Preserves volumes and networks for quick restart
down:
	@echo "Stopping services..."
	@cd srcs && docker-compose down

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
	@cd srcs && docker-compose down -v --rmi all
	@docker system prune -af --volumes

# REBUILD TARGET: Complete reset and rebuild
# Equivalent to fclean + all, useful for testing changes from scratch
re: fclean all

# LOGGING TARGET: Monitor container output in real-time
# Essential for debugging container startup and runtime issues
logs:
	@cd srcs && docker-compose logs -f

# STATUS TARGET: Show current container states
# Quick way to verify which containers are running and their health
status:
	@cd srcs && docker-compose ps
