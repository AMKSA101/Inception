Inception — One-page printable cheat sheet

Keep this on hand during your defense. Short, copyable commands and quick checks for the stack.

---

Quick make targets (recommended)

- Build & start:
  make          # runs build then up
- Build only:
  make build
- Start (detached):
  make up
- Stop (keep volumes):
  make down
- Full cleanup (danger: deletes volumes & images):
  make fclean
- Rebuild from scratch:
  make re
- Tail logs:
  make logs
- Show status:
  make status

Docker Compose equivalents (from repo root):

cd srcs
docker-compose build
docker-compose up -d
docker-compose logs -f <service>
docker-compose down

---

Important ports & URLs (default mappings)

- Nginx (HTTPS): https://localhost  (443)
- Static site: http://localhost:8080  (8080)
- Adminer (direct): http://localhost:8081  (8081)
- Portainer: https://localhost:9443  (9443)
- FTP (learning only): localhost:21 (and passive 21100-21110)

Named containers (use these names in docker commands):
- mariadb, wordpress, nginx, redis, ftp, static-website, portainer, adminer

---

Fast per-service tests

Nginx
- curl -vk https://localhost/        # shows response, -k for self-signed
- docker exec -it nginx nginx -t     # test config
- docker logs -f nginx

WordPress
- curl -L -k https://localhost/      # follow redirects
- docker exec -it wordpress bash
  ps aux | grep php-fpm
  ls -la /var/www/html

MariaDB
- docker logs -f mariadb
- docker exec -it mariadb mysql -u root -p
- docker exec -it mariadb mysqladmin ping -u${MYSQL_USER} -p${MYSQL_PASSWORD}

Redis
- docker exec -it redis redis-cli ping   # expect PONG
- docker exec -it redis redis-cli set test hello
- docker exec -it redis redis-cli get test

Adminer
- Open http://localhost:8081 and login with DB creds from `srcs/.env`

Portainer
- Open https://localhost:9443 to view containers and logs

FTP (learning only)
- lftp -u <user>,<pass> -p 21 localhost
- docker logs -f ftp

Static site
- curl -I http://localhost:8080/  # expect 200/OK and index content

---

General debugging commands

- Show running containers:
  docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
- Show all containers (including stopped):
  docker ps -a
- Inspect network:
  docker network inspect inception-network
- Inspect container details:
  docker inspect <container>
- See which host ports are bound:
  ss -ltnp | grep -E '(:443|:8080|:8081|:9443|:21)'
- Enter container shell:
  docker exec -it <container> bash
- Follow logs for one service:
  docker logs -f <container>

Persistence test (demonstrate volumes)

# create test file inside WordPress
docker exec -it wordpress bash -c "echo persist > /var/www/html/keep.txt"
make down && make up
docker exec -it wordpress cat /var/www/html/keep.txt   # should print 'persist'

Quick answers you should memorize

- "How do you reset everything?": make fclean (WARNING: deletes data)
- "How to view logs?": make logs or docker logs -f <container>
- "Why depends_on isn't enough?": depends_on only waits for container start, not service readiness. Use healthchecks or manual checks (DB ping).
- "Where are configs?": srcs/requirements/<service>/conf/ (nginx, mariadb, etc.)

Files to point evaluators to

- `Makefile` — automation targets
- `srcs/docker-compose.yml` — services, volumes, networks
- `srcs/requirements/nginx/conf/nginx.conf` — Nginx config
- `srcs/requirements/mariadb/conf/50-server.cnf` — DB config
- `srcs/requirements/wordpress/tools/setup-wordpress.sh` — WP setup & perms

One-line health-check (example)

# Source srcs/.env first if needed
# Minimal: check nginx and static site
curl -s -k -o /dev/null -w "%{http_code}" https://localhost/ && echo " nginx OK"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ && echo " static-site OK"

---

Printing tips

- Open `CHEAT_SHEET.md` in your editor and print-to-PDF or use `pandoc` to convert to PDF:
  pandoc CHEAT_SHEET.md -o CHEAT_SHEET.pdf

---

If you want, I can:
- Format this into a single-column printable PDF and commit it.
- Generate a condensed `cheat-sheet.txt` for easy terminal display.

Good luck on your defense — tell me if you want the PDF version committed next.
