# Inception — Docker Infrastructure Project

**A clean, simplified Docker-based multi-service web infrastructure**

---

## 📋 Overview

This project deploys a complete web infrastructure using Docker containers with:
- **NGINX** - Web server with SSL/TLS
- **WordPress** - CMS with PHP-FPM 7.4
- **MariaDB** - MySQL database
- **Redis** - Object cache server
- **Adminer** - Database management UI
- **FTP** - File transfer service (vsftpd)
- **Portainer** - Docker management UI
- **Static Website** - Simple static site

---

## 🏗️ Architecture

```
                     Browser (HTTPS)
                            |
                      [Port 443]
                            |
                    ╔═══════════════╗
                    ║    NGINX      ║  SSL Termination
                    ╚═══════════════╝  Reverse Proxy
                       |         |
                       ↓         ↓
            ╔════════════════╗  ╔═══════════════╗
            ║  WordPress     ║  ║  Adminer      ║
            ║  (PHP-FPM)     ║  ║  (PHP-FPM)    ║
            ╚════════════════╝  ╚═══════════════╝
                  |      |              |
                  ↓      ↓              ↓
         ╔════════════╗  ╔═══════════════╗
         ║  MariaDB   ║  ║    Redis      ║
         ║ (Database) ║  ║   (Cache)     ║
         ╚════════════╝  ╚═══════════════╝

Bonus Services:
╔═══════╗  ╔═══════════╗  ╔═══════════════╗
║  FTP  ║  ║ Portainer ║  ║ Static Site   ║
╚═══════╝  ╚═══════════╝  ╚═══════════════╝

Network: inception (bridge)
```

---

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Add domain to `/etc/hosts`:
  ```bash
  echo "127.0.0.1 abamksa.42.fr" | sudo tee -a /etc/hosts
  ```

### Build and Run
```bash
cd /home/joker/Workspace/Inception
make        # Build and start all services
```

### Makefile Commands
```bash
make            # Build and start all services
make status     # Check container status
make logs       # View live logs
make down       # Stop all services
make restart    # Restart services
make clean      # Clean up containers and images
make fclean     # Full cleanup including data
make re         # Rebuild everything from scratch
./check.sh      # Run comprehensive system check
```

---

## 📦 Services

### NGINX
- **Port:** 443 (HTTPS only)
- **SSL:** Self-signed certificate (TLSv1.2, TLSv1.3)
- **Purpose:** Web server and reverse proxy
- **Serves:** WordPress, Adminer proxying

### WordPress
- **URL:** https://abamksa.42.fr
- **Admin Panel:** https://abamksa.42.fr/wp-admin/
- **Credentials:** `abamksa` / `secure_pass_123`
- **Second User:** `wpuser` / `user123` (Author role)
- **PHP Version:** 7.4-FPM
- **Features:** Redis cache, WP-CLI automation

### MariaDB
- **Port:** 3306 (internal only)
- **Database:** wordpress
- **User:** wp_user
- **Access:** `docker exec -it mariadb mysql -u wp_user -p`

### Redis
- **Port:** 6379 (internal only)
- **Purpose:** WordPress object caching
- **Test:** `docker exec -it redis redis-cli ping`
- **Password:** Set in .env file

### Adminer
- **Access:** Via NGINX proxy (configure in nginx.conf)
- **Purpose:** Web-based database management
- **Connect to:** mariadb:3306

### FTP
- **Ports:** 21, 21000-21010
- **User:** ftpuser
- **Password:** ftpuser789
- **Access:** `ftp localhost 21` or `ftp -A localhost 21` (active mode)
- **Directory:** /var/www/html (WordPress files)

### Portainer
- **Port:** 9443
- **URL:** http://localhost:9443
- **Purpose:** Docker container management UI
- **Setup:** Create admin password on first access

### Static Website
- **Purpose:** Demonstration static site
- **Server:** Python HTTP server (port 8000 internal)

---

## 📁 Project Structure

```
Inception/
├── Makefile                          # Build automation
├── check.sh                          # System verification script
├── README.md                         # This file
└── srcs/
    ├── docker-compose.yml           # Service orchestration
    ├── .env                         # Environment variables (create this)
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/nginx.conf
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/setup-wordpress.sh
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf
        │   └── tools/init.sh
        └── bonus/
            ├── redis/
            │   ├── Dockerfile
            │   └── conf/redis.conf
            ├── adminer/
            │   ├── Dockerfile
            │   └── conf/www.conf
            ├── ftp/
            │   ├── Dockerfile
            │   ├── conf/vsftpd.conf
            │   └── tools/setup-ftp.sh
            ├── portainer/
            │   └── Dockerfile
            └── static-website/
                ├── Dockerfile
                └── website/
                    ├── index.html
                    ├── styles.css
                    └── script.js
```

---

## ⚙️ Configuration

### Docker Compose
- **Network:** `inception` (bridge driver)
- **Volumes:**
  - `mariadb_data` → `/home/joker/data/mariadb`
  - `wordpress_data` → `/home/joker/data/wordpress`
  - `portainer_data` → Local Docker volume

### Environment Variables

Create `srcs/.env` file with:

```bash
# Domain
DOMAIN_NAME=abamksa.42.fr

# MariaDB
MYSQL_ROOT_PASSWORD=root_password_123
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=db_password_123

# Redis
REDIS_PASSWORD=redis_password_123

# FTP
FTP_USER=ftpuser
FTP_PASSWORD=ftpuser789
```

---

## 🧪 Testing & Verification

### Automated System Check
```bash
./check.sh
```

This verifies:
- ✅ Docker and Docker Compose installation
- ✅ All 8 containers running
- ✅ Network connectivity
- ✅ Volume mounts
- ✅ Service health
- ✅ SSL certificates
- ✅ Port bindings
- ✅ Domain resolution

### Manual Testing

**NGINX:**
```bash
curl -Ik https://abamksa.42.fr
docker exec nginx nginx -t
```

**WordPress:**
```bash
firefox https://abamksa.42.fr/wp-admin/
docker exec wordpress php-fpm7.4 -t
docker exec wordpress wp --info --allow-root
```

**MariaDB:**
```bash
docker exec mariadb mysqladmin ping -h localhost
docker exec -it mariadb mysql -u wp_user -p wordpress
```

**Redis:**
```bash
docker exec redis redis-cli ping
docker exec wordpress wp redis status --allow-root
```

**FTP:**
```bash
ftp -A localhost 21
# Login: ftpuser / ftpuser789
# Commands: pwd, ls, cd /var/www/html
```

**Portainer:**
```bash
firefox http://localhost:9443
```

---

## 🔐 Security

- ✅ HTTPS only (no HTTP on port 80)
- ✅ TLS 1.2 and 1.3 protocols
- ✅ Self-signed SSL certificate
- ✅ Isolated Docker network
- ✅ Passwords in .env (not in code)
- ✅ Minimal exposed ports
- ✅ Non-root users where possible
- ✅ Chroot for FTP users

---

## 🐛 Troubleshooting

### Containers Not Starting
```bash
make logs                      # View all logs
docker logs <container_name>   # View specific container
docker compose -f srcs/docker-compose.yml config  # Validate syntax
```

### WordPress Issues
```bash
# Check domain resolution
ping abamksa.42.fr

# Verify NGINX
docker exec nginx nginx -t
docker logs nginx --tail 50

# Check PHP-FPM
docker exec wordpress ps aux | grep php-fpm

# Verify WordPress files
docker exec wordpress ls -la /var/www/html/
```

### Database Connection Issues
```bash
# Test MariaDB
docker exec mariadb mysqladmin ping

# Test connectivity from WordPress
docker exec wordpress nc -zv mariadb 3306

# Check credentials
docker exec wordpress env | grep MYSQL
```

### Redis Cache Issues
```bash
# Test Redis
docker exec redis redis-cli ping

# Check WordPress Redis plugin
docker exec wordpress wp plugin list --allow-root
docker exec wordpress wp redis status --allow-root

# View Redis config in WordPress
docker exec wordpress cat /var/www/html/wp-config.php | grep REDIS
```

### FTP Connection Issues
```bash
# Check FTP container
docker logs ftp

# Try active mode
ftp -A localhost 21

# Access files directly
docker exec ftp ls -la /var/www/html/
```

### Complete Rebuild
```bash
make fclean    # Remove everything including data
make           # Rebuild from scratch
```

---

## 📊 Key Improvements

### Project Simplification
- ✅ Cleaned up Makefile (removed verbose comments)
- ✅ Consistent naming conventions (`inception` network, `_data` volumes)
- ✅ Standardized entrypoint scripts (`docker-entrypoint.sh`)
- ✅ Added `set -e` for proper error handling in scripts
- ✅ Used `netcat` (nc) for service health checks

### Docker Compose Updates
- ✅ Network renamed: `inception-network` → `inception`
- ✅ Volume naming: hyphens → underscores for consistency
- ✅ Explicit environment variables for each service
- ✅ Removed unnecessary volumes
- ✅ Proper port mappings (Portainer 9443, FTP 21 + passive ports)

### Dockerfile Improvements
- ✅ Removed excessive comments
- ✅ Cleaner package installation syntax
- ✅ Consistent formatting across all Dockerfiles
- ✅ Added netcat to WordPress for connectivity checks
- ✅ Proper working directories

### Script Enhancements
- ✅ Created comprehensive `check.sh` verification script
- ✅ Simplified entrypoint scripts
- ✅ Better error handling with `set -e`
- ✅ Replaced mysqladmin with netcat for MariaDB checks

---

## 🎯 Project Requirements

### Mandatory ✅
- ✅ NGINX with TLSv1.2 or TLSv1.3
- ✅ WordPress + PHP-FPM (no nginx)
- ✅ MariaDB (no nginx)
- ✅ Volumes for database and WordPress files
- ✅ Docker network connecting all containers
- ✅ Containers restart on crash
- ✅ No passwords in Dockerfiles (using .env)
- ✅ No `latest` tags
- ✅ Custom Dockerfiles (no ready-made Docker images)
- ✅ Makefile for building

### Bonus ✅
- ✅ Redis cache for WordPress
- ✅ FTP server (vsftpd)
- ✅ Adminer (database management)
- ✅ Static website
- ✅ Portainer (Docker management)

---

## 📚 Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Codex](https://codex.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [Redis Documentation](https://redis.io/documentation)

---

## 👤 Author

**abamksa**
- Project: Inception (42 Network)
- Domain: abamksa.42.fr
- GitHub: AMKSA101

---

## 📄 License

This project is part of the 42 school curriculum.
