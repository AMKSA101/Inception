COMPOSE_FILE = srcs/docker-compose.yml
ENV_FILE = srcs/.env

.PHONY: all setup build up down restart logs clean fclean re status

all: build up

setup:
	@echo "Setting up data directories..."
	@mkdir -p /home/joker/data/mariadb
	@mkdir -p /home/joker/data/wordpress

build: setup
	@echo "Building Docker images..."
	docker compose -f $(COMPOSE_FILE) build

up: build
	@echo "Starting services..."
	docker compose -f $(COMPOSE_FILE) up -d

down:
	@echo "Stopping services..."
	docker compose -f $(COMPOSE_FILE) down

restart: down up

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

clean: down
	@echo "Cleaning up..."
	docker compose -f $(COMPOSE_FILE) down -v --rmi all
	docker system prune -af

fclean: clean
	@echo "Removing volumes and data..."
	@rm -rf /home/joker/data/mariadb/*
	@rm -rf /home/joker/data/wordpress/*

re: fclean all

status:
	docker compose -f $(COMPOSE_FILE) ps
