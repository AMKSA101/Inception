# 🐳 Inception Project - WordPress Infrastructure with Docker

A complete containerized WordPress deployment using Docker Compose with NGINX, WordPress (PHP-FPM), and MariaDB.

## 📋 Table of Contents
- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Debugging Journey](#-debugging-journey)
- [Technical Details](#-technical-details)
- [File Structure](#-file-structure)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Project Overview

This project creates a production-ready WordPress website using three custom Docker containers:
- **NGINX**: Reverse proxy with SSL/TLS encryption
- **WordPress**: PHP-FPM with WP-CLI automation
- **MariaDB**: Database server with custom initialization

### Key Features
- ✅ **HTTPS Only**: Self-signed SSL certificates
- ✅ **Persistent Data**: Docker volumes for database and WordPress files
- ✅ **Automated Setup**: WP-CLI for headless WordPress installation
- ✅ **Container Networking**: Internal communication between services
- ✅ **Environment Configuration**: Centralized environment variables

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    INCEPTION ARCHITECTURE                    │
└─────────────────────────────────────────────────────────────┘

    External Access (Port 443)
              │
              ▼
    ┌─────────────────┐
    │      NGINX      │ ◄── SSL Termination
    │   (Debian:11)   │     Self-signed Certificate
    │                 │     Reverse Proxy
    └─────────┬───────┘
              │ FastCGI (Port 9000)
              ▼
    ┌─────────────────┐     ┌─────────────────┐
    │   WordPress     │────▶│     MariaDB     │
    │  (PHP-FPM 7.4)  │     │   (v10.5.29)    │
    │   + WP-CLI       │     │  Custom Init    │
    └─────────────────┘     └─────────────────┘
              │                       │
              ▼                       ▼
    ┌─────────────────┐     ┌─────────────────┐
    │ wordpress-data  │     │  mariadb-data   │
    │    (Volume)     │     │    (Volume)     │
    └─────────────────┘     └─────────────────┘

    ┌─────────────────────────────────────────────────────────┐
    │                 inception-network                       │
    │              (Custom Docker Network)                   │
    └─────────────────────────────────────────────────────────┘
```

### Container Communication
```
User Request → NGINX:443 → WordPress:9000 → MariaDB:3306
            ←           ←                 ←
         HTTPS         FastCGI          MySQL
```

---

## 🚀 Quick Start

### Prerequisites
- Docker Engine
- Docker Compose
- Linux/macOS environment

### Installation
```bash
# Clone or extract the project
cd inception

# Build and start all services
make

# Or manually:
cd srcs
docker-compose up -d --build
```

### Access the Website
```bash
# Via curl (bypass SSL warning)
curl -k https://localhost:443

# Via browser
https://localhost:443
# Accept the self-signed certificate warning
```

### Management Commands
```bash
make status    # Check container status
make logs      # View container logs
make down      # Stop all services
make clean     # Remove stopped containers
make fclean    # Complete cleanup (removes volumes)
make re        # Rebuild everything from scratch
```

---

## 🐛 Debugging Journey

This section documents the **actual debugging process** and all issues encountered during development:

### 🔍 **Phase 1: Initial Assessment**
**Issue**: Project structure existed but wasn't functional
```
❌ Empty Makefile
❌ Missing .env file
❌ Containers building but website not accessible
```

**Solution**: Created basic infrastructure
```bash
# Created Makefile with automation
# Created .env with database credentials
# Initial docker-compose build successful
```

---

### 🔍 **Phase 2: Database Connectivity Issues**
**Issue**: WordPress couldn't connect to MariaDB
```
❌ Error: "mysql-client package not found"
❌ WordPress container failing to start
❌ Database connection timeouts
```

**Root Cause Analysis**:
```bash
# Checked WordPress Dockerfile
RUN apt-get install mysql-client  # ❌ Package doesn't exist in Debian Bullseye

# Checked container logs
docker-compose logs wordpress
# Error: E: Package 'mysql-client' has no installation candidate
```

**Solution**: Fixed package name
```dockerfile
# BEFORE (broken)
RUN apt-get install mysql-client

# AFTER (working)
RUN apt-get install default-mysql-client
```

---

### 🔍 **Phase 3: WP-CLI Download Failures**
**Issue**: WordPress setup script failing
```
❌ WP-CLI download returning 404 errors
❌ WordPress installation not completing
❌ Container startup hanging
```

**Root Cause Analysis**:
```bash
# Original URL in Dockerfile
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-2.8.1.phar
# Result: 404 Not Found

# Checked WP-CLI releases
curl -I https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar
# Result: 200 OK
```

**Solution**: Updated to GitHub releases URL
```dockerfile
# BEFORE (broken)
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-2.8.1.phar

# AFTER (working)
curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar
```

---

### 🔍 **Phase 4: PHP-FPM Configuration Errors**
**Issue**: PHP-FPM failing to start
```
❌ ERROR: [pool www] pm.max_spare_servers(35) must not be greater than pm.max_children(20)
❌ WordPress container exiting immediately
❌ NGINX showing "502 Bad Gateway"
```

**Root Cause Analysis**:
```bash
# Checked PHP-FPM configuration
cat conf/www.conf
pm.max_children = 20
pm.max_spare_servers = 35  # ❌ Invalid: 35 > 20

# Checked container logs
docker-compose logs wordpress
# PHP-FPM validation failed
```

**Solution**: Fixed PHP-FPM pool configuration
```ini
# BEFORE (broken)
pm.max_children = 20
pm.max_spare_servers = 35

# AFTER (working)
pm.max_children = 20
pm.max_spare_servers = 15  # ✅ 15 < 20
```

---

### 🔍 **Phase 5: Volume Mounting Issues**
**Issue**: NGINX showing "File not found" errors
```
❌ NGINX error: "FastCGI sent in stderr: Primary script unknown"
❌ WordPress files not accessible to NGINX
❌ Website returning 404 errors
```

**Root Cause Analysis**:
```bash
# Checked container file structure
docker exec nginx ls -la /var/www/html/
# Empty directory

docker exec wordpress ls -la /var/www/html/
# Empty directory

docker exec wordpress ls -la /var/www/wordpress/
# WordPress files present here
```

**The Problem**: Volume Mounting Mismatch
```yaml
# docker-compose.yml volumes
wordpress:
  volumes:
    - wordpress-data:/var/www/html  # Mounted here

nginx:
  volumes:
    - wordpress-data:/var/www/html  # Expected files here

# But WordPress installed to /var/www/wordpress/ (different location!)
```

**Solution**: Copy WordPress files to shared volume
```bash
# Added to setup-wordpress.sh
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Copying WordPress files to shared volume..."
    cp -r /var/www/wordpress/* /var/www/html/  # ✅ Copy to shared location
    chown -R www-data:www-data /var/www/html/
fi
```

---

### 🔍 **Phase 6: MariaDB Initialization**
**Issue**: Database not properly initialized
```
❌ MariaDB stuck in setup mode
❌ WordPress couldn't create database connection
❌ Inconsistent container restart behavior
```

**Solution**: Enhanced initialization script with proper cleanup
```bash
# Added proper process management
kill $MYSQL_PID
wait $MYSQL_PID
echo "Temporary MariaDB instance stopped"

# Proper transition to normal mode
exec "$@"
```

---

### 🎯 **Final Success Validation**
```bash
# All containers running
docker-compose ps
# ✅ nginx: Up, port 443
# ✅ wordpress: Up, port 9000  
# ✅ mariadb: Up, port 3306

# Website accessible
curl -k https://localhost:443
# ✅ Returns full WordPress HTML page

# Database connectivity confirmed
docker-compose logs wordpress
# ✅ "MariaDB is ready!"
# ✅ "WordPress setup completed!"
```

---

## 🔧 Technical Details

### SSL/TLS Configuration
```bash
# Self-signed certificate generation (in NGINX Dockerfile)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx-selfsigned.key \
    -out /etc/nginx/ssl/nginx-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=abamksa.42.fr"
```

### Environment Variables
| Variable | Purpose | Example |
|----------|---------|---------|
| `DOMAIN_NAME` | WordPress URL & SSL CN | `abamksa.42.fr` |
| `MYSQL_ROOT_PASSWORD` | MariaDB root access | `Joker101` |
| `MYSQL_DATABASE` | WordPress database | `wordpress` |
| `MYSQL_USER` | WordPress DB user | `wp_user` |
| `MYSQL_PASSWORD` | WordPress DB password | `user` |

### Network Architecture
```yaml
networks:
  inception-network:
    driver: bridge
    # Enables container-to-container communication
    # wordpress -> mariadb:3306
    # nginx -> wordpress:9000
```

### Volume Management
```yaml
volumes:
  wordpress-data:
    driver: local
    # Persists: /var/www/html (WordPress files)
    
  mariadb-data:
    driver: local
    # Persists: /var/lib/mysql (Database files)
```

---

## 📁 File Structure

```
inception/
├── Makefile                     # Build automation (CREATED)
├── README.md                    # This documentation (CREATED)
└── srcs/
    ├── docker-compose.yml       # Container orchestration
    ├── .env                     # Environment variables (CREATED)
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile       # NGINX container build
        │   ├── conf/
        │   │   └── nginx.conf   # Reverse proxy config
        │   └── tools/           # SSL certificate scripts
        ├── wordpress/
        │   ├── Dockerfile       # WordPress container (FIXED)
        │   ├── conf/
        │   │   └── www.conf     # PHP-FPM config (FIXED)
        │   └── tools/
        │       └── setup-wordpress.sh  # WP setup script (FIXED)
        └── mariadb/
            ├── Dockerfile       # MariaDB container
            ├── conf/
            │   └── 50-server.cnf # MariaDB config
            └── tools/
                └── init.sh      # Database initialization (ENHANCED)
```

### Key Files Modified
- ✅ **Makefile**: Created from scratch for automation
- ✅ **.env**: Created with database credentials
- ✅ **WordPress Dockerfile**: Fixed package names and WP-CLI URL
- ✅ **www.conf**: Fixed PHP-FPM pool configuration
- ✅ **setup-wordpress.sh**: Added file copying to shared volume
- ✅ **init.sh**: Enhanced database initialization process

---

## 🛠️ Troubleshooting

### Common Issues

#### 1. **Website Not Accessible**
```bash
# Check container status
make status

# Check logs for errors
make logs

# Common causes:
# - NGINX not running (check port 443)
# - SSL certificate issues (use curl -k)
# - WordPress files not copied to shared volume
```

#### 2. **Database Connection Errors**
```bash
# Check MariaDB logs
docker-compose logs mariadb

# Test database connectivity
docker exec wordpress mysqladmin ping -h mariadb -u wp_user -p

# Common causes:
# - Incorrect credentials in .env
# - MariaDB not fully initialized
# - Network connectivity issues
```

#### 3. **PHP-FPM Errors**
```bash
# Check WordPress container logs
docker-compose logs wordpress

# Common causes:
# - Invalid www.conf configuration
# - File permission issues
# - Missing PHP extensions
```

#### 4. **Build Failures**
```bash
# Clean rebuild
make fclean
make

# Check for:
# - Package installation failures
# - Network connectivity issues
# - Dockerfile syntax errors
```

### Debug Commands
```bash
# Enter container shell
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Check file permissions
docker exec wordpress ls -la /var/www/html/

# Test internal connectivity
docker exec wordpress ping mariadb
docker exec nginx ping wordpress

# Monitor real-time logs
docker-compose logs -f nginx
docker-compose logs -f wordpress
docker-compose logs -f mariadb
```

---

## 🎓 Learning Outcomes

This project demonstrates:

1. **Docker Multi-Container Architecture**
   - Custom Dockerfiles for each service
   - Container networking and communication
   - Volume mounting and data persistence

2. **Web Server Configuration**
   - NGINX as reverse proxy
   - SSL/TLS certificate management
   - FastCGI integration with PHP-FPM

3. **Database Management**
   - MariaDB initialization and security
   - User management and permissions
   - Container-based database deployment

4. **WordPress Deployment**
   - Headless WordPress installation with WP-CLI
   - PHP-FPM configuration and optimization
   - File system permissions and sharing

5. **DevOps Practices**
   - Infrastructure as Code (Docker Compose)
   - Environment variable management
   - Build automation with Makefile
   - Systematic debugging and troubleshooting

---

## 📝 Notes

- This project uses **self-signed SSL certificates** for HTTPS
- **MariaDB** is used instead of MySQL for better licensing
- **PHP-FPM** provides better performance than Apache mod_php
- **WP-CLI** enables automated WordPress setup without web interface
- All containers run as **non-root users** for security

---

**Project Status**: ✅ **Fully Functional**  
**Last Updated**: July 25, 2025  
**Tested Environment**: Docker Engine 24.x, Docker Compose 2.x

---

*This documentation was created to help understand the complete development process, including all the challenges faced and solutions implemented. It serves as both a technical reference and a learning resource for containerized web application deployment.*
