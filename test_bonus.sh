#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   INCEPTION BONUS SERVICES VERIFICATION TESTS  ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo ""

# Function to print test results
print_test() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Test 1: Redis Cache
echo -e "${YELLOW}[1/6] Testing Redis Cache...${NC}"
docker exec redis redis-cli ping > /dev/null 2>&1
print_test $? "Redis server is responding"

redis_keys=$(docker exec redis redis-cli DBSIZE 2>/dev/null | grep -o '[0-9]*')
echo -e "    → Redis has ${redis_keys} keys in database"

docker exec wordpress php -r "if (extension_loaded('redis')) { exit(0); } else { exit(1); }" 2>/dev/null
print_test $? "Redis PHP extension is installed in WordPress"

echo ""

# Test 2: FTP Server
echo -e "${YELLOW}[2/6] Testing FTP Server...${NC}"
docker exec ftp ps aux | grep -q vsftpd
print_test $? "vsftpd service is running"

docker exec ftp cat /etc/vsftpd.conf | grep -q "pasv_enable=YES"
print_test $? "FTP passive mode is configured"

docker exec ftp ls -la /var/www/wordpress > /dev/null 2>&1
print_test $? "FTP has access to WordPress volume"

ftp_user=$(docker exec ftp cat /etc/vsftpd.userlist 2>/dev/null | head -1)
if [ -n "$ftp_user" ]; then
    echo -e "    → FTP username: ${ftp_user}"
fi

echo ""

# Test 3: Adminer
echo -e "${YELLOW}[3/6] Testing Adminer...${NC}"
curl -s http://localhost:8080 | grep -q "Adminer"
print_test $? "Adminer web interface is accessible"

docker exec adminer ps aux | grep -q php
print_test $? "PHP-FPM service is running in Adminer"

echo -e "    → Access at: ${BLUE}http://localhost:8080${NC}"
echo -e "    → Use MariaDB credentials to login"

echo ""

# Test 4: Static Website
echo -e "${YELLOW}[4/6] Testing Static Website...${NC}"
curl -s http://localhost:8081 > /dev/null 2>&1
print_test $? "Static website is accessible"

curl -s http://localhost:8081 | grep -q "<!DOCTYPE html>"
print_test $? "Website returns valid HTML"

website_lang=$(docker exec website ls -la /usr/share/nginx/html/*.html 2>/dev/null | wc -l)
if [ $website_lang -gt 0 ]; then
    echo -e "    → Static HTML website detected"
fi

echo -e "    → Access at: ${BLUE}http://localhost:8081${NC}"

echo ""

# Test 5: Portainer
echo -e "${YELLOW}[5/6] Testing Portainer...${NC}"
portainer_status=$(docker inspect portainer --format='{{.State.Status}}' 2>/dev/null)
if [ "$portainer_status" = "running" ]; then
    print_test 0 "Portainer container is running"
    curl -s http://localhost:9443 > /dev/null 2>&1
    print_test $? "Portainer web interface is accessible"
    echo -e "    → Access at: ${BLUE}http://localhost:9443${NC}"
else
    print_test 1 "Portainer container is $portainer_status"
    echo -e "    ${RED}→ Check logs: docker logs portainer${NC}"
fi

echo ""

# Test 6: Container Status
echo -e "${YELLOW}[6/6] Testing All Containers Status...${NC}"
containers=("nginx" "wordpress" "mariadb" "redis" "ftp" "adminer" "website" "portainer")
for container in "${containers[@]}"; do
    status=$(docker inspect $container --format='{{.State.Status}}' 2>/dev/null)
    if [ "$status" = "running" ]; then
        print_test 0 "$container is running"
    else
        print_test 1 "$container is $status"
    fi
done

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              MANUAL VERIFICATION STEPS         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}1. WordPress with Redis Cache:${NC}"
echo -e "   • Access your WordPress admin panel"
echo -e "   • Install 'Redis Object Cache' plugin (if not already installed)"
echo -e "   • Go to Settings → Redis and verify connection"
echo ""

echo -e "${GREEN}2. FTP Server:${NC}"
echo -e "   • Connect using FTP client: ${BLUE}ftp localhost 21${NC}"
echo -e "   • Or use FileZilla/WinSCP with passive mode"
echo -e "   • Verify you can see WordPress files"
echo ""

echo -e "${GREEN}3. Adminer:${NC}"
echo -e "   • Open: ${BLUE}http://localhost:8080${NC}"
echo -e "   • Login with:"
echo -e "     - System: MySQL"
echo -e "     - Server: mariadb"
echo -e "     - Username: your_db_user"
echo -e "     - Password: your_db_password"
echo -e "     - Database: your_db_name"
echo ""

echo -e "${GREEN}4. Static Website:${NC}"
echo -e "   • Open: ${BLUE}http://localhost:8081${NC}"
echo -e "   • Verify it's not PHP (should be HTML/JS/CSS)"
echo ""

echo -e "${GREEN}5. Portainer (5th bonus service):${NC}"
echo -e "   • Open: ${BLUE}http://localhost:9443${NC}"
echo -e "   • Create admin account on first visit"
echo -e "   • Manage Docker containers through web UI"
echo ""

echo -e "${YELLOW}Quick Access URLs:${NC}"
echo -e "   • Main site:     ${BLUE}https://localhost${NC}"
echo -e "   • Adminer:       ${BLUE}http://localhost:8080${NC}"
echo -e "   • Static site:   ${BLUE}http://localhost:8081${NC}"
echo -e "   • Portainer:     ${BLUE}http://localhost:9000${NC}"
echo ""
