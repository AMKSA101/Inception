#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           INCEPTION PROJECT - SYSTEM CHECK                      ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print section header
print_header() {
    echo ""
    echo -e "${YELLOW}━━━ $1 ━━━${NC}"
}

# Check if docker-compose is installed
print_header "Prerequisites Check"
if command -v docker-compose &> /dev/null; then
    print_status 0 "docker-compose is installed"
    docker-compose --version
    DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    print_status 0 "Docker Compose plugin is installed"
    docker compose version
    DOCKER_COMPOSE="docker compose"
else
    print_status 1 "docker-compose or Docker Compose plugin not found"
    exit 1
fi

# Check if Docker is running
if docker info &> /dev/null; then
    print_status 0 "Docker daemon is running"
else
    print_status 1 "Docker daemon is not running"
    exit 1
fi

# Check if .env file exists
print_header "Configuration Files"
if [ -f "srcs/.env" ]; then
    print_status 0 ".env file exists"
else
    print_status 1 ".env file not found in srcs/"
    exit 1
fi

# Check required directories
print_header "Data Directories"
if [ -d "/home/joker/data/mariadb" ]; then
    print_status 0 "MariaDB data directory exists"
else
    print_status 1 "MariaDB data directory missing (/home/joker/data/mariadb)"
fi

if [ -d "/home/joker/data/wordpress" ]; then
    print_status 0 "WordPress data directory exists"
else
    print_status 1 "WordPress data directory missing (/home/joker/data/wordpress)"
fi

# Check Docker Compose configuration
print_header "Docker Compose Configuration"
cd srcs
if $DOCKER_COMPOSE config &> /dev/null; then
    print_status 0 "docker-compose.yml is valid"
else
    print_status 1 "docker-compose.yml has syntax errors"
    $DOCKER_COMPOSE config
    exit 1
fi
cd ..

# Check if containers are running
print_header "Container Status"
cd srcs

containers=("mariadb" "wordpress" "nginx" "redis" "ftp" "adminer" "static-website" "portainer")
for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        status=$(docker inspect --format='{{.State.Status}}' $container 2>/dev/null)
        if [ "$status" = "running" ]; then
            print_status 0 "$container is running"
        else
            print_status 1 "$container exists but status: $status"
        fi
    else
        print_status 1 "$container is not running"
    fi
done

# Check container health
print_header "Container Health"
for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        health=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null)
        if [ -z "$health" ]; then
            echo -e "${YELLOW}○${NC} $container (no health check configured)"
        elif [ "$health" = "healthy" ]; then
            print_status 0 "$container is healthy"
        else
            print_status 1 "$container health: $health"
        fi
    fi
done

# Check networks
print_header "Network Status"
if docker network ls --format '{{.Name}}' | grep -q "inception"; then
    network_name=$(docker network ls --format '{{.Name}}' | grep "inception")
    print_status 0 "inception network exists ($network_name)"
    network_containers=$(docker network inspect $network_name --format='{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
    echo -e "   Connected containers: ${BLUE}${network_containers}${NC}"
else
    print_status 1 "inception network not found"
fi

# Check volumes
print_header "Volume Status"
volumes=$(docker volume ls --format '{{.Name}}' | grep -E "(mariadb|wordpress|portainer)")
if [ -n "$volumes" ]; then
    while IFS= read -r volume; do
        print_status 0 "$volume exists"
    done <<< "$volumes"
else
    print_status 1 "No volumes found matching pattern"
fi

# Check ports
print_header "Port Binding Check"
if docker ps --format '{{.Ports}}' | grep -q "443"; then
    print_status 0 "Port 443 (HTTPS) is exposed"
else
    print_status 1 "Port 443 (HTTPS) is not exposed"
fi

# Test service connectivity
print_header "Service Connectivity Tests"

# Check NGINX
if docker ps --format '{{.Names}}' | grep -q "^nginx$"; then
    if docker exec nginx nginx -t &> /dev/null; then
        print_status 0 "NGINX configuration is valid"
    else
        print_status 1 "NGINX configuration has errors"
    fi
fi

# Check MariaDB
if docker ps --format '{{.Names}}' | grep -q "^mariadb$"; then
    if docker exec mariadb mysqladmin ping -h localhost --silent 2>/dev/null; then
        print_status 0 "MariaDB is responding"
    else
        print_status 1 "MariaDB is not responding"
    fi
fi

# Check WordPress
if docker ps --format '{{.Names}}' | grep -q "^wordpress$"; then
    if docker exec wordpress php-fpm7.4 -t &> /dev/null; then
        print_status 0 "PHP-FPM configuration is valid"
    else
        print_status 1 "PHP-FPM configuration has errors"
    fi
fi

# Check Redis
if docker ps --format '{{.Names}}' | grep -q "^redis$"; then
    if docker exec redis redis-cli ping &> /dev/null; then
        print_status 0 "Redis is responding"
    else
        print_status 1 "Redis is not responding (may need authentication)"
    fi
fi

# Check domain resolution
print_header "Domain Resolution"
if grep -q "abamksa.42.fr" /etc/hosts; then
    print_status 0 "abamksa.42.fr found in /etc/hosts"
else
    print_status 1 "abamksa.42.fr not found in /etc/hosts"
    echo -e "   ${YELLOW}Add this line to /etc/hosts:${NC} 127.0.0.1 abamksa.42.fr"
fi

# Check SSL certificate
print_header "SSL Certificate Check"
if docker ps --format '{{.Names}}' | grep -q "^nginx$"; then
    if docker exec nginx test -f /etc/ssl/certs/nginx-selfsigned.crt; then
        print_status 0 "SSL certificate exists in NGINX"
    else
        print_status 1 "SSL certificate not found in NGINX"
    fi
fi

# Display URLs
print_header "Access URLs"
echo -e "${GREEN}WordPress:${NC}      https://abamksa.42.fr"
echo -e "${GREEN}WordPress Admin:${NC} https://abamksa.42.fr/wp-admin/"
echo -e "${GREEN}Adminer:${NC}        https://abamksa.42.fr/adminer/ (if configured in NGINX)"
echo -e "${GREEN}Static Site:${NC}    https://abamksa.42.fr/static/ (if configured in NGINX)"

# Container logs preview
print_header "Recent Container Logs (last 5 lines)"
for container in "mariadb" "wordpress" "nginx"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "\n${BLUE}--- $container ---${NC}"
        docker logs --tail 5 $container 2>&1 | sed 's/^/   /'
    fi
done

# Summary
print_header "Summary"
running_count=$(docker ps --format '{{.Names}}' | grep -E "^(mariadb|wordpress|nginx|redis|ftp|adminer|static-website|portainer)$" | wc -l)
total_count=8
echo -e "Containers running: ${GREEN}${running_count}${NC}/${total_count}"

if [ $running_count -eq $total_count ]; then
    echo -e "\n${GREEN}✓ All services are running!${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Visit https://abamksa.42.fr (accept self-signed certificate)"
    echo -e "  2. Check WordPress admin: https://abamksa.42.fr/wp-admin/"
    echo -e "  3. View logs: make logs"
else
    echo -e "\n${RED}✗ Some services are not running${NC}"
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Check logs: $DOCKER_COMPOSE -f srcs/docker-compose.yml logs"
    echo -e "  2. Restart services: make re"
    echo -e "  3. Check specific container: docker logs <container_name>"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
cd ..
