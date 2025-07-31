# 🚀 Inception Project - Quick Reference

## 📋 Essential Commands

### Project Management
```bash
# Start everything
make

# Check status
make status

# View logs
make logs

# Stop services
make down

# Complete reset
make fclean && make
```

### Debugging Commands
```bash
# Check container health
docker-compose ps

# View specific service logs
docker-compose logs nginx
docker-compose logs wordpress  
docker-compose logs mariadb

# Enter container shell
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Test connectivity
curl -k https://localhost:443
```

## 🔧 Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| 502 Bad Gateway | `docker-compose restart nginx wordpress` |
| Database connection error | `docker-compose restart mariadb wordpress` |
| SSL certificate error | Use `curl -k` or accept in browser |
| Permission denied | `docker exec wordpress chown -R www-data:www-data /var/www/html/` |
| Port already in use | `make down && make up` |

## 📁 Important File Locations

| Service | Configuration | Logs | Data |
|---------|---------------|------|------|
| NGINX | `/etc/nginx/nginx.conf` | `docker-compose logs nginx` | N/A |
| WordPress | `/var/www/html/wp-config.php` | `docker-compose logs wordpress` | `wordpress-data:/var/www/html/` |
| MariaDB | `/etc/mysql/mariadb.conf.d/50-server.cnf` | `docker-compose logs mariadb` | `mariadb-data:/var/lib/mysql/` |

## 🌐 Access Points

- **Website**: https://localhost:443
- **WordPress Admin**: https://localhost:443/wp-admin
  - Username: `admin`
  - Password: `admin123`

## 🔍 Health Check Commands

```bash
# Quick system check
docker-compose ps && curl -k -s https://localhost:443 | grep -q "WordPress" && echo "✅ System OK" || echo "❌ System Error"

# Database connectivity
docker exec wordpress mysqladmin ping -h mariadb -u wp_user -p

# File permissions
docker exec wordpress ls -la /var/www/html/ | head -5

# Service status
docker-compose top
```

## 📊 Resource Usage

```bash
# Container resource usage
docker stats --no-stream

# Volume usage
docker system df

# Network information
docker network ls
docker network inspect srcs_inception-network
```

---

*Last Updated: July 25, 2025*
