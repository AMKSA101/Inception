#!/bin/bash
# Inception Project - Comprehensive Test Suite
# This script performs detailed testing of all services (mandatory + bonus)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Check if running from project root
if [ ! -f "srcs/docker-compose.yml" ]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

# Load environment variables
if [ -f "srcs/.env" ]; then
    set -a
    source srcs/.env
    set +a
else
    echo -e "${YELLOW}⚠️  .env file not found - some tests may fail${NC}"
fi

# Counters
total_tests=0
passed_tests=0
failed_tests=0

# Function to print section header
print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to run test
run_test() {
    local test_name=$1
    local test_cmd=$2
    
    ((total_tests++))
    echo -n "  Testing ${test_name}... "
    
    if eval "$test_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((passed_tests++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((failed_tests++))
        return 1
    fi
}

# Function to show command output
show_output() {
    local description=$1
    local command=$2
    
    echo -e "  ${BLUE}${description}:${NC}"
    eval "$command" 2>&1 | sed 's/^/    /'
    echo ""
}

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║     INCEPTION PROJECT - COMPREHENSIVE TEST SUITE           ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# MANDATORY SERVICES
# ============================================================================

print_header "1️⃣  NGINX TESTING (Mandatory)"

run_test "Container running" "docker ps | grep -q '^.*nginx'"
run_test "Configuration valid" "docker exec nginx nginx -t"
run_test "HTTPS responding" "curl -Iks --max-time 5 https://${DOMAIN_NAME} 2>&1 | head -1 | grep -qE 'HTTP.*[23][0-9][0-9]'"
run_test "SSL certificate exists" "docker exec nginx test -f /etc/ssl/certs/nginx-selfsigned.crt"
run_test "SSL key exists" "docker exec nginx test -f /etc/ssl/private/nginx-selfsigned.key"

show_output "SSL Certificate Details" "docker exec nginx openssl x509 -in /etc/ssl/certs/nginx-selfsigned.crt -noout -subject -issuer -dates 2>/dev/null | head -4"
show_output "TLS Protocol Configuration" "docker exec nginx grep 'ssl_protocols' /etc/nginx/sites-available/default 2>/dev/null | head -1"
show_output "FastCGI Configuration" "docker exec nginx grep 'fastcgi_pass' /etc/nginx/sites-available/default 2>/dev/null | head -1"

# ============================================================================

print_header "2️⃣  WORDPRESS TESTING (Mandatory)"

run_test "Container running" "docker ps | grep -q '^.*wordpress'"
run_test "PHP-FPM master process" "docker exec wordpress pgrep -f 'php-fpm: master'"
run_test "PHP-FPM worker processes" "docker exec wordpress pgrep -f 'php-fpm: pool www' | wc -l | grep -qE '[1-9]'"
run_test "WordPress files exist" "docker exec wordpress test -f /var/www/html/wp-config.php"
run_test "wp-content directory" "docker exec wordpress test -d /var/www/html/wp-content"
run_test "Database connection" "docker exec wordpress php -r 'exit(mysqli_connect(\"mariadb\", \"${MYSQL_USER}\", \"${MYSQL_PASSWORD}\", \"${MYSQL_DATABASE}\") ? 0 : 1);'"

show_output "PHP Version" "docker exec wordpress php -v | head -1"
show_output "WordPress Version" "docker exec wordpress wp core version --allow-root --path=/var/www/html 2>/dev/null || echo 'WP-CLI not available'"
show_output "WordPress Database Config" "docker exec wordpress grep \"^define.*DB_\" /var/www/html/wp-config.php 2>/dev/null | head -4"
show_output "File Permissions" "docker exec wordpress ls -lah /var/www/html/ | head -5"

# ============================================================================

print_header "3️⃣  MARIADB TESTING (Mandatory)"

run_test "Container running" "docker ps | grep -q '^.*mariadb'"
run_test "MySQL daemon responding" "docker exec mariadb mysqladmin ping --silent 2>/dev/null"
run_test "WordPress database exists" "! docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'USE ${MYSQL_DATABASE}' 2>&1 | grep -q ERROR"
run_test "WordPress tables exist" "docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} -e 'SHOW TABLES' 2>/dev/null | grep -q wp_posts"
run_test "WordPress users exist" "docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} wordpress -e 'SELECT COUNT(*) FROM wp_users' 2>/dev/null | grep -qE '[1-9]'"
run_test "Volume persistence" "test -d /home/joker/data/mariadb"

show_output "MariaDB Version" "docker exec mariadb mysql --version"
show_output "Databases List" "docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;' 2>/dev/null"
show_output "WordPress Tables" "docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} wordpress -e 'SHOW TABLES;' 2>/dev/null | head -10"
show_output "WordPress Users" "docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} wordpress -e 'SELECT user_login, user_email FROM wp_users;' 2>/dev/null"
show_output "Database Size" "docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = 'wordpress' GROUP BY table_schema;\" 2>/dev/null"

# ============================================================================
# BONUS SERVICES
# ============================================================================

print_header "4️⃣  REDIS TESTING (Bonus)"

run_test "Container running" "docker ps | grep -q '^.*redis'"
run_test "Redis responding (PING)" "docker exec redis redis-cli -a ${REDIS_PASSWORD} ping 2>/dev/null | grep -q PONG"
run_test "Authentication required" "docker exec redis redis-cli ping 2>&1 | grep -q NOAUTH"
run_test "SET command works" "docker exec redis redis-cli -a ${REDIS_PASSWORD} SET test_key 'test_value' 2>/dev/null | grep -q OK"
run_test "GET command works" "docker exec redis redis-cli -a ${REDIS_PASSWORD} GET test_key 2>/dev/null | grep -q test_value"

show_output "Redis Version" "docker exec redis redis-cli -a ${REDIS_PASSWORD} INFO server 2>/dev/null | grep redis_version"
show_output "Redis Memory Usage" "docker exec redis redis-cli -a ${REDIS_PASSWORD} INFO memory 2>/dev/null | grep -E 'used_memory_human|maxmemory_human|maxmemory_policy'"
show_output "Redis Database Size" "docker exec redis redis-cli -a ${REDIS_PASSWORD} DBSIZE 2>/dev/null"

# Clean up test key
docker exec redis redis-cli -a ${REDIS_PASSWORD} DEL test_key >/dev/null 2>&1

# ============================================================================

print_header "5️⃣  ADMINER TESTING (Bonus)"

run_test "Container running" "docker ps | grep -q '^.*adminer'"
run_test "PHP-FPM running" "docker exec adminer pgrep -f php-fpm"
run_test "Adminer file exists" "docker exec adminer test -f /var/www/adminer/index.php"
run_test "Can resolve MariaDB" "docker exec adminer getent hosts mariadb"
run_test "Database connection" "docker exec adminer php -r 'exit(mysqli_connect(\"mariadb\", \"${MYSQL_USER}\", \"${MYSQL_PASSWORD}\", \"${MYSQL_DATABASE}\") ? 0 : 1);'"

show_output "PHP Version" "docker exec adminer php -v | head -1"
show_output "Adminer File Size" "docker exec adminer ls -lh /var/www/adminer/index.php"

# ============================================================================

print_header "6️⃣  PORTAINER TESTING (Bonus)"

run_test "Container running" "docker ps | grep -q '^.*portainer'"
run_test "Portainer process running" "docker exec portainer pgrep portainer"
run_test "Docker socket accessible" "docker exec portainer test -S /var/run/docker.sock"
run_test "Data volume exists" "docker volume inspect srcs_portainer-data >/dev/null 2>&1"
run_test "Data directory exists" "docker exec portainer test -d /data"

show_output "Portainer Version" "docker exec portainer /portainer --version 2>/dev/null || echo 'Version command not available'"
show_output "Portainer Data Directory" "docker exec portainer ls -la /data | head -8"

# ============================================================================

print_header "7️⃣  FTP TESTING (Bonus)"

run_test "Container running" "docker ps | grep -q '^.*ftp'"
run_test "vsftpd process running" "docker exec ftp pgrep vsftpd"
run_test "Port 21 accessible" "timeout 2 nc -zv localhost 21 2>&1 | grep -q succeeded"
run_test "WordPress volume mounted" "docker exec ftp test -d /var/www/html"
run_test "Can list WordPress files" "docker exec ftp ls /var/www/html/wp-config.php >/dev/null 2>&1"

show_output "FTP Server Version" "timeout 2 curl -s telnet://localhost:21 2>&1 | grep -E '^220|vsFTPd' | head -1"
show_output "FTP User" "docker exec ftp grep ftpuser /etc/passwd 2>/dev/null || echo 'FTP user configured in startup script'"
show_output "WordPress Files via FTP" "docker exec ftp ls -lh /var/www/html/ | head -5"

# Test FTP login if lftp available (more reliable than ftp)
if command -v lftp >/dev/null 2>&1; then
    run_test "FTP login works" "timeout 5 lftp -u ${FTP_USER},${FTP_PASSWORD} -e 'quit' localhost 2>&1 | grep -qv 'Login failed'"
elif command -v curl >/dev/null 2>&1; then
    run_test "FTP login works" "timeout 5 curl -u ${FTP_USER}:${FTP_PASSWORD} ftp://localhost/ 2>&1 | grep -qv 'Login denied'"
else
    echo -e "  ${YELLOW}⚠️  FTP client not installed - manual verification: FTP is accessible on port 21${NC}"
    ((total_tests++))
fi

# ============================================================================

print_header "8️⃣  STATIC WEBSITE TESTING (Bonus)"

run_test "Container running" "docker ps | grep -q '^.*static-website'"
run_test "HTML file exists" "docker exec static-website test -f /var/www/static-site/index.html"
run_test "CSS file exists" "docker exec static-website test -f /var/www/static-site/styles.css"
run_test "JS file exists" "docker exec static-website test -f /var/www/static-site/script.js"

show_output "Static Files" "docker exec static-website ls -lh /var/www/static-site/"
show_output "HTML Preview" "docker exec static-website head -15 /var/www/static-site/index.html"

# ============================================================================
# VOLUME TESTS
# ============================================================================

print_header "💾 VOLUME PERSISTENCE TESTING"

run_test "mariadb-data volume" "docker volume inspect srcs_mariadb-data >/dev/null 2>&1"
run_test "wordpress-data volume" "docker volume inspect srcs_wordpress-data >/dev/null 2>&1"
run_test "static-site-data volume" "docker volume inspect srcs_static-site-data >/dev/null 2>&1"
run_test "adminer-data volume" "docker volume inspect srcs_adminer-data >/dev/null 2>&1"
run_test "portainer-data volume" "docker volume inspect srcs_portainer-data >/dev/null 2>&1"

show_output "All Volumes" "docker volume ls | grep srcs_"

# Test persistence
echo -e "  ${BLUE}Testing volume persistence:${NC}"
TEST_FILE="inception_test_$(date +%s).txt"
docker exec wordpress bash -c "echo 'Persistence Test' > /var/www/html/${TEST_FILE}" 2>/dev/null
if docker exec wordpress test -f /var/www/html/${TEST_FILE} 2>/dev/null; then
    echo -e "    ${GREEN}✓ Test file created successfully${NC}"
    docker exec wordpress rm /var/www/html/${TEST_FILE} 2>/dev/null
    echo -e "    ${GREEN}✓ Test file cleaned up${NC}"
else
    echo -e "    ${RED}✗ Failed to create test file${NC}"
fi
echo ""

# ============================================================================
# NETWORK TESTS
# ============================================================================

print_header "🌐 NETWORK CONNECTIVITY TESTING"

run_test "inception-network exists" "docker network inspect srcs_inception-network >/dev/null 2>&1"
run_test "WordPress → MariaDB DNS" "docker exec wordpress getent hosts mariadb"
run_test "WordPress → Redis DNS" "docker exec wordpress getent hosts redis"
run_test "WordPress → MariaDB port" "docker exec wordpress timeout 2 bash -c 'cat < /dev/null > /dev/tcp/mariadb/3306' 2>/dev/null"
run_test "WordPress → Redis port" "docker exec wordpress timeout 2 bash -c 'cat < /dev/null > /dev/tcp/redis/6379' 2>/dev/null"
run_test "Adminer → MariaDB DNS" "docker exec adminer getent hosts mariadb"
run_test "FTP → WordPress volume" "docker exec ftp test -f /var/www/html/wp-config.php"

show_output "Network Details" "docker network inspect srcs_inception-network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{println}}{{end}}'"

# ============================================================================
# SECURITY TESTS
# ============================================================================

print_header "🔒 SECURITY TESTING"

run_test "Redis requires password" "docker exec redis redis-cli ping 2>&1 | grep -q NOAUTH"
run_test "MariaDB port not exposed to internet" "! docker port mariadb 2>&1 | grep -q '0.0.0.0:3306'"
run_test "Redis port not exposed to internet" "! docker port redis 2>&1 | grep -q '0.0.0.0:6379'"
run_test "HTTPS port exposed" "docker port nginx | grep -q '443'"
run_test "TLS 1.2/1.3 configured" "docker exec nginx grep -E 'TLSv1\.[23]' /etc/nginx/sites-available/default >/dev/null 2>&1"

echo -e "  ${BLUE}Security Notes:${NC}"
echo -e "    ${YELLOW}⚠️  FTP transmits credentials in plaintext (expected for bonus)${NC}"
echo -e "    ${YELLOW}⚠️  Self-signed SSL certificate (expected for development)${NC}"
echo -e "    ${YELLOW}⚠️  Portainer has Docker socket access (root privileges)${NC}"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================

print_header "📊 TEST SUMMARY"

echo ""
percentage=$((passed_tests * 100 / total_tests))

echo -e "  ${BOLD}Total Tests:${NC}  ${total_tests}"
echo -e "  ${GREEN}${BOLD}Passed:${NC}      ${GREEN}${passed_tests}${NC}"
if [ $failed_tests -gt 0 ]; then
    echo -e "  ${RED}${BOLD}Failed:${NC}      ${RED}${failed_tests}${NC}"
fi
echo -e "  ${BOLD}Success Rate:${NC} ${percentage}%"
echo ""

if [ $failed_tests -eq 0 ]; then
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║  ✅ ALL TESTS PASSED! YOUR PROJECT IS READY FOR DEFENSE!  ║${NC}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
elif [ $percentage -ge 90 ]; then
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║  ⚠️  MOSTLY PASSING - CHECK FAILED TESTS ABOVE            ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
else
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${RED}║  ❌ MULTIPLE FAILURES - REVIEW LOGS ABOVE                  ║${NC}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
