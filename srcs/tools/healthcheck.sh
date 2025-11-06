#!/bin/bash
# Inception Project Health Check Script
# Tests all services and displays status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 INCEPTION PROJECT - HEALTH CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running from project root
if [ ! -f "srcs/docker-compose.yml" ]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

# Load environment variables if .env exists
if [ -f "srcs/.env" ]; then
    set -a
    source srcs/.env
    set +a
else
    echo -e "${YELLOW}⚠️  .env file not found - some tests may fail${NC}"
fi

# Function to check if container is running
check_container() {
    local container=$1
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "${GREEN}✓${NC} $container is running"
        return 0
    else
        echo -e "${RED}✗${NC} $container is NOT running"
        return 1
    fi
}

# Function to run test and display result
run_test() {
    local test_name=$1
    local test_cmd=$2
    
    echo -n "Testing ${test_name}... "
    if eval "$test_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Counter for passed tests
passed=0
total=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 CONTAINER STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

containers=("nginx" "wordpress" "mariadb" "redis" "adminer" "portainer" "ftp" "static-website")
for container in "${containers[@]}"; do
    ((total++))
    if check_container "$container"; then
        ((passed++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 SERVICE TESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test Nginx HTTPS (using -k to ignore self-signed certificate)
((total++))
if run_test "Nginx HTTPS" "curl -Iks --max-time 5 https://${DOMAIN_NAME} 2>&1 | head -1 | grep -qE 'HTTP.*[23][0-9][0-9]'"; then
    ((passed++))
fi

# Test Nginx config
((total++))
if run_test "Nginx configuration" "docker exec nginx nginx -t"; then
    ((passed++))
fi

# Test MariaDB
((total++))
if run_test "MariaDB connection" "docker exec mariadb mysqladmin ping -u root -p${MYSQL_ROOT_PASSWORD} --silent"; then
    ((passed++))
fi

# Test MariaDB database exists
((total++))
if run_test "WordPress database" "docker exec mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'USE wordpress' 2>&1"; then
    ((passed++))
fi

# Test Redis
((total++))
if run_test "Redis connection" "docker exec redis redis-cli -a ${REDIS_PASSWORD} ping 2>&1 | grep -q PONG"; then
    ((passed++))
fi

# Test WordPress files
((total++))
if run_test "WordPress installation" "docker exec wordpress test -f /var/www/html/wp-config.php"; then
    ((passed++))
fi

# Test PHP-FPM
((total++))
if run_test "PHP-FPM process" "docker exec wordpress pgrep php-fpm"; then
    ((passed++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 VOLUME CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check volumes exist
volumes=("mariadb-data" "wordpress-data" "static-site-data" "adminer-data" "portainer-data")
for volume in "${volumes[@]}"; do
    ((total++))
    if run_test "Volume ${volume}" "docker volume inspect srcs_${volume}"; then
        ((passed++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 NETWORK CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check network exists
((total++))
if run_test "inception-network" "docker network inspect srcs_inception-network"; then
    ((passed++))
fi

# Test container connectivity (using DNS resolution instead of ping)
((total++))
if run_test "WordPress → MariaDB DNS" "docker exec wordpress getent hosts mariadb"; then
    ((passed++))
fi

((total++))
if run_test "WordPress → Redis DNS" "docker exec wordpress getent hosts redis"; then
    ((passed++))
fi

# Test actual service connectivity (better than ping)
((total++))
if run_test "WordPress → MariaDB port" "docker exec wordpress timeout 2 bash -c 'cat < /dev/null > /dev/tcp/mariadb/3306'"; then
    ((passed++))
fi

((total++))
if run_test "WordPress → Redis port" "docker exec wordpress timeout 2 bash -c 'cat < /dev/null > /dev/tcp/redis/6379'"; then
    ((passed++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

percentage=$((passed * 100 / total))

if [ $passed -eq $total ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED!${NC}"
    echo -e "Score: ${GREEN}${passed}/${total}${NC} (${percentage}%)"
    echo ""
    echo "🎉 Your Inception project is fully operational!"
    exit 0
elif [ $percentage -ge 75 ]; then
    echo -e "${YELLOW}⚠️  MOSTLY WORKING${NC}"
    echo -e "Score: ${YELLOW}${passed}/${total}${NC} (${percentage}%)"
    echo ""
    echo "Some tests failed. Check logs: docker-compose logs -f"
    exit 1
else
    echo -e "${RED}❌ MULTIPLE FAILURES${NC}"
    echo -e "Score: ${RED}${passed}/${total}${NC} (${percentage}%)"
    echo ""
    echo "Critical issues detected. Run: make logs"
    exit 1
fi
