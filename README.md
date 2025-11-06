# Inception — Complete Defense Guide

> **Your Ultimate Defense Preparation Document**  
> This README is your comprehensive guide to master and defend the Inception project. It covers every concept, command, test, and question evaluators might ask.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Quick Glossary](#quick-glossary)
3. [Repository Layout](#repository-layout)
4. [Architecture & Services](#architecture--services)
5. [Build, Run, Stop Commands](#build-run-stop-commands)
6. [How Everything Fits Together](#how-everything-fits-together)
7. [Testing Each Service](#testing-each-service)
8. [Debugging Guide](#debugging-guide)
9. [Common Issues & Fixes](#common-issues--fixes)
10. [Defense Questions & Answers](#defense-questions--answers)
11. [Security Notes](#security-notes)
12. [One-Page Cheat Sheet](#one-page-cheat-sheet)
13. [Additional Resources](#additional-resources)

---

## 🎯 Project Overview

**Inception** is a system administration and Docker infrastructure project that creates a complete web application stack using Docker Compose. It demonstrates containerization, service orchestration, networking, and volume management.

### What This Project Does:
- ✅ Deploys **WordPress** with PHP-FPM behind **Nginx** (HTTPS only)
- ✅ Uses **MariaDB** for database persistence
- ✅ Implements **Redis** for caching
- ✅ Includes 5 bonus services: **Adminer**, **Portainer**, **FTP**, **Static Website**, and more
- ✅ All services run in isolated Docker containers with custom-built images
- ✅ Data persists across container restarts using Docker volumes

### Key Learning Goals:
- Master Docker containerization and custom image building
- Understand multi-container orchestration with Docker Compose
- Learn service networking, volume management, and environment configuration
- Practice debugging production-like infrastructure
- Demonstrate security best practices

**This README will make you an expert** ready to answer any evaluator question with confidence.

---

## 📖 Quick Glossary

### Essential Docker Concepts

| Term | Definition | In This Project |
|------|------------|----------------|
| **Docker** | Platform for running applications in isolated containers | Core technology for all services |
| **Docker Image** | Read-only template containing application code and dependencies | We build 8 custom images |
| **Docker Container** | Running instance of an image | 8 containers running simultaneously |
| **Docker Compose** | Tool to orchestrate multi-container applications via YAML | Defined in `srcs/docker-compose.yml` |
| **Docker Volume** | Persistent storage that survives container restarts | Used for database and WordPress files |
| **Docker Network** | Virtual network connecting containers | `inception-network` (bridge mode) |

### Service-Specific Terms

| Service | What It Does | Port | Purpose |
|---------|--------------|------|---------|
| **Nginx** | Web server & reverse proxy | 443 (HTTPS) | Entry point, serves static files, proxies PHP |
| **WordPress** | PHP-based CMS | Internal (9000) | Dynamic content, blog posts, pages |
| **PHP-FPM** | FastCGI Process Manager | Internal (9000) | Executes PHP code for WordPress |
| **MariaDB** | MySQL-compatible database | Internal (3306) | Stores WordPress data |
| **Redis** | In-memory key-value store | Internal (6379) | Caches database queries, sessions |
| **Adminer** | Database management UI | 8081 (via Nginx) | Web interface for database |
| **Portainer** | Docker management UI | 9443 | Monitor and manage containers |
| **FTP** | File transfer protocol server | 21 | Upload files to WordPress |
| **Static Site** | Simple HTML/CSS/JS website | 8080 | Demonstration static content |

---

## 📁 Repository Layout

```
Inception/
├── Makefile                          # Build automation (all, build, up, down, clean, fclean, re)
├── README.md                         # This comprehensive guide
├── CHEAT_SHEET.md                    # Quick reference for common commands
└── srcs/
    ├── .env                          # ⚠️  CRITICAL: Environment variables (DB passwords, domain)
    ├── docker-compose.yml            # Service orchestration definition
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile            # Custom MariaDB image
        │   ├── conf/50-server.cnf    # Database configuration
        │   └── tools/init.sh         # Database initialization script
        ├── nginx/
        │   ├── Dockerfile            # Custom Nginx image with SSL
        │   └── conf/nginx.conf       # Server blocks, upstreams, SSL config
        ├── wordpress/
        │   ├── Dockerfile            # Custom WordPress + PHP-FPM image
        │   ├── conf/www.conf         # PHP-FPM pool configuration
        │   └── tools/setup-wordpress.sh  # WordPress installation & setup
        └── bonus/
            ├── adminer/              # Database web interface
            ├── ftp/                  # FTP server for file uploads
            ├── portainer/            # Docker management UI
            ├── redis/                # Cache server
            └── static-website/       # Simple HTML site

```

### 🔑 Critical Files You Must Know

| File | Purpose | Evaluator Will Ask |
|------|---------|-------------------|
| `srcs/.env` | Contains all passwords, domain name, database credentials | "Show me your environment variables" |
| `srcs/docker-compose.yml` | Defines all 8 services, networks, volumes | "Explain your service dependencies" |
| `Makefile` | Automation for build/start/stop/clean | "How do you start the project?" |
| `requirements/*/Dockerfile` | Custom image build instructions | "Why did you use Alpine/Debian?" |
| `requirements/nginx/conf/nginx.conf` | Web server configuration | "How does HTTPS work? Show me SSL" |

---

## 🏗️ Architecture & Services

### Service Overview Diagram

```
                                   [Internet/Browser]
                                          |
                                    HTTPS (443)
                                          ↓
                        ┌─────────────────────────────────┐
                        │   NGINX (Reverse Proxy/SSL)     │
                        │   - Terminates SSL/TLS          │
                        │   - Serves static files         │
                        │   - Proxies PHP to WordPress    │
                        └────────┬───────────┬────────────┘
                                 │           │
                    PHP Files ───┘           └─── Static Files
                         ↓                            ↓
         ┌───────────────────────────┐    ┌─────────────────────┐
         │   WORDPRESS (PHP-FPM)     │    │  STATIC-WEBSITE     │
         │   - Executes PHP code     │    │  - HTML/CSS/JS      │
         │   - Handles CMS logic     │    └─────────────────────┘
         └───────┬──────────┬────────┘
                 │          │
          DB ────┘          └──── Cache
          ↓                        ↓
  ┌──────────────┐         ┌─────────────┐
  │   MARIADB    │         │    REDIS    │
  │   - MySQL DB │         │   - Cache   │
  │   - Data     │         │   - Sessions│
  └──────────────┘         └─────────────┘

         Supporting Services:
  ┌──────────┐  ┌───────────┐  ┌──────────┐
  │ ADMINER  │  │ PORTAINER │  │   FTP    │
  │ DB Admin │  │ Docker UI │  │ File Xfer│
  └──────────┘  └───────────┘  └──────────┘
```

### Detailed Service Breakdown

#### 1️⃣ **NGINX** (Container: `nginx`)
- **Role**: Entry point for all HTTP/HTTPS traffic
- **Build**: `requirements/nginx`
- **Ports**: 
  - `443` → HTTPS (WordPress)
- **Key Features**:
  - SSL/TLS termination (self-signed certificate)
  - Reverse proxy to WordPress PHP-FPM
  - Serves static files directly (performance)
- **Volumes**: 
  - `wordpress-data:/var/www/html` (shared with WordPress)
  - `static-site-data:/var/www/static-site`
- **Config**: `requirements/nginx/conf/nginx.conf`

#### 2️⃣ **WORDPRESS** (Container: `wordpress`)
- **Role**: PHP application server (CMS)
- **Build**: `requirements/wordpress`
- **Internal Port**: `9000` (PHP-FPM)
- **Depends On**: `mariadb`, `redis`
- **Key Features**:
  - WordPress core installation
  - PHP-FPM 7.4 or 8.x
  - Connects to MariaDB for data
  - Uses Redis for caching (if configured)
- **Volumes**: `wordpress-data:/var/www/html` (persistent uploads, themes, plugins)
- **Setup**: `tools/setup-wordpress.sh` (downloads WP, configures wp-config.php)

#### 3️⃣ **MARIADB** (Container: `mariadb`)
- **Role**: Relational database
- **Build**: `requirements/mariadb`
- **Internal Port**: `3306` (not exposed to host)
- **Key Features**:
  - MySQL-compatible
  - Creates `wordpress` database on startup
  - Persistent storage for posts, users, settings
- **Volumes**: `mariadb-data:/var/lib/mysql` (database files)
- **Config**: `conf/50-server.cnf`, `tools/init.sh`

#### 4️⃣ **REDIS** (Container: `redis`)
- **Role**: In-memory cache
- **Build**: `requirements/bonus/redis`
- **Internal Port**: `6379`
- **Key Features**:
  - Object caching for WordPress
  - Session storage
  - Password-protected
- **Config**: `conf/redis.conf`

#### 5️⃣ **ADMINER** (Container: `adminer`)
- **Role**: Database management UI
- **Build**: `requirements/bonus/adminer`
- **Access**: Via Nginx proxy (HTTP)
- **Key Features**:
  - Web-based SQL interface
  - Connect to MariaDB
  - Run queries, export/import

#### 6️⃣ **PORTAINER** (Container: `portainer`)
- **Role**: Docker management UI
- **Build**: `requirements/bonus/portainer`
- **Access**: Internal (inception-network)
- **Key Features**:
  - Monitor containers
  - View logs
  - Restart services
  - ⚠️ **Security**: Binds Docker socket (root access)

#### 7️⃣ **FTP** (Container: `ftp`)
- **Role**: File transfer server
- **Build**: `requirements/bonus/ftp`
- **Ports**: `21` (command), `21100-21110` (passive data)
- **Key Features**:
  - Upload files to WordPress volume
  - ⚠️ **Warning**: Insecure, learning only
- **Volumes**: `wordpress-data:/var/www/html` (shared)

#### 8️⃣ **STATIC-WEBSITE** (Container: `static-website`)
- **Role**: Simple HTML demonstration
- **Build**: `requirements/bonus/static-website`
- **Access**: Via Nginx
- **Key Features**:
  - HTML/CSS/JavaScript files
  - No backend processing

### 🌐 Network Architecture

**Network**: `inception-network` (Bridge mode)

**Why Bridge?**
- Isolates containers from host network
- Containers can communicate by service name (e.g., `mariadb`, `redis`)
- Only specified ports exposed to host

**Service Communication Examples**:
```bash
# WordPress connects to database:
mysql -h mariadb -u $DB_USER -p$DB_PASSWORD

# WordPress connects to cache:
redis-cli -h redis -p 6379

# Nginx proxies to WordPress:
fastcgi_pass wordpress:9000;
```

### 💾 Volume Strategy

| Volume | Type | Purpose | Path in Container | Persistence |
|--------|------|---------|-------------------|-------------|
| `mariadb-data` | Bind mount | Database files | `/var/lib/mysql` | ✅ Host: `/home/joker/data/mariadb` |
| `wordpress-data` | Bind mount | WP files, uploads | `/var/www/html` | ✅ Host: `/home/joker/data/wordpress` |
| `static-site-data` | Named volume | Static HTML | `/var/www/static-site` | ✅ Docker-managed |
| `adminer-data` | Named volume | Adminer files | `/var/www/adminer` | ✅ Docker-managed |
| `portainer-data` | Named volume | Portainer config | `/data` | ✅ Docker-managed |

**Key Concept**: Volumes persist data even when containers are deleted!

---

## ⚙️ Build, Run, Stop Commands

### Quick Start (First Time Setup)

```bash
# 1. Clone and enter the project
cd /home/joker/Workspace/Inception

# 2. Ensure .env file exists in srcs/
ls srcs/.env  # Should exist with your credentials

# 3. Build and start everything
make

# 4. Check all services are running
make status

# 5. Access your WordPress site
# Open https://abamksa.42.fr (or your domain from .env)
```

### 🔨 Makefile Commands (Main Interface)

| Command | What It Does | When to Use |
|---------|--------------|-------------|
| `make` or `make all` | Build images + start containers | **First time** or after code changes |
| `make build` | Build/rebuild Docker images | After changing Dockerfile or configs |
| `make up` | Start containers (must build first) | Restart after `make down` |
| `make down` | Stop containers (keeps volumes) | Temporary shutdown |
| `make clean` | Stop + remove dangling images | Free up disk space |
| `make fclean` | **Nuclear**: Remove everything | ⚠️ **Data loss!** Complete reset |
| `make re` | Full rebuild (`fclean` + `all`) | Fix corruption, start fresh |
| `make logs` | Stream logs from all containers | **Debugging** |
| `make status` | Show container states | Quick health check |

### 📝 Makefile Internals (What Actually Runs)

```makefile
# make build
cd srcs && docker-compose build

# make up  
cd srcs && docker-compose up -d

# make down
cd srcs && docker-compose down

# make fclean
cd srcs && docker-compose down -v --rmi all
docker system prune -af --volumes
```

### 🐳 Direct Docker Compose Commands

If you prefer manual control:

```bash
cd srcs

# Build all images
docker-compose build

# Build specific service
docker-compose build nginx

# Start all services (detached)
docker-compose up -d

# Start and attach to logs
docker-compose up

# Restart specific service
docker-compose restart wordpress

# Stop everything
docker-compose down

# Stop and remove volumes (⚠️ data loss)
docker-compose down -v

# View service status
docker-compose ps

# Follow logs for all services
docker-compose logs -f

# Follow logs for one service
docker-compose logs -f mariadb

# Execute command in running container
docker-compose exec wordpress bash
```

### 🔍 Essential Docker Commands

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs nginx
docker logs -f wordpress  # Follow mode

# Execute command in container
docker exec -it wordpress bash
docker exec -it mariadb mysql -u root -p

# Inspect container details
docker inspect nginx

# View resource usage
docker stats

# List networks
docker network ls

# Inspect network
docker network inspect inception-network

# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_wordpress-data

# Remove unused resources
docker system prune
docker system prune -a  # Also remove unused images
docker system prune -a --volumes  # ⚠️ Remove everything
```

### 🌐 Access Points After Startup

| Service | URL | Notes |
|---------|-----|-------|
| **WordPress** | `https://abamksa.42.fr` | Main site (HTTPS only) |
| **WordPress Admin** | `https://abamksa.42.fr/wp-admin` | Login with env credentials |
| **Adminer** | Internal (via inception-network) | Database management UI |
| **Portainer** | Internal (via inception-network) | Docker management |
| **Static Site** | Internal (via inception-network) | HTML demo |
| **FTP** | `ftp://abamksa.42.fr:21` | File upload (insecure) |

**Note**: Replace `abamksa.42.fr` with your `$DOMAIN_NAME` from `srcs/.env`

### 🚀 Typical Workflow

```bash
# Morning: Start the stack
make up

# Development: Make changes to Dockerfile/configs
vim srcs/requirements/nginx/conf/nginx.conf

# Rebuild only changed service
cd srcs && docker-compose build nginx
docker-compose up -d nginx

# Check logs while testing
make logs

# Evening: Shut down (keeps data)
make down

# Weekly: Clean up disk space
make clean

# Before defense: Complete fresh start
make re
```

### ⚠️ Important Notes

1. **Always `cd srcs` before using `docker-compose` directly**
2. **`make down` preserves volumes** (data safe)
3. **`make fclean` deletes volumes** (⚠️ data loss!)
4. **`depends_on` doesn't wait for service readiness**, only container start
5. **Check `.env` file** before first run

---

## 🧪 Testing Each Service

### Pre-Test Checklist

```bash
# 1. Verify all containers are running
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# 2. Check logs for errors
make logs | grep -i error

# 3. Verify volumes exist
docker volume ls | grep srcs
```

### 1️⃣ Testing NGINX

#### Basic Health Check
```bash
# Test HTTPS connection
curl -Ik https://abamksa.42.fr

# Expected output:
# HTTP/1.1 200 OK
# Server: nginx/1.18.0
```

#### Advanced Tests
```bash
# Validate Nginx configuration
docker exec nginx nginx -t
# Expected: "syntax is ok" and "test is successful"

# Check which files Nginx is serving
docker exec nginx ls -la /var/www/html

# View Nginx error log
docker exec nginx tail -f /var/log/nginx/error.log

# Test SSL certificate
docker exec nginx openssl x509 -in /etc/ssl/certs/nginx-selfsigned.crt -noout -text

# Reload Nginx without downtime
docker exec nginx nginx -s reload

# Check Nginx process
docker exec nginx ps aux | grep nginx
```

#### What Evaluators Will Ask
- **"Show me your SSL certificate"**: `docker exec nginx ls -lh /etc/ssl/certs/`
- **"Prove Nginx is proxying to WordPress"**: Open `srcs/requirements/nginx/conf/nginx.conf` and show the `fastcgi_pass wordpress:9000;` line
- **"What happens if WordPress is down?"**: Nginx will return 502 Bad Gateway

---

### 2️⃣ Testing WORDPRESS

#### Basic Health Check
```bash
# Test WordPress is responding
curl -L https://abamksa.42.fr

# Check WordPress files exist
docker exec wordpress ls -la /var/www/html

# Expected files:
# wp-config.php, wp-content/, wp-admin/, index.php
```

#### Advanced Tests
```bash
# Enter WordPress container
docker exec -it wordpress bash

# Inside container:
# Check PHP-FPM is running
ps aux | grep php-fpm

# Verify PHP version
php -v

# Test database connection
php -r "var_export((bool)mysqli_connect('mariadb', getenv('DB_USER'), getenv('DB_PASSWORD'), getenv('DB_NAME')));"
# Expected: true

# Check WordPress installation
wp core version --allow-root --path=/var/www/html

# List WordPress users
wp user list --allow-root --path=/var/www/html

# Check file permissions
ls -la /var/www/html/wp-content/uploads
# Should be owned by www-data or writable
```

#### WordPress Admin Test
```bash
# Login to admin panel
# URL: https://abamksa.42.fr/wp-admin
# Username: From $WP_ADMIN_USER in .env
# Password: From $WP_ADMIN_PASSWORD in .env

# Create a test post
# Go to Posts > Add New
# Publish it
# Verify it appears on the homepage
```

#### What Evaluators Will Ask
- **"Where are WordPress files?"**: `/var/www/html` (show with `docker exec wordpress pwd`)
- **"What PHP version?"**: `docker exec wordpress php -v`
- **"Show me wp-config.php"**: `docker exec wordpress cat /var/www/html/wp-config.php | grep DB_`

---

### 3️⃣ Testing MARIADB

#### Basic Health Check
```bash
# Test database is responding
docker exec mariadb mysqladmin ping -u root -p$MYSQL_ROOT_PASSWORD

# Expected output: "mysqld is alive"
```

#### Advanced Tests
```bash
# Enter MariaDB container
docker exec -it mariadb bash

# Connect to MySQL
mysql -u root -p$MYSQL_ROOT_PASSWORD

# Inside MySQL:
SHOW DATABASES;
# Expected: wordpress database exists

USE wordpress;
SHOW TABLES;
# Expected: wp_posts, wp_users, wp_options, etc.

SELECT COUNT(*) FROM wp_posts;
SELECT user_login, user_email FROM wp_users;

# Check database size
SELECT 
  table_schema AS 'Database',
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'wordpress'
GROUP BY table_schema;
```

#### Backup & Restore Test
```bash
# Export database
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD wordpress > backup.sql

# Verify backup file
ls -lh backup.sql

# Restore database (if needed)
docker exec -i mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress < backup.sql
```

#### What Evaluators Will Ask
- **"Show me the database"**: `docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"`
- **"How do you backup data?"**: Show mysqldump command above
- **"Where is data stored?"**: `/var/lib/mysql` in container, `/home/joker/data/mariadb` on host

---

### 4️⃣ Testing REDIS

#### Basic Health Check
```bash
# Test Redis is responding (with password)
docker exec redis redis-cli -a $REDIS_PASSWORD ping

# Expected output: PONG
```

#### Advanced Tests
```bash
# Enter Redis container
docker exec -it redis sh

# Test Redis commands
redis-cli -a $REDIS_PASSWORD

# Inside redis-cli:
PING
# Expected: PONG

# Set and get a key
SET testkey "Hello Redis"
GET testkey
# Expected: "Hello Redis"

# Check Redis info
INFO server
INFO stats

# List all keys
KEYS *

# Monitor Redis commands in real-time
MONITOR
# (Press Ctrl+C to stop)

# Check memory usage
INFO memory
```

#### WordPress Redis Integration Test
```bash
# If WordPress has Redis object cache plugin:
# Check wp-content/object-cache.php exists
docker exec wordpress ls -la /var/www/html/wp-content/object-cache.php

# Flush Redis cache
docker exec redis redis-cli -a $REDIS_PASSWORD FLUSHALL

# Check cache is being populated
docker exec redis redis-cli -a $REDIS_PASSWORD DBSIZE
# Visit WordPress site
# Check DBSIZE again - should increase
```

#### What Evaluators Will Ask
- **"What does Redis do?"**: Caches database queries and sessions for faster performance
- **"Test Redis works"**: Show `PING` and `SET/GET` commands above
- **"Is it password protected?"**: Yes, show `redis.conf` with `requirepass`

---

### 5️⃣ Testing ADMINER

#### Basic Health Check
```bash
# Test Adminer responds via Nginx (internal)
# Access through Nginx proxy within the network
docker exec nginx curl -I http://adminer:9000 || echo "Not exposed externally"
```

#### Manual Test
```bash
# Note: Adminer is accessible only within the inception-network
# To test, you can temporarily expose it or use another container

# Login details:
# System: MySQL
# Server: mariadb
# Username: From $DB_USER in .env
# Password: From $DB_PASSWORD in .env
# Database: wordpress

# Test SQL query:
SELECT * FROM wp_users LIMIT 5;
```

#### What Evaluators Will Ask
- **"What is Adminer?"**: Lightweight web-based database management tool (like phpMyAdmin)
- **"How do you access it?"**: Via Nginx proxy (internal network only)

---

### 6️⃣ Testing PORTAINER

#### Basic Health Check
```bash
# Check Portainer is running
docker ps | grep portainer

# Portainer is accessible only within the inception-network
```

#### Manual Test
```bash
# Access Portainer through the internal network
# Create admin account on first visit
# View containers list (should match `docker ps`)
# Check volumes
# View logs for any container
```

#### What Evaluators Will Ask
- **"What is Portainer?"**: Web UI for managing Docker containers, images, networks, volumes
- **"Security risk?"**: Yes - binds Docker socket (root access). Never expose publicly!

---

### 7️⃣ Testing FTP

#### Basic Health Check
```bash
# Test FTP server is listening
docker exec ftp netstat -tuln | grep :21
# Or check from host:
nc -zv localhost 21
```

#### Advanced Tests
```bash
# Install FTP client (if needed)
sudo apt-get install -y ftp lftp

# Connect via FTP
ftp localhost 21
# Or use lftp:
lftp -u $FTP_USER,$FTP_PASSWORD localhost

# Inside FTP:
ls
# Upload a test file
put localfile.txt
ls
# Verify file appears

# Check file appears in WordPress volume
docker exec wordpress ls -la /var/www/html/
```

#### Security Warning
```bash
# ⚠️ FTP transmits passwords in plaintext
# Never use in production
# Included only for educational purposes
```

#### What Evaluators Will Ask
- **"Why is FTP insecure?"**: Transmits credentials and data unencrypted
- **"What's the alternative?"**: SFTP (SSH File Transfer Protocol) or FTPS (FTP over SSL/TLS)

---

### 8️⃣ Testing STATIC-WEBSITE

#### Basic Health Check
```bash
# Test static site responds via Nginx (internal)
docker exec nginx curl -I http://static-website:80 || echo "Check volume mount"

# Check static files exist
docker exec static-website ls -la /var/www/static-site/
```

#### Manual Test
```bash
# Access through Nginx
# Should display HTML/CSS/JS content

# Edit a file to test live reload
docker exec static-website sh -c 'echo "TEST" >> /var/www/static-site/index.html'

# Refresh and verify change appears
```

---

### 🔄 Volume Persistence Test (Critical for Defense)

```bash
# 1. Create test data
docker exec wordpress bash -c 'echo "PERSISTENCE TEST" > /var/www/html/persist.txt'
docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS testdb;"

# 2. Stop all containers
make down

# 3. Start containers again
make up

# 4. Verify data survived
docker exec wordpress cat /var/www/html/persist.txt
# Expected: "PERSISTENCE TEST"

docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;" | grep testdb
# Expected: testdb exists

# ✅ This proves volumes work correctly!
```

---

### 🌐 Network Communication Test

```bash
# Test containers can reach each other by name
docker exec wordpress ping -c 2 mariadb
docker exec wordpress ping -c 2 redis
docker exec nginx ping -c 2 wordpress

# Test DNS resolution
docker exec wordpress nslookup mariadb

# Check network connectivity
docker network inspect inception-network

# Show container IPs
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q)
```

---

### 📊 Performance Test

```bash
# Apache Bench (if installed)
ab -n 100 -c 10 https://abamksa.42.fr/

# OR use curl for simple test
time curl -k https://abamksa.42.fr/ > /dev/null

# Check resource usage
docker stats --no-stream

# Monitor logs during load
make logs
```

---

### ✅ Complete Health Check Script

Create this as `srcs/tools/healthcheck.sh`:

```bash
#!/bin/bash
set -e

echo "🔍 INCEPTION HEALTH CHECK"
echo "=========================="

# Load environment variables
source srcs/.env

echo "✓ Checking containers..."
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E "nginx|wordpress|mariadb|redis"

echo ""
echo "✓ Testing Nginx HTTPS..."
curl -Ik https://$DOMAIN_NAME 2>&1 | head -2

echo ""
echo "✓ Testing MariaDB..."
docker exec mariadb mysqladmin ping -u root -p$MYSQL_ROOT_PASSWORD 2>&1 | grep "alive"

echo ""
echo "✓ Testing Redis..."
docker exec redis redis-cli -a $REDIS_PASSWORD ping 2>/dev/null

echo ""
echo "✓ Testing WordPress files..."
docker exec wordpress test -f /var/www/html/wp-config.php && echo "wp-config.php exists"

echo ""
echo "✓ Testing volumes..."
docker volume ls | grep -E "mariadb|wordpress"

echo ""
echo "✓ Testing network..."
docker network inspect inception-network &>/dev/null && echo "inception-network exists"

echo ""
echo "=========================="
echo "✅ ALL CHECKS PASSED!"
```

Run it:
```bash
chmod +x srcs/tools/healthcheck.sh
./srcs/tools/healthcheck.sh
```

---

## 🔧 How the Pieces Fit Together

### Request Flow (Browser → WordPress → Database)

```
1. User browser  →  https://abamksa.42.fr
                     ↓
2. Nginx (SSL termination, :443)
   - Receives HTTPS request
   - Terminates SSL/TLS
   - Checks if request is for static file or PHP
                     ↓
3a. Static files: Nginx serves directly from /var/www/html
                     ↓
3b. PHP request: Nginx forwards to PHP-FPM
   fastcgi_pass wordpress:9000;
                     ↓
4. WordPress container (PHP-FPM)
   - Executes PHP code (wp-login.php, wp-admin/*, etc.)
   - Needs data? → Connects to MariaDB
                     ↓
5. MariaDB container
   - Receives SQL query (SELECT * FROM wp_posts)
   - Returns data to WordPress
   - WordPress checks Redis for cached results
                     ↓
6. Redis container (optional)
   - Returns cached objects (faster than DB queries)
   - WordPress uses this to speed up repeated queries
                     ↓
7. WordPress generates HTML
   - Sends response back to Nginx
   - Nginx sends response to user browser
```

### Key Configuration Files

| Service | Config File | Purpose | Critical Settings |
|---------|-------------|---------|-------------------|
| **Nginx** | `requirements/nginx/conf/nginx.conf` | Server blocks, SSL, upstreams | `fastcgi_pass wordpress:9000;` |
| **WordPress** | Generated `wp-config.php` | Database connection | `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` |
| **PHP-FPM** | `requirements/wordpress/conf/www.conf` | PHP process pool | `listen = 9000`, user/group settings |
| **MariaDB** | `requirements/mariadb/conf/50-server.cnf` | Database server | `bind-address`, `port` |
| **Redis** | `requirements/bonus/redis/conf/redis.conf` | Cache server | `requirepass`, `maxmemory-policy` |

### Environment Variables Flow

```
.env file (srcs/.env)
    ↓
docker-compose.yml (env_file: .env)
    ↓
Container environment variables
    ↓
Application configs (wp-config.php, init.sh, etc.)
```

### Critical Environment Variables

```bash
# Domain
DOMAIN_NAME=abamksa.42.fr

# Database credentials
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword

# WordPress admin
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_TITLE=My WordPress Site
WP_URL=https://abamksa.42.fr

# Database connection (for WordPress)
DB_NAME=wordpress
DB_USER=wpuser
DB_PASSWORD=wppassword
DB_HOST=mariadb

# Redis
REDIS_PASSWORD=redis_secure_password

# FTP (optional)
FTP_USER=ftpuser
FTP_PASSWORD=ftppassword
```

### Service Dependencies

```yaml
# docker-compose.yml dependency tree
nginx:
  depends_on:
    - wordpress
    - adminer

wordpress:
  depends_on:
    - mariadb
    - redis

adminer:
  depends_on:
    - mariadb

ftp:
  depends_on:
    - wordpress

static-website:
  depends_on:
    - nginx
    - wordpress
```

**Important**: `depends_on` only ensures container **start order**, NOT service readiness!

### Container Communication

```bash
# Containers use service names as hostnames
# Example from WordPress container:

# Connect to database
mysql -h mariadb -u $DB_USER -p$DB_PASSWORD $DB_NAME

# Connect to cache
redis-cli -h redis -p 6379 -a $REDIS_PASSWORD

# From Nginx to WordPress
# nginx.conf: fastcgi_pass wordpress:9000;
```

### Port Mapping Explained

```
Host Machine                Container
=================================
443         →               443   (Nginx HTTPS)
            internal        9000  (WordPress PHP-FPM)
            internal        3306  (MariaDB)
            internal        6379  (Redis)
21          →               21    (FTP)
21100-21110 →         21100-21110 (FTP passive)
```

**Security**: Only essential ports exposed to host. Database and Redis stay internal.

---

## 🐛 Debugging & Troubleshooting Guide

### 🔍 Systematic Debugging Approach

Follow this step-by-step process when something breaks:

#### Step 1: Verify Docker is Running

```bash
# Check Docker daemon
sudo systemctl status docker
docker info

# Check Docker Compose version
docker-compose --version
# OR (Docker Compose V2)
docker compose version
```

**If Docker isn't running**: `sudo systemctl start docker`

---

#### Step 2: Check Container Status

```bash
# Quick status
make status

# Detailed status
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Expected: All 8 containers with "Up" status
# If any say "Exited" or "Restarting", that's your culprit
```

---

#### Step 3: Read Container Logs

```bash
# All services
make logs

# Specific service (when you know which is failing)
docker logs nginx
docker logs -f wordpress      # Follow mode (live updates)
docker logs --tail 50 mariadb # Last 50 lines

# Look for keywords:
# - ERROR
# - FATAL
# - Connection refused
# - Permission denied
# - Failed to
```

---

#### Step 4: Enter Container for Investigation

```bash
# Get shell access
docker exec -it wordpress bash
# OR if bash not available:
docker exec -it redis sh

# Inside container, check:

# 1. Processes running
ps aux

# 2. Network connectivity
ping mariadb
ping redis

# 3. File permissions
ls -la /var/www/html

# 4. Config files
cat /var/www/html/wp-config.php

# 5. Ports listening
netstat -tuln
# OR
ss -tuln
```

---

#### Step 5: Test Service-Specific Issues

##### 🔴 Problem: Nginx returns 502 Bad Gateway

**Meaning**: Nginx can't reach the backend (WordPress)

```bash
# 1. Check Nginx config syntax
docker exec nginx nginx -t

# 2. Check WordPress is running
docker ps | grep wordpress

# 3. Check PHP-FPM is listening
docker exec wordpress netstat -tuln | grep 9000

# 4. Check Nginx upstream config
docker exec nginx cat /etc/nginx/nginx.conf | grep fastcgi_pass
# Should show: fastcgi_pass wordpress:9000;

# 5. Check WordPress logs
docker logs wordpress | tail -20

# 6. Restart WordPress
docker restart wordpress

# 7. Test from Nginx container
docker exec nginx curl -v http://wordpress:9000
```

---

##### 🔴 Problem: "Error establishing database connection"

**Meaning**: WordPress can't connect to MariaDB

```bash
# 1. Check MariaDB is running
docker ps | grep mariadb

# 2. Check MariaDB logs
docker logs mariadb | tail -30

# 3. Verify .env credentials match
cat srcs/.env | grep -E "DB_|MYSQL_"

# 4. Test connection from WordPress container
docker exec wordpress mysql -h mariadb -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "SHOW TABLES;"

# 5. Check MariaDB is accepting connections
docker exec mariadb mysqladmin ping -u root -p$MYSQL_ROOT_PASSWORD

# 6. Verify database exists
docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"

# 7. Check network connectivity
docker exec wordpress ping -c 3 mariadb
```

---

##### 🔴 Problem: 403 Forbidden / Permission Denied

**Meaning**: Web server can't read files

```bash
# 1. Check file ownership
docker exec wordpress ls -la /var/www/html

# Expected owner: www-data (user ID 33 or 82)

# 2. Fix permissions
docker exec wordpress chown -R www-data:www-data /var/www/html

# 3. Fix directory permissions
docker exec wordpress find /var/www/html -type d -exec chmod 755 {} \;

# 4. Fix file permissions
docker exec wordpress find /var/www/html -type f -exec chmod 644 {} \;

# 5. Check volume mount
docker inspect wordpress | grep -A 10 Mounts
```

---

##### 🔴 Problem: Port Already in Use

**Error**: `bind: address already in use`

```bash
# 1. Find what's using the port
sudo ss -ltnp | grep -E ":443|:21|:8080|:8081|:9443"

# 2. Kill the process (example for port 443)
sudo lsof -ti:443 | xargs sudo kill -9

# 3. OR change port in docker-compose.yml
# From: "443:443"
# To:   "8443:443"

# 4. Restart containers
make down && make up
```

---

##### 🔴 Problem: Redis Connection Failed

```bash
# 1. Check Redis is running
docker ps | grep redis

# 2. Test Redis
docker exec redis redis-cli -a $REDIS_PASSWORD ping

# 3. Check Redis logs
docker logs redis

# 4. Verify Redis password in .env
cat srcs/.env | grep REDIS_PASSWORD

# 5. Check Redis config
docker exec redis cat /etc/redis/redis.conf | grep requirepass
```

---

##### 🔴 Problem: SSL Certificate Errors

```bash
# 1. Check certificate exists
docker exec nginx ls -lh /etc/ssl/certs/nginx-selfsigned.crt

# 2. Verify certificate details
docker exec nginx openssl x509 -in /etc/ssl/certs/nginx-selfsigned.crt -noout -text

# 3. Check Nginx SSL config
docker exec nginx cat /etc/nginx/nginx.conf | grep -A 5 "ssl_certificate"

# 4. For browsers: Accept self-signed certificate (expected for development)

# 5. For curl: Use -k flag
curl -k https://abamksa.42.fr
```

---

#### Step 6: Check Docker Resources

```bash
# Check disk space
df -h

# Check Docker disk usage
docker system df

# Check running container resources
docker stats --no-stream

# Check Docker logs
sudo journalctl -u docker --no-pager | tail -50
```

---

#### Step 7: Network Debugging

```bash
# Inspect network
docker network inspect inception-network

# Check DNS resolution
docker exec wordpress nslookup mariadb

# Check container can reach internet
docker exec wordpress ping -c 2 8.8.8.8

# Check container IP addresses
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q)

# Test connectivity between containers
docker exec wordpress curl -v http://redis:6379
```

---

#### Step 8: Volume Issues

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_wordpress-data

# Check volume contents from host
ls -la /home/joker/data/wordpress
ls -la /home/joker/data/mariadb

# Check volume mount in container
docker inspect wordpress | grep -A 10 Mounts

# Remove orphaned volumes (⚠️ data loss)
docker volume prune
```

---

#### Step 9: Build Issues

```bash
# Clear build cache
docker builder prune -a

# Rebuild without cache
cd srcs && docker-compose build --no-cache

# Build specific service
cd srcs && docker-compose build --no-cache nginx

# Check Dockerfile syntax
docker build -t test-build srcs/requirements/nginx/
```

---

#### Step 10: Nuclear Option (Last Resort)

```bash
# ⚠️ WARNING: This deletes ALL data

# 1. Stop everything
make down

# 2. Remove all containers
docker rm -f $(docker ps -aq)

# 3. Remove all images
docker rmi -f $(docker images -q)

# 4. Remove all volumes (⚠️ DATA LOSS)
docker volume rm $(docker volume ls -q)

# 5. Remove all networks
docker network prune -f

# 6. Clean system
docker system prune -a --volumes -f

# 7. Rebuild from scratch
make re
```

---

### 🛠️ Common Error Messages Decoded

| Error Message | Meaning | Fix |
|---------------|---------|-----|
| `Connection refused` | Service not listening on expected port | Check service is running, verify port config |
| `No such file or directory` | Missing file or incorrect path | Check Dockerfile COPY commands, volume mounts |
| `Permission denied` | Insufficient file permissions | Fix with `chown` and `chmod` |
| `Address already in use` | Port conflict | Change port or stop conflicting service |
| `Cannot connect to Docker daemon` | Docker not running | `sudo systemctl start docker` |
| `Network not found` | Docker network missing | `docker network create inception-network` |
| `Volume not found` | Docker volume missing | Recreate with `docker volume create` |
| `Image not found` | Need to build images first | Run `make build` |
| `Exit code 137` | Container killed (OOM) | Increase Docker memory limit |
| `Exit code 1` | Application error | Check container logs for details |

---

### 📋 Debug Checklist for Defense

Print this and check off during evaluation:

```
☐ All 8 containers running (`docker ps`)
☐ No errors in logs (`make logs | grep -i error`)
☐ Nginx responding on HTTPS (`curl -Ik https://domain`)
☐ WordPress accessible (open in browser)
☐ Database connection working (create/view posts)
☐ Volumes persist after restart (`make down && make up`)
☐ Redis responding (`docker exec redis redis-cli -a $PASS ping`)
☐ SSL certificate present (`docker exec nginx ls /etc/ssl/certs/`)
☐ All services can communicate (test with `ping` between containers)
☐ .env file has all required variables
```

---

## Common issues & quick fixes

- "502 Bad Gateway" from Nginx
  - Check that the PHP process in the `wordpress` container is listening on the socket/port Nginx expects.
  - Run `nginx -t` inside `nginx` container and check upstream targets.

- "Error establishing a database connection"
  - Ensure credentials in `.env` match MariaDB.
  - Confirm MariaDB started, check `docker logs mariadb`.

- Files appear missing or uploads failing
  - Check volume mount `wordpress-data:/var/www/html` and host filesystem ownership.

- SSL issues
  - If certificates are self-signed for development, browsers will warn. For tests, use the browser's advanced options or use curl with `-k` to ignore cert verification.

- Port conflicts
  - If `443`, `8080`, `8081`, or `9443` are already in use locally, stop the local service or change mapping in `srcs/docker-compose.yml`.

---

## 🔒 Security Notes

### ⚠️ Known Vulnerabilities (By Design)

This is a **learning project**. Several security choices are acceptable for evaluation but NEVER for production:

| Issue | Risk | Production Fix |
|-------|------|----------------|
| **FTP Protocol** | Plaintext passwords | Use SFTP or FTPS |
| **Self-signed SSL** | Browser warnings, MITM attacks | Use Let's Encrypt (free CA) |
| **Portainer Socket Binding** | Root access to host Docker | Use Docker-in-Docker or rootless mode |
| **`.env` file** | Secrets in plain text | Use Docker secrets or vault |
| **Adminer Publicly Exposed** | Unauthorized DB access | Require authentication, use VPN |
| **No rate limiting** | Brute force attacks | Implement fail2ban, nginx rate limits |
| **Root in containers** | Privilege escalation | Run as non-root user |

---

### ✅ Security Measures Implemented

1. **HTTPS Only**: TLSv1.2/1.3 enforced
2. **Isolated Network**: Services communicate internally only
3. **Database Not Exposed**: MariaDB port 3306 not bound to host
4. **Redis Password Protection**: Requires authentication
5. **Minimal Base Images**: Alpine Linux where possible (smaller attack surface)
6. **Environment Variables**: Credentials not hardcoded in Dockerfiles

---

### 🛡️ Production Hardening Checklist

If deploying to production, implement:

```bash
# 1. Use Let's Encrypt for SSL
certbot --nginx -d yourdomain.com

# 2. Enable firewall
ufw enable
ufw allow 443/tcp
ufw allow 22/tcp

# 3. Use Docker secrets instead of .env
docker secret create db_password ./db_pass.txt

# 4. Run containers as non-root
USER www-data in Dockerfile

# 5. Enable Docker security features
docker run --security-opt=no-new-privileges \
           --cap-drop=ALL \
           --read-only

# 6. Regular updates
apt update && apt upgrade
docker images --format "{{.Repository}}:{{.Tag}}" | xargs -L1 docker pull

# 7. Monitoring and logging
# Install: Prometheus, Grafana, ELK stack

# 8. Backup automation
# Cron job for daily database backups

# 9. Remove FTP completely
# Use SFTP with key-based authentication

# 10. Scan for vulnerabilities
docker scan yourimage:tag
```

---

## 📄 One-Page Cheat Sheet

### Quick Reference Card (Print This!)

```
┌─────────────────────────────────────────────────────────┐
│         INCEPTION PROJECT - DEFENSE CHEAT SHEET         │
└─────────────────────────────────────────────────────────┘

🚀 START PROJECT
  make                          # Build + start
  make status                   # Check containers
  docker ps                     # Verify running

🔍 DEBUGGING
  make logs                     # All logs
  docker logs -f <service>      # Single service
  docker exec -it <name> bash   # Enter container
  docker exec nginx nginx -t    # Test Nginx config

🧪 TESTING
  curl -Ik https://domain       # Test HTTPS
  docker exec mariadb mysqladmin ping -u root -p$PASS
  docker exec redis redis-cli -a $PASS ping
  docker exec wordpress ls /var/www/html

💾 VOLUMES
  docker volume ls              # List volumes
  ls /home/joker/data/          # Host bind mounts
  # Prove persistence:
  docker exec wordpress touch /var/www/html/test.txt
  make down && make up
  docker exec wordpress ls /var/www/html/test.txt

🌐 NETWORKING
  docker network inspect inception-network
  docker exec wordpress ping mariadb
  docker exec wordpress nslookup redis

🗄️ DATABASE
  docker exec mariadb mysql -u root -p
  SHOW DATABASES;
  USE wordpress; SHOW TABLES;
  # Backup:
  docker exec mariadb mysqldump -u root -p$PASS wordpress > backup.sql

🔄 RESTART/REBUILD
  make down                     # Stop (keep data)
  make fclean                   # ⚠️ DELETE ALL
  make re                       # Clean + rebuild

📦 SERVICES (8 total)
  nginx       → HTTPS entry point (443)
  wordpress   → PHP-FPM application
  mariadb     → MySQL database
  redis       → Cache server
  adminer     → DB web UI
  portainer   → Docker management
  ftp         → File upload (insecure!)
  static      → HTML demo

🔑 KEY CONCEPTS
  • Image = Blueprint, Container = Running instance
  • Volume = Persistent storage
  • Network = Container communication
  • depends_on = Startup order (NOT readiness!)

⚠️ SECURITY ISSUES (Expected for learning)
  • FTP plaintext (use SFTP in production)
  • Self-signed SSL (use Let's Encrypt)
  • Portainer socket binding (root access risk)

❓ MOST COMMON QUESTIONS
  Q: Start project?    A: make
  Q: Show logs?        A: make logs
  Q: Test database?    A: docker exec mariadb mysqladmin ping
  Q: Prove volumes?    A: Create file, restart, verify exists
  Q: 502 error?        A: Check wordpress running + nginx config
  Q: SSL cert?         A: docker exec nginx ls /etc/ssl/certs/

💡 PRO TIPS
  • Run commands to SHOW, don't just explain
  • Know your .env file contents
  • Practice breaking + fixing
  • Explain WHY, not just HOW
  • Keep README open during defense

┌─────────────────────────────────────────────────────────┐
│  Good luck with your defense! You've got this! 🚀       │
└─────────────────────────────────────────────────────────┘
```

---

## 🎓 Defense Questions & Answers

### 📌 Docker Fundamentals

#### Q1: What is Docker?
**Answer**: Docker is a containerization platform that packages applications and their dependencies into isolated containers. Unlike virtual machines, containers share the host OS kernel, making them lightweight and fast to start.

**Key points**:
- Containers vs VMs: Containers are lighter (no full OS), VMs include guest OS
- Uses Linux namespaces and cgroups for isolation
- Enables "build once, run anywhere" philosophy

---

#### Q2: What's the difference between an image and a container?
**Answer**:
- **Image**: Read-only template containing application code, dependencies, and configuration. Like a blueprint.
- **Container**: Running instance of an image. Like a house built from a blueprint.

**Example**:
```bash
# Image (stored)
docker images | grep nginx

# Container (running instance of that image)
docker ps | grep nginx

# One image can create many containers
docker run -d nginx  # Container 1
docker run -d nginx  # Container 2
```

---

#### Q3: What is Docker Compose? Why use it?
**Answer**: Docker Compose is a tool for defining and running multi-container applications using a YAML file.

**Benefits**:
- Single command to start entire stack (`docker-compose up`)
- Defines services, networks, and volumes in one place
- Manages service dependencies
- Easy to share and reproduce environments

**In this project**: `srcs/docker-compose.yml` defines 8 services with their relationships

---

#### Q4: What are Docker volumes? Why do we need them?
**Answer**: Volumes are persistent storage mechanisms that survive container deletion.

**Without volumes**: Data deleted when container is removed
**With volumes**: Data persists on host filesystem

**Types in this project**:
```bash
# Bind mount (explicit host path)
volumes:
  - /home/joker/data/wordpress:/var/www/html

# Named volume (Docker-managed)
volumes:
  - portainer-data:/data
```

**Demonstration**:
```bash
# Prove persistence
docker exec wordpress bash -c 'echo TEST > /var/www/html/test.txt'
make down
make up
docker exec wordpress cat /var/www/html/test.txt  # Still exists!
```

---

#### Q5: What are Docker networks? Why use them?
**Answer**: Docker networks provide isolated communication between containers.

**In this project**: `inception-network` (bridge mode)

**Benefits**:
- Containers talk using service names (not IPs)
- Isolation from host network
- Security: unexposed services stay internal

**Example**:
```bash
# WordPress connects to database by NAME, not IP
mysql -h mariadb -u $DB_USER -p$DB_PASSWORD

# Network DNS resolves "mariadb" to container IP
```

---

### 🏗️ Project-Specific Questions

#### Q6: How do you start this project?
**Answer**:
```bash
# Method 1: Using Makefile (recommended)
make

# Method 2: Docker Compose directly
cd srcs && docker-compose up -d --build

# Verify running
docker ps
```

---

#### Q7: Explain the architecture of your project.
**Answer**: 

"We have 8 containers orchestrated with Docker Compose:

1. **Nginx**: Entry point (HTTPS), reverse proxy to WordPress
2. **WordPress**: PHP-FPM application server
3. **MariaDB**: Database for WordPress data
4. **Redis**: Caching layer for performance
5. **Adminer**: Web UI for database management
6. **Portainer**: Docker management UI
7. **FTP**: File upload server
8. **Static-website**: HTML demonstration

**Data flow**: Browser → Nginx (SSL) → WordPress (PHP) → MariaDB (data) + Redis (cache)

All communicate via `inception-network` bridge network. Critical data stored in volumes."

**Show diagram**: Point to architecture diagram in README

---

#### Q8: How does NGINX know where to forward requests?
**Answer**: Nginx configuration defines upstream servers.

```bash
# Show config
docker exec nginx cat /etc/nginx/nginx.conf | grep -A 5 upstream

# Example from config:
upstream php-backend {
    server wordpress:9000;
}

# In server block:
location ~ \.php$ {
    fastcgi_pass php-backend;
    # OR directly:
    fastcgi_pass wordpress:9000;
}
```

**Key point**: Uses Docker DNS to resolve `wordpress` to container IP

---

#### Q9: Why HTTPS instead of HTTP? Show me SSL configuration.
**Answer**: Project requirements mandate TLSv1.2 or TLSv1.3 only.

```bash
# Show certificate
docker exec nginx ls -lh /etc/ssl/certs/nginx-selfsigned.crt
docker exec nginx ls -lh /etc/ssl/private/nginx-selfsigned.key

# Show Nginx SSL config
docker exec nginx grep -A 10 "ssl_certificate" /etc/nginx/nginx.conf

# Expected output:
# ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
# ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
# ssl_protocols TLSv1.2 TLSv1.3;
```

---

#### Q10: Where are WordPress files located?
**Answer**:
```bash
# Inside container
docker exec wordpress pwd
# Output: /var/www/wordpress (working directory)

# Actual WordPress installation
docker exec wordpress ls -la /var/www/html
# Output: wp-config.php, wp-content/, wp-admin/, index.php, etc.

# On host (bind mount)
ls -la /home/joker/data/wordpress
```

---

#### Q11: How do you prove data persists after container deletion?
**Answer**:
```bash
# Test procedure:
# 1. Create test data
docker exec wordpress bash -c 'echo "PERSISTENCE" > /var/www/html/test.txt'

# 2. Stop and REMOVE containers (not just stop)
make down
docker rm -f wordpress  # Force remove

# 3. Recreate container
make up

# 4. Verify data survived
docker exec wordpress cat /var/www/html/test.txt
# Output: PERSISTENCE

# This works because /var/www/html is mounted to a volume!
```

---

#### Q12: What is the purpose of each Dockerfile?
**Answer**:

**Good answer**: Each service has a custom Dockerfile to:
- Install required packages
- Copy configuration files
- Set up environment
- Define entrypoint/startup command

**Example for Nginx**:
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache nginx openssl
COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=SA/ST=Riyadh/L=Riyadh/O=42/CN=abamksa.42.fr"
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
```

---

#### Q13: Why use Alpine or Debian as base images?
**Answer**:

**Alpine**:
- ✅ Tiny size (~5MB)
- ✅ Minimal attack surface
- ❌ Uses musl libc (compatibility issues with some software)

**Debian**:
- ✅ Widely compatible
- ✅ Large package repository
- ❌ Larger size (~100MB)

**In this project**: Choose based on service needs. Nginx/Redis can use Alpine (simple). WordPress might need Debian (more PHP extensions).

---

#### Q14: What does `depends_on` do in docker-compose.yml?
**Answer**: `depends_on` controls container startup ORDER, not readiness.

```yaml
wordpress:
  depends_on:
    - mariadb
    - redis
```

**What it does**: Start mariadb and redis BEFORE wordpress
**What it DOESN'T do**: Wait for mariadb to be ready to accept connections

**Solution**: Use health checks or init scripts that wait for services

**Example wait script**:
```bash
# In WordPress entrypoint
while ! nc -z mariadb 3306; do
  echo "Waiting for MariaDB..."
  sleep 2
done
```

---

### 🔧 Technical Deep Dives

#### Q15: How does WordPress connect to the database?
**Answer**: Via `wp-config.php` which is generated during setup.

```bash
# Show wp-config.php
docker exec wordpress cat /var/www/html/wp-config.php | grep DB_

# Expected:
define('DB_NAME', 'wordpress');
define('DB_USER', 'wpuser');
define('DB_PASSWORD', 'wppassword');
define('DB_HOST', 'mariadb');  # ← Docker DNS resolves this
```

**Connection test**:
```bash
docker exec wordpress mysql -h mariadb -u wpuser -p$DB_PASSWORD wordpress -e "SHOW TABLES;"
```

---

#### Q16: What is PHP-FPM? Why not Apache?
**Answer**:

**PHP-FPM** (FastCGI Process Manager):
- Separate process pool for PHP
- Better performance under load
- Used with Nginx (Nginx handles HTTP, PHP-FPM executes PHP)

**Apache** (mod_php):
- All-in-one (web server + PHP)
- Simpler but less performant

**In this project**: Nginx + PHP-FPM = best performance

**Verification**:
```bash
docker exec wordpress ps aux | grep php-fpm
# Shows multiple PHP-FPM worker processes
```

---

#### Q17: How do containers communicate without exposing ports to the host?
**Answer**: Docker's internal DNS on the bridge network.

```bash
# From WordPress container to MariaDB:
# No need for localhost:3306
# Just use the service name:
mysql -h mariadb -p 3306

# Docker's embedded DNS resolves "mariadb" to container IP
# Example: 172.18.0.3

# Verify DNS resolution:
docker exec wordpress nslookup mariadb
```

**Security benefit**: Database port 3306 never exposed to internet

---

#### Q18: What is Redis used for in this project?
**Answer**: Object caching to improve WordPress performance.

**How it works**:
1. WordPress queries database: `SELECT * FROM wp_posts`
2. Result cached in Redis
3. Next request: WordPress checks Redis first (fast)
4. Only queries database if cache miss (slow)

**Verification**:
```bash
# Check Redis is running
docker exec redis redis-cli -a $REDIS_PASSWORD ping

# Check cached keys
docker exec redis redis-cli -a $REDIS_PASSWORD KEYS *

# If WordPress has Redis plugin:
docker exec wordpress ls /var/www/html/wp-content/object-cache.php
```

---

#### Q19: How would you backup and restore the database?
**Answer**:

**Backup**:
```bash
# Export all WordPress data
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD wordpress > backup_$(date +%Y%m%d).sql

# Verify backup
ls -lh backup_*.sql
```

**Restore**:
```bash
# Import from backup
docker exec -i mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress < backup_20251106.sql

# Verify restoration
docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress -e "SELECT COUNT(*) FROM wp_posts;"
```

---

#### Q20: What security measures are implemented?
**Answer**:

1. ✅ **HTTPS only** (TLS 1.2/1.3)
2. ✅ **Database not exposed** to host (only internal network)
3. ✅ **Redis password-protected**
4. ✅ **Services isolated** in Docker network
5. ✅ **Minimal base images** (Alpine where possible)
6. ✅ **Environment variables** for secrets (not hardcoded)

**Improvements for production**:
- Use proper CA-signed certificates (Let's Encrypt)
- Implement Docker secrets instead of `.env`
- Run containers as non-root users
- Enable SELinux/AppArmor
- Remove FTP (use SFTP)
- Don't expose Portainer publicly

---

### 🚨 Bonus Services Questions

#### Q21: Why is FTP insecure? What's the alternative?
**Answer**:

**FTP Problems**:
- ❌ Passwords transmitted in cleartext
- ❌ Data transferred unencrypted
- ❌ Vulnerable to sniffing/MITM attacks

**Alternatives**:
- ✅ **SFTP** (SSH File Transfer Protocol) - encrypted
- ✅ **FTPS** (FTP over SSL/TLS) - encrypted
- ✅ **SCP** (Secure Copy) - encrypted

**In this project**: FTP for demonstration only. Never use in production.

---

#### Q22: What is Adminer? Why not phpMyAdmin?
**Answer**:

**Adminer**:
- Single PHP file
- Lightweight (~500KB)
- Supports multiple databases (MySQL, PostgreSQL, SQLite, etc.)

**phpMyAdmin**:
- Full application
- MySQL-only
- Heavier (~10MB)

**Both are fine** for this project. Adminer chosen for simplicity.

---

#### Q23: What security risk does Portainer pose?
**Answer**: Portainer binds the Docker socket (`/var/run/docker.sock`).

**Risk**: Anyone with access to Portainer has **root access** to the host.

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock  # ⚠️ Dangerous!
```

**Why dangerous**:
- Can start containers with `--privileged`
- Can mount host filesystem
- Can break out of container isolation

**Mitigation**:
- Never expose Portainer publicly
- Use authentication
- Consider rootless Docker
- Use Docker in Docker (DinD) instead of binding socket

---

### ⚙️ Makefile & Workflow Questions

#### Q24: Explain your Makefile targets.
**Answer**:

```makefile
make        # Build images + start containers
make build  # Build/rebuild Docker images
make up     # Start containers (must build first)
make down   # Stop containers (keep volumes)
make clean  # Stop + prune unused images
make fclean # ⚠️ Remove everything (data loss!)
make re     # Complete rebuild (fclean + all)
make logs   # Stream all container logs
make status # Show container states
```

**Demonstration**: Run any of these commands to show evaluator

---

#### Q25: What happens when you run `make re`?
**Answer**:

```bash
# 1. make fclean:
docker-compose down -v --rmi all  # Stop, remove containers, volumes, images
docker system prune -af --volumes  # Clean all unused resources

# 2. make all:
docker-compose build  # Rebuild all images from scratch
docker-compose up -d  # Start containers

# Result: Fresh installation, all data lost
```

**When to use**: Fix corruption, test clean install, prepare for evaluation

---

### 🎯 Practical Demonstrations

#### Q26: Show me this works. Create a post and prove it persists.
**Answer**:

```bash
# 1. Open WordPress admin
# https://abamksa.42.fr/wp-admin

# 2. Create a post
# Title: "Persistence Test"
# Content: "Testing volumes"
# Click Publish

# 3. Verify in database
docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress \
  -e "SELECT post_title FROM wp_posts WHERE post_type='post';"

# 4. Restart containers
make down && make up

# 5. Verify post still exists
# Open: https://abamksa.42.fr
# Post should still be visible

# 6. Check volume
ls -lh /home/joker/data/wordpress/
# Files still present
```

---

#### Q27: Break something and fix it in front of me.
**Answer (Example)**:

```bash
# Scenario: Break database connection

# 1. Corrupt .env file
docker exec wordpress bash -c 'sed -i "s/DB_HOST=mariadb/DB_HOST=wrong/" /var/www/html/wp-config.php'

# 2. Show error
curl -k https://abamksa.42.fr
# Shows: "Error establishing database connection"

# 3. Diagnose
docker logs wordpress | tail -20
# Shows connection errors

# 4. Fix
docker exec wordpress bash -c 'sed -i "s/DB_HOST=wrong/DB_HOST=mariadb/" /var/www/html/wp-config.php'

# 5. Verify fix
curl -k https://abamksa.42.fr
# Works again!
```

---

## Evaluator Checklist & Probable Questions

### 🎯 Quick Defense Checklist

Print this and bring to defense:

```
☐ Can explain: Docker vs VM
☐ Can explain: Image vs Container
☐ Can explain: Volume persistence mechanism
☐ Can explain: Bridge network and DNS
☐ Can start project: make
☐ Can show logs: make logs
☐ Can enter container: docker exec -it wordpress bash
☐ Can test Nginx: curl -Ik https://domain
☐ Can test database: docker exec mariadb mysqladmin ping
☐ Can test Redis: docker exec redis redis-cli ping
☐ Can show SSL cert: docker exec nginx ls /etc/ssl/certs/
☐ Can show wp-config: docker exec wordpress cat wp-config.php
☐ Can prove persistence: Create file, restart, verify exists
☐ Can backup database: mysqldump command
☐ Can fix 502 error: Check WordPress is running, verify nginx config
☐ Can explain security risks: FTP, Portainer socket binding
☐ Know all 8 services and their roles
☐ Know difference between make down and make fclean
```

---

### 💡 Pro Tips for Defense

1. **Be confident**: You built this, you understand it
2. **Show, don't just tell**: Run commands instead of just explaining
3. **Know your weak points**: FTP security, Portainer risks
4. **Practice failing**: Break something and fix it
5. **Understand WHY**: Not just HOW (Why Nginx+PHP-FPM? Why volumes?)
6. **Keep it simple**: Don't overexplain, answer the question asked
7. **Have backup plan**: If website down, know how to check logs

---

### 🚨 Common Evaluator Tricks

**They might**:
- Delete a container: `docker rm -f wordpress`
  - **Your response**: `make up` - data survives in volume
  
- Change .env password
  - **Your response**: Show error, explain connection failure, fix .env

- Ask "What if MariaDB crashes?"
  - **Your response**: `docker restart mariadb` - data in volume persists

- Request SSL certificate details
  - **Your response**: `docker exec nginx openssl x509 -in /cert -noout -text`

- Ask to create WordPress post
  - **Your response**: Show admin panel, create post, verify in database

---

---

## 📚 Additional Resources

### Official Documentation

| Technology | Official Docs | Why Read |
|------------|---------------|----------|
| **Docker** | [docs.docker.com](https://docs.docker.com) | Core containerization concepts |
| **Docker Compose** | [docs.docker.com/compose](https://docs.docker.com/compose/) | Multi-container orchestration |
| **Nginx** | [nginx.org/en/docs](https://nginx.org/en/docs/) | Web server configuration |
| **WordPress** | [developer.wordpress.org](https://developer.wordpress.org/) | PHP/MySQL CMS internals |
| **MariaDB** | [mariadb.com/kb](https://mariadb.com/kb/en/library/) | Database administration |
| **Redis** | [redis.io/documentation](https://redis.io/documentation) | Caching strategies |
| **PHP-FPM** | [php.net/manual/en/install.fpm.php](https://php.net/manual/en/install.fpm.php) | FastCGI configuration |

---

### Recommended Reading

**Docker Fundamentals**:
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Security](https://docs.docker.com/engine/security/)

**Nginx + PHP-FPM**:
- [Nginx + PHP-FPM Configuration](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
- [Understanding FastCGI](https://www.nginx.com/resources/glossary/reverse-proxy-server/)

**WordPress Optimization**:
- [WordPress with Redis Object Cache](https://wordpress.org/plugins/redis-cache/)
- [WordPress Security Hardening](https://wordpress.org/support/article/hardening-wordpress/)

---

### Useful Docker Commands Reference

```bash
# === CONTAINER MANAGEMENT ===
docker ps                          # List running containers
docker ps -a                       # List all containers
docker start <container>           # Start stopped container
docker stop <container>            # Stop running container
docker restart <container>         # Restart container
docker rm <container>              # Remove container
docker rm -f <container>           # Force remove running container

# === IMAGE MANAGEMENT ===
docker images                      # List images
docker rmi <image>                 # Remove image
docker build -t name:tag .         # Build image from Dockerfile
docker pull image:tag              # Download image from registry
docker push image:tag              # Upload image to registry

# === LOGS & DEBUGGING ===
docker logs <container>            # View container logs
docker logs -f <container>         # Follow logs (live)
docker logs --tail 100 <container> # Last 100 lines
docker exec -it <container> bash   # Interactive shell
docker inspect <container>         # Detailed container info
docker stats                       # Resource usage

# === VOLUMES ===
docker volume ls                   # List volumes
docker volume inspect <volume>     # Volume details
docker volume rm <volume>          # Remove volume
docker volume prune                # Remove unused volumes

# === NETWORKS ===
docker network ls                  # List networks
docker network inspect <network>   # Network details
docker network create <network>    # Create network
docker network rm <network>        # Remove network

# === SYSTEM MAINTENANCE ===
docker system df                   # Show disk usage
docker system prune                # Remove unused resources
docker system prune -a             # Remove all unused images too
docker system prune --volumes      # Remove unused volumes too
```

---

### Quick Troubleshooting Commands

```bash
# Container won't start?
docker logs <container>
docker inspect <container> | grep -A 20 State

# Network issues?
docker network inspect inception-network
docker exec <container> ping <other-container>

# Volume problems?
docker volume inspect <volume>
ls -la /var/lib/docker/volumes/<volume>/_data

# Permission errors?
docker exec <container> ls -la /path/to/files
docker exec <container> chown -R www-data:www-data /path

# Configuration errors?
docker exec nginx nginx -t
docker exec mariadb mysqladmin ping
docker exec redis redis-cli ping
```

---

### Practice Scenarios for Defense

**Scenario 1: Evaluator stops MariaDB**
```bash
docker stop mariadb
# Website shows database error
docker start mariadb
# Wait ~10 seconds for initialization
# Website works again
```

**Scenario 2: Evaluator deletes WordPress container**
```bash
docker rm -f wordpress
# Website down
make up
# Website back, data intact (volume survived)
```

**Scenario 3: Evaluator asks for database backup**
```bash
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD wordpress > backup.sql
ls -lh backup.sql
# Show file size and timestamp
```

**Scenario 4: Evaluator corrupts wp-config.php**
```bash
docker exec wordpress bash -c 'echo "BROKEN" >> /var/www/html/wp-config.php'
# Website breaks
docker exec wordpress bash -c 'sed -i "/BROKEN/d" /var/www/html/wp-config.php'
# OR restore from backup
# Website works
```

---

### Final Pre-Defense Checklist

**24 Hours Before Defense**:
- [ ] Run `make re` for clean installation
- [ ] Verify all 8 containers start successfully
- [ ] Test HTTPS access in browser
- [ ] Create a test WordPress post
- [ ] Verify post persists after `make down && make up`
- [ ] Test each service individually (see Testing section)
- [ ] Review all Q&A in this README
- [ ] Print the one-page cheat sheet

**During Defense**:
- [ ] Keep this README open for reference
- [ ] Have terminal ready with `cd /home/joker/Workspace/Inception`
- [ ] Know your `.env` file contents (but don't show passwords publicly!)
- [ ] Demonstrate, don't just explain
- [ ] If stuck, check logs first: `make logs`
- [ ] Be honest if you don't know something - better than guessing

**After Defense**:
- [ ] Celebrate! 🎉 You earned it!

---

## 🎓 Conclusion

You now have a **complete** understanding of:
- ✅ Docker containerization and orchestration
- ✅ Multi-service architecture with Nginx, WordPress, MariaDB, Redis
- ✅ Volume persistence and data management
- ✅ Network isolation and service communication
- ✅ Security considerations and trade-offs
- ✅ Debugging and troubleshooting methodology
- ✅ Every question an evaluator might ask

**You're ready to defend this project with confidence!**

Remember: The evaluator wants to see that you **understand** what you built, not that you memorized answers. Use this README as a reference, but make the knowledge your own by practicing the commands and understanding the concepts.

**Good luck! 🚀**

---

*This README was created to help you master the Inception project. If you have suggestions for improvements, feel free to contribute!*

---

**Last Updated**: November 6, 2025  
**Version**: 2.0 - Complete Defense Edition  
**Author**: Inception Project Documentation Team

---

## Service testing — how to check and master each service

This section gives hands-on commands and quick tests you can run to verify each service is alive, configured correctly, and easy-to-demonstrate to evaluators. For each service I show: quick status checks, deeper tests (entering the container), and one-or-two mastery tasks you should be able to perform during a defense.

General tips before testing:
- Run `make status` (or `cd srcs && docker-compose ps`) to see containers and names.
- Use `make logs` or `docker-compose logs -f <service>` to follow logs in real time.
- Use `docker exec -it <container> bash` (or `sh`) to inspect filesystem, configs, processes.

1) Nginx (`nginx`)
- Quick check (from host):
  - `curl -vk https://localhost/` (use `-k` if certs are self-signed)
  - `curl -I http://localhost:8080/` (static site)
- Logs and config test:
  - `docker logs -f nginx`
  - `docker exec -it nginx nginx -t` (validate config)
- Mastery tasks to demo:
  - Show `nginx -t` output and then gracefully reload without downtime: `docker exec -it nginx nginx -s reload`.
  - Inspect which upstream Nginx is proxying to: open `srcs/requirements/nginx/conf/nginx.conf` and inside container `cat /etc/nginx/nginx.conf` (or the site file) to point to the `wordpress` upstream.

2) WordPress (`wordpress`)
- Quick check (HTTP):
  - `curl -I https://localhost/` or `curl -L -k https://localhost/` to follow redirects.
- Check PHP/FPM and file permissions:
  - `docker exec -it wordpress bash`
  - Inside container: `ps aux | grep php-fpm` and `ls -la /var/www/html`.
- DB connectivity test from WP container:
  - If the container lacks a client, install or use `mariadb` container: `docker exec -it wordpress bash -c 'php -r "var_export((bool)mysqli_connect(\"mariadb\", \"${DB_USER}\", \"${DB_PASSWORD}\"));"'` replacing env vars if needed. Alternatively run `docker exec -it mariadb mysql -u root -p`.
- Mastery tasks:
  - Demonstrate creating a new post via the WP admin UI and show it persists after `make down && make up` (tests volumes).
  - Show ability to list and restore a WordPress file from the `wordpress-data` volume.

3) MariaDB (`mariadb`)
- Quick status and logs:
  - `docker logs -f mariadb`
  - `docker exec -it mariadb mysqladmin --silent --wait=30 ping -u${MYSQL_USER} -p${MYSQL_PASSWORD}` (replace env names as appropriate) — returns "mysqld is alive" when up.
- Enter and run SQL:
  - `docker exec -it mariadb mysql -u root -p` then `SHOW DATABASES;` and inspect `wordpress` DB.
- Mastery tasks:
  - Show how to export the WordPress DB: `docker exec -i mariadb mysqldump -u ${DB_USER} -p${DB_PASS} ${DB_NAME} > backup.sql` (run from host shell).
  - Show that restoring `backup.sql` recreates tables if needed.

4) Redis (`redis`)
- Quick check and logs:
  - `docker logs -f redis`
  - `docker exec -it redis redis-cli ping` should return `PONG`.
- From WordPress container (if `redis-cli` available):
  - `docker exec -it wordpress bash -c 'redis-cli -h redis ping'`
- Mastery tasks:
  - Demonstrate set/get: `docker exec -it redis redis-cli set testkey hello` and `docker exec -it redis redis-cli get testkey`.
  - If WP uses object-cache, show a cached object before/after clearing Redis.

5) Adminer (`adminer`)
- Quick check:
  - `curl -I http://localhost:8081` or open `http://localhost:8081` in a browser.
  - Use Adminer to log in with the DB credentials from `srcs/.env` and list the `wordpress` DB tables.
- Mastery tasks:
  - Show you can run a simple `SELECT COUNT(*) FROM wp_posts;` and export a small SQL dump using Adminer's UI.

6) Portainer (`portainer`)
- Quick check:
  - Open `https://localhost:9443` (accept self-signed cert if needed) and show the containers list.
  - From CLI: `docker ps` and verify the same containers appear in Portainer.
- Mastery tasks:
  - Show container logs in Portainer, then repeat the same in the terminal using `docker logs` to prove parity.
  - Demonstrate stopping and starting a container from Portainer and the effect on `docker ps`.

7) FTP (`ftp`)
>- WARNING: FTP here is for learning only and is insecure. Avoid using in untrusted networks.
- Quick check (passive test from the host):
  - Try `ftp localhost` (or use `lftp`): `lftp -u <user>,<pass> -p 21 localhost` then `ls` and `put` a small file into `/var/www/html` to show uploads.
  - Check server logs: `docker logs -f ftp`.
- Mastery tasks:
  - Show an upload to the `wordpress-data` volume and verify file appears inside `wordpress` container: `docker exec -it wordpress ls -la /var/www/html`.

8) Static site (`static-website`)
- Quick check:
  - `curl -I http://localhost:8080/` and `curl http://localhost:8080/` to fetch the index.html and confirm content.
- Mastery tasks:
  - Edit a file in the `static-site-data` volume (or inside the `static-website` container) and show the change reflected via `curl` without rebuilding the image (shows mounted volume behavior).

9) General Docker and network checks
- Inspect networks and endpoints:
  - `docker network ls` and `docker network inspect inception-network` to show connected containers and IPs.
- Inspect container details:
  - `docker inspect nginx` (or any container) to show mount points, environment, and network settings.
- Port listening checks on host:
  - `ss -ltnp | grep -E "(:443|:8080|:8081|:9443|:21)"` to show host ports bound.

10) Persistence & volume checks (demonstrate to evaluators)
- Test workflow to show persistence:
  - Create a file in WordPress volume: `docker exec -it wordpress bash -c "echo 'persist' > /var/www/html/keep.txt"`.
  - `make down && make up`
  - `docker exec -it wordpress cat /var/www/html/keep.txt` should show `persist`.

11) Small health-check script (example)
Here is a tiny health-check script you can add to `srcs/tools/check-stack.sh` and run on your host to validate basic endpoints quickly:

```bash
#!/usr/bin/env bash
set -e
echo "Checking services..."
curl -s -k -o /dev/null -w "%{http_code}" https://localhost/ && echo " nginx: OK"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ && echo " static-site: OK"
docker exec -it redis redis-cli ping | grep PONG && echo " redis: OK"
docker exec -it mariadb mysqladmin ping -u root -p${MYSQL_ROOT_PASSWORD} | grep 'mysqld is alive' && echo " mariadb: OK"
echo "done"
```

Place proper `MYSQL_ROOT_PASSWORD` or source `srcs/.env` before running. This is intentionally minimal — extend with DB queries or WP HTTP checks for a stronger validation.

---

If you want, I can also:
- Create `srcs/tools/check-stack.sh` automatically, make it executable, and add a README line showing how to run it.
- Produce printable one-page cheat-sheet of the most important commands above for quick reference during a defense.

End of testing section.

## Final notes

- This README aims to be both a learning resource and a reference during evaluations.
- If you want, I can also:
  - Add a short script that runs a health-check suite against the stack (HTTP checks, DB connect test).
  - Add a `docs/` folder with copies of important config excerpts and annotated explanations.

Good luck with your defense — if you want, tell me which parts you expect the evaluators to focus on and I can produce a one-page cheat sheet you can print or memorize.
