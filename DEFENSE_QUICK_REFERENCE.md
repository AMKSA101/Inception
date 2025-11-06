# Inception Defense - Quick Reference Card

> **Print this document and bring it to your defense!**

---

## 🚀 Essential Commands

```bash
# START PROJECT
make                    # Build and start everything
make status            # Check container status
docker ps              # List running containers

# DEBUGGING
make logs              # View all logs
docker logs -f nginx   # Follow specific service logs
docker exec -it wordpress bash  # Enter container

# TESTING
curl -Ik https://abamksa.42.fr    # Test HTTPS
docker exec nginx nginx -t         # Validate Nginx config
docker exec mariadb mysqladmin ping -u root -p[password]
docker exec redis redis-cli -a [password] ping

# RESTART/REBUILD
make down              # Stop (keeps data)
make fclean           # ⚠️ DELETE EVERYTHING
make re               # Full rebuild
```

---

## 📦 8 Services Architecture

```
Browser → Nginx (HTTPS:443) → WordPress (PHP-FPM:9000)
                              ↓                    ↓
                         MariaDB (DB:3306)   Redis (Cache:6379)
                              
Bonus: Adminer, Portainer, FTP, Static-Website
```

---

## 🔑 Key Concepts (30-Second Explanations)

**Docker vs VM**  
Container = Shares host kernel, lightweight  
VM = Full OS, heavy

**Image vs Container**  
Image = Blueprint (read-only)  
Container = Running instance

**Volume**  
Persistent storage that survives container deletion  
Example: `/home/joker/data/wordpress:/var/www/html`

**Network**  
Bridge network allows containers to talk by name  
Example: `mysql -h mariadb` (not IP address!)

**depends_on**  
Controls START ORDER, NOT readiness  
nginx depends on wordpress = starts AFTER, not WHEN READY

---

## ❓ Top 10 Questions & Answers

**Q1: How do you start the project?**  
`make` or `cd srcs && docker-compose up -d --build`

**Q2: Where are WordPress files?**  
Container: `/var/www/html`  
Host: `/home/joker/data/wordpress`

**Q3: How does Nginx know where to proxy?**  
`nginx.conf` has: `fastcgi_pass wordpress:9000;`

**Q4: How do you prove volumes work?**  
```bash
docker exec wordpress touch /var/www/html/test.txt
make down && make up
docker exec wordpress ls /var/www/html/test.txt  # Still exists!
```

**Q5: What if you get 502 Bad Gateway?**  
- Check WordPress is running: `docker ps | grep wordpress`
- Check PHP-FPM: `docker exec wordpress ps aux | grep php-fpm`
- Validate config: `docker exec nginx nginx -t`

**Q6: Database connection error?**  
- Check MariaDB running: `docker logs mariadb`
- Test connection: `docker exec wordpress mysql -h mariadb -u $USER -p`
- Verify .env credentials match

**Q7: Where are database passwords?**  
`srcs/.env` file (environment variables)

**Q8: How to backup database?**  
`docker exec mariadb mysqldump -u root -p$PASS wordpress > backup.sql`

**Q9: What are security issues?**  
- FTP = plaintext (use SFTP in production)
- Self-signed SSL (use Let's Encrypt)
- Portainer socket binding = root access risk

**Q10: What is Redis for?**  
Caching database queries for faster WordPress performance

---

## 🐛 Quick Troubleshooting

| Symptom | Command | Fix |
|---------|---------|-----|
| Container not running | `docker ps -a` | `docker restart [name]` |
| 502 Error | `docker logs wordpress` | Check PHP-FPM running |
| DB Error | `docker logs mariadb` | Check .env credentials |
| Permission denied | `docker exec [container] ls -la` | `chown www-data:www-data` |
| Port conflict | `sudo ss -ltnp \| grep 443` | Kill process or change port |

---

## 💾 Volume Persistence Test

```bash
# 1. Create test data
docker exec wordpress bash -c 'echo TEST > /var/www/html/test.txt'

# 2. Restart everything
make down && make up

# 3. Verify data survived
docker exec wordpress cat /var/www/html/test.txt
# Output: TEST ✅
```

---

## 🌐 Network Communication Test

```bash
# Test containers can reach each other
docker exec wordpress ping -c 2 mariadb    # ✅ Should work
docker exec wordpress ping -c 2 redis      # ✅ Should work

# DNS resolution
docker exec wordpress nslookup mariadb     # Shows IP

# Inspect network
docker network inspect srcs_inception-network
```

---

## 🗄️ Database Commands

```bash
# Enter database
docker exec -it mariadb mysql -u root -p

# Inside MySQL:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT user_login FROM wp_users;

# Backup
docker exec mariadb mysqldump -u root -p$PASS wordpress > backup.sql

# Restore
docker exec -i mariadb mysql -u root -p$PASS wordpress < backup.sql
```

---

## 🔐 Security: What Evaluator Should Know

**Expected (OK for learning)**:
- ✅ FTP insecure (plaintext) - would use SFTP in production
- ✅ Self-signed SSL - would use Let's Encrypt
- ✅ Portainer socket binding - root access risk

**Implemented**:
- ✅ HTTPS only (TLS 1.2/1.3)
- ✅ Database not exposed to host
- ✅ Redis password protected
- ✅ Isolated network

---

## 📊 Health Check

Run this script:
```bash
./srcs/tools/healthcheck.sh
```

Or manual checks:
```bash
# All containers running?
docker ps | wc -l  # Should be 9 (8 containers + header)

# Any errors?
make logs | grep -i error

# Website accessible?
curl -Ik https://your-domain.42.fr

# Database responsive?
docker exec mariadb mysqladmin ping -u root -p$PASS

# Redis working?
docker exec redis redis-cli -a $PASS ping  # Should return PONG
```

---

## 💡 Defense Pro Tips

1. **Show, don't just tell** - Run commands instead of explaining
2. **Keep README open** - Reference when needed
3. **Know your .env** - But don't show passwords publicly
4. **Practice breaking/fixing** - Delete container, restart, prove data persists
5. **Explain WHY** - Not just how (Why Nginx+PHP-FPM? Performance!)
6. **Be honest** - Better to say "I don't know" than guess wrong
7. **Stay calm** - You built this, you understand it!

---

## ⚡ Super Quick Reference

```bash
Start:    make
Status:   docker ps
Logs:     make logs
Enter:    docker exec -it [container] bash
Test:     curl -Ik https://domain
Restart:  make down && make up
Rebuild:  make re  # ⚠️ Deletes data!
```

---

## ✅ Defense Checklist

```
☐ All 8 containers running
☐ Can access WordPress via HTTPS
☐ Can create/view WordPress posts
☐ Can enter any container
☐ Can show database tables
☐ Can prove volume persistence
☐ Can test Redis connection
☐ Know .env file location and contents
☐ Can explain Docker vs VM
☐ Can explain image vs container
☐ Can explain why HTTPS
☐ Can explain security issues
☐ Can backup database
☐ Can fix 502 error
☐ Can restart specific service
```

---

## 🎯 Final Words

**You've got this!** 🚀

The evaluator wants to see you **understand** what you built.  
Use commands to **demonstrate**, not just describe.  
If stuck, check logs: `make logs`

**Good luck with your defense!**

---

*Last Updated: November 6, 2025*  
*Keep this card with you during defense*
