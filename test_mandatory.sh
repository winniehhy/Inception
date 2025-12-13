#!/bin/bash

# ============================================
# INCEPTION - MANDATORY PART TEST SCRIPT
# ============================================
# This script automates most checks from the evaluation sheet
# for the mandatory part of the Inception project.
#
# Usage: ./test_mandatory.sh
#
# Note: Some checks still require manual verification:
# - Visual inspection of WordPress site
# - Admin login and page editing
# - Persistence after reboot
# - Student explanations
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Test results tracking (0 = pass, 1 = fail)
declare -A TEST_RESULTS

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print test results and track them
print_test() {
    local status=$1
    local message=$2
    local key=$3
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
    
    # Store result if key provided
    if [ -n "$key" ]; then
        TEST_RESULTS["$key"]=$status
    fi
}

# Function to print checklist item
print_checklist() {
    local key=$1
    local message=$2
    
    if [ "${TEST_RESULTS[$key]:-1}" -eq 0 ]; then
        echo -e "[${GREEN}✓${NC}] $message"
    else
        echo -e "[${RED} ${NC}] $message"
    fi
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print info
print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_header "INCEPTION - MANDATORY PART TEST SCRIPT"

# Check if running from project root
if [ ! -f "Makefile" ] || [ ! -d "srcs" ]; then
    echo -e "${RED}ERROR: Please run this script from the project root directory!${NC}"
    echo -e "${YELLOW}The script expects to find:${NC}"
    echo -e "  - Makefile (in current directory)"
    echo -e "  - srcs/ folder (in current directory)"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  This script will verify the mandatory requirements${NC}"
echo -e "${CYAN}  Running from: $(pwd)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}EVALUATOR: Before starting, run cleanup command:${NC}"
echo -e "${GREEN}docker stop \$(docker ps -qa); docker rm \$(docker ps -qa); docker rmi -f \$(docker images -qa); docker volume rm \$(docker volume ls -q); docker network rm \$(docker network ls -q) 2>/dev/null${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -p "Have you run the cleanup command? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Please run the cleanup command first!${NC}"
    echo -e "${YELLOW}Press Enter when ready to continue...${NC}"
    read
fi

echo -e "\n${YELLOW}Building and starting containers with 'make'...${NC}"
echo -e "${YELLOW}(This may take several minutes on first build)${NC}\n"

# Run make to build and start containers
make

echo -e "\n${YELLOW}Waiting for containers to be fully ready...${NC}"
sleep 10

# ============================================
# 0. CREDENTIAL SECURITY CHECK
# ============================================
print_header "0. CREDENTIAL SECURITY CHECK (CRITICAL)"

echo -e "${YELLOW}Scanning for exposed credentials in git-tracked files...${NC}"
CREDENTIAL_LEAK=0

# Check if git repo exists
if [ -d ".git" ]; then
    # Check for passwords/secrets in tracked files (excluding .env which should be in .gitignore)
    echo -e "  Checking for hardcoded credentials in tracked files..."
    
    # Common credential patterns
    PATTERNS=(
        "password.*=.*['\"].*['\"]"
        "PASSWORD.*=.*['\"].*['\"]"
        "secret.*=.*['\"].*['\"]"
        "SECRET.*=.*['\"].*['\"]"
        "mysql_root_password"
        "db_password"
        "wp_password"
    )
    
    for pattern in "${PATTERNS[@]}"; do
        FOUND=$(git grep -i "$pattern" 2>/dev/null | grep -v ".env" | grep -v "test_mandatory.sh" | grep -v ".gitignore" || true)
        if [ -n "$FOUND" ]; then
            # Check if it's actually reading from secrets or using environment variables (which is OK)
            if echo "$FOUND" | grep -qE "cat.*secrets|/run/secrets|_FILE:|_password\)|\$\{[A-Z_]+\}|\"\$\{[A-Z_]+\}\""; then
                continue  # This is OK - using Docker secrets or environment variables properly
            fi
            print_test 1 "CRITICAL: Hardcoded credential found"
            echo -e "  ${RED}$FOUND${NC}"
            CREDENTIAL_LEAK=1
        fi
    done
    
    # Check if .env is tracked
    if git ls-files --error-unmatch srcs/.env 2>/dev/null; then
        print_test 1 "CRITICAL: .env file is tracked by git!" "env_not_tracked"
        CREDENTIAL_LEAK=1
    else
        print_test 0 ".env file is NOT tracked by git (good)" "env_not_tracked"
    fi
    
    # Note: Project uses .env for credentials (checked above)
    # If using separate secrets folder, ensure it's in .gitignore
    if [ -d "secrets" ] && git ls-files secrets/*.txt 2>/dev/null | grep -q ".txt"; then
        print_test 1 "WARNING: Secret files are tracked by git"
        CREDENTIAL_LEAK=1
    fi
    
    if [ $CREDENTIAL_LEAK -eq 0 ]; then
        print_test 0 "No obvious credential leaks detected" "no_cred_leak"
    else
        TEST_RESULTS["no_cred_leak"]=1
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}⚠  CRITICAL: Credentials found in repository!${NC}"
        echo -e "${RED}⚠  This will result in immediate project failure!${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    fi
else
    echo -e "  ${YELLOW}Not a git repository - skipping git checks${NC}"
fi

# ============================================
# 1. PRELIMINARY CHECKS
# ============================================
print_header "1. PRELIMINARY CHECKS"

echo -e "${YELLOW}Checking for .env file...${NC}"
if [ -f "srcs/.env" ]; then
    print_test 0 ".env file exists in srcs/" "env_exists"
    echo -e "  ${YELLOW}→ Make sure all credentials are ONLY in .env file${NC}"
else
    print_test 1 ".env file NOT found in srcs/" "env_exists"
fi

echo -e "\n${YELLOW}Checking directory structure...${NC}"
if [ -d "srcs" ]; then
    print_test 0 "srcs/ folder exists at root" "srcs_exists"
else
    print_test 1 "srcs/ folder NOT found" "srcs_exists"
fi

if [ -f "Makefile" ]; then
    print_test 0 "Makefile exists at root" "makefile_exists"
    
    echo -e "\n${YELLOW}Checking Makefile contents...${NC}"
    if grep -q "docker.*compose.*build\|docker-compose.*build\|docker.*compose.*up" Makefile; then
        print_test 0 "Makefile contains docker compose commands" "makefile_compose"
    else
        echo -e "  ${YELLOW}→ Verify Makefile builds Docker images using docker compose${NC}"
    fi
    
    if grep -q "\-\-link" Makefile; then
        print_test 1 "FORBIDDEN: '--link' found in Makefile"
    else
        print_test 0 "No '--link' in Makefile (good)"
    fi
else
    print_test 1 "Makefile NOT found"
fi

echo -e "\n${YELLOW}Checking docker-compose.yml...${NC}"
if [ -f "srcs/docker-compose.yml" ] || [ -f "srcs/docker-compose.yaml" ]; then
    COMPOSE_FILE=$(find srcs -name "docker-compose.y*ml" -type f | head -1)
    print_test 0 "docker-compose file found"
    
    # Check for prohibited 'network: host'
    if grep -q "network:.*host" "$COMPOSE_FILE"; then
        print_test 1 "FORBIDDEN: 'network: host' found in docker-compose"
    else
        print_test 0 "No 'network: host' found (good)"
    fi
    
    # Check for prohibited 'links:'
    if grep -q "links:" "$COMPOSE_FILE"; then
        print_test 1 "FORBIDDEN: 'links:' found in docker-compose"
    else
        print_test 0 "No 'links:' found (good)"
    fi
    
    # Check for required 'networks:'
    if grep -q "networks:" "$COMPOSE_FILE"; then
        print_test 0 "networks: declaration found (required)" "has_networks"
    else
        print_test 1 "MISSING: 'networks:' not found in docker-compose" "has_networks"
    fi
else
    print_test 1 "docker-compose file NOT found"
fi

echo -e "\n${YELLOW}Checking for prohibited --link in Dockerfiles and scripts...${NC}"
LINK_FOUND=0
if find srcs -type f \( -name "Dockerfile*" -o -name "*.sh" \) -exec grep -l "\-\-link" {} \; 2>/dev/null | grep -q .; then
    print_test 1 "FORBIDDEN: '--link' found in project files"
    find srcs -type f \( -name "Dockerfile*" -o -name "*.sh" \) -exec grep -l "\-\-link" {} \; 2>/dev/null
else
    print_test 0 "No '--link' found in project files (good)"
fi

echo -e "\n${YELLOW}Checking Dockerfiles for prohibited commands...${NC}"
BAD_DOCKERFILE=0
for dockerfile in $(find srcs/requirements -name "Dockerfile*" -type f); do
    echo "  Checking: $dockerfile"
    
    # Check for tail -f or background processes in ENTRYPOINT
    if grep -E "ENTRYPOINT.*tail -f|ENTRYPOINT.*&.*bash|ENTRYPOINT.*&.*sh" "$dockerfile" > /dev/null; then
        print_test 1 "FORBIDDEN: Background process or tail -f in ENTRYPOINT in $dockerfile"
        BAD_DOCKERFILE=1
    else
        print_test 0 "No tail -f or background process in ENTRYPOINT"
    fi
    
    # Check for prohibited 'latest' tag
    if grep -E "FROM.*:latest" "$dockerfile" > /dev/null; then
        print_test 1 "FORBIDDEN: 'latest' tag found in $dockerfile"
        BAD_DOCKERFILE=1
    else
        print_test 0 "No 'latest' tag (good)"
    fi
    
    # Check for Alpine or Debian base
    if grep -E "^FROM (alpine|debian):" "$dockerfile" > /dev/null; then
        VERSION=$(grep -E "^FROM (alpine|debian):" "$dockerfile" | head -1)
        print_test 0 "Uses Alpine or Debian base: $VERSION"
        
        # Check if it's versioned (not latest)
        if echo "$VERSION" | grep -qE "alpine:[0-9]|debian:[0-9]|debian:bullseye|debian:bookworm"; then
            print_test 0 "Base image is properly versioned"
        else
            echo -e "  ${YELLOW}→ Verify this is the penultimate stable version${NC}"
        fi
    else
        BASE_IMAGE=$(grep -E "^FROM" "$dockerfile" | head -1)
        echo -e "  ${YELLOW}→ Base image: $BASE_IMAGE${NC}"
        echo -e "  ${YELLOW}→ Verify this is a local image or penultimate Alpine/Debian${NC}"
    fi
    
    # Check for entrypoint scripts with infinite loops
    ENTRYPOINT_SCRIPT=$(grep -E "ENTRYPOINT.*\.sh" "$dockerfile" | sed -E 's/.*ENTRYPOINT[^"]*"([^"]+)".*/\1/' | head -1)
    if [ -n "$ENTRYPOINT_SCRIPT" ]; then
        echo -e "  ${YELLOW}→ Entrypoint script detected: $ENTRYPOINT_SCRIPT${NC}"
        echo -e "  ${YELLOW}→ Verify it doesn't run programs in background (e.g., 'nginx & bash')${NC}"
    fi
    
    echo ""
done

echo -e "\n${YELLOW}Checking for infinite loops in scripts...${NC}"
INFINITE_LOOP=0
for script in $(find srcs -name "*.sh"); do
    if grep -E "sleep infinity|tail -f /dev/null|tail -f /dev/random|while true.*do" "$script" > /dev/null; then
        print_test 1 "WARNING: Possible infinite loop in $script"
        INFINITE_LOOP=1
    fi
done
if [ $INFINITE_LOOP -eq 0 ]; then
    print_test 0 "No obvious infinite loops found"
fi

# ============================================
# 2. DOCKER BASICS
# ============================================
print_header "2. DOCKER BASICS"

echo -e "${YELLOW}Checking Dockerfiles for each service...${NC}"
DOCKERFILES=(
    "srcs/requirements/nginx/Dockerfile"
    "srcs/requirements/wordpress/Dockerfile"
    "srcs/requirements/mariadb/Dockerfile"
)

for df in "${DOCKERFILES[@]}"; do
    if [ -f "$df" ] && [ -s "$df" ]; then
        print_test 0 "$df exists and is not empty"
    else
        print_test 1 "$df missing or empty"
    fi
done

echo -e "\n${YELLOW}Verifying custom Dockerfiles (not using DockerHub ready-made images)...${NC}"
echo -e "  ${YELLOW}→ Evaluator should ask how images were built${NC}"
echo -e "  ${YELLOW}→ Student must have written their own Dockerfiles${NC}"
echo -e "  ${YELLOW}→ Cannot use ready-made Docker images from DockerHub${NC}"

echo -e "\n${YELLOW}Checking Docker images...${NC}"
echo -e "Running: docker images\n"
docker images

echo -e "\n${YELLOW}Verifying image names match service names...${NC}"
EXPECTED_IMAGES=("nginx" "wordpress" "mariadb")
for img in "${EXPECTED_IMAGES[@]}"; do
    if docker images --format '{{.Repository}}' | grep -qi "^${img}$\|/${img}$\|inception.*${img}\|${img}.*inception\|srcs.*${img}\|${img}.*srcs"; then
        IMG_NAME=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -i "${img}" | head -1)
        print_test 0 "Image for $img service found: $IMG_NAME"
        
        # Check if it's NOT from DockerHub official repo (shouldn't be pulling nginx:latest etc)
        if docker images --format '{{.Repository}}' | grep -q "^${img}$" && ! docker images --format '{{.Repository}}' | grep -q "/"; then
            # Could be official image - need to check build context
            echo -e "  ${YELLOW}→ EVALUATOR: Verify this was built from Dockerfile (not pulled from DockerHub)${NC}"
        fi
    else
        print_test 1 "Image for $img service NOT found or incorrectly named"
        echo -e "  ${YELLOW}→ Image name should match or include service name${NC}"
    fi
done

echo -e "\n${YELLOW}Checking for forbidden DockerHub pulls...${NC}"
# Check if student pulled ready-made images
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -qE "^nginx:[0-9]|^wordpress:[0-9]|^mariadb:[0-9]|^mysql:[0-9]"; then
    print_warning "Found official images that may indicate pulling instead of building"
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "^nginx:|^wordpress:|^mariadb:|^mysql:" || true
    echo -e "  ${YELLOW}→ CRITICAL: Ask student if they pulled these or built them${NC}"
    echo -e "  ${YELLOW}→ They should have built from Alpine/Debian base, NOT these${NC}"
else
    print_test 0 "No obvious DockerHub official images found (good)"
fi

echo -e "\n${YELLOW}Running: docker compose ps${NC}"
docker compose -f srcs/docker-compose.yml ps

echo -e "\n${YELLOW}Checking container status...${NC}"
CONTAINERS=("nginx" "wordpress" "mariadb")
for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -qi "${container}"; then
        FULL_NAME=$(docker ps --format '{{.Names}}' | grep -i "${container}" | head -1)
        STATUS=$(docker ps --filter "name=${container}" --format '{{.Status}}' | head -1)
        print_test 0 "$container is running - $STATUS" "${container}_running"
        
        # Check for restart policy
        RESTART_POLICY=$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$FULL_NAME" 2>/dev/null)
        if [[ "$RESTART_POLICY" == "always" ]] || [[ "$RESTART_POLICY" == "unless-stopped" ]]; then
            print_test 0 "  Restart policy: $RESTART_POLICY (containers will auto-restart)"
        else
            echo -e "  ${YELLOW}→ Restart policy: $RESTART_POLICY (verify auto-restart is configured)${NC}"
        fi
    else
        print_test 1 "$container is NOT running" "${container}_running"
    fi
done

# ============================================
# 3. DOCKER NETWORK
# ============================================
print_header "3. DOCKER NETWORK"

echo -e "${YELLOW}Listing all Docker networks...${NC}"
docker network ls

echo -e "\n${YELLOW}Verifying project network configuration...${NC}"
NETWORK_NAME=$(grep -A 10 "^networks:" srcs/docker-compose.y*ml 2>/dev/null | grep -v "^networks:" | grep ":" | head -1 | awk '{print $1}' | tr -d ':')
if [ -n "$NETWORK_NAME" ]; then
    # Docker Compose prefixes network name with project name
    FULL_NETWORK=$(docker network ls --format '{{.Name}}' | grep -i "${NETWORK_NAME}" | head -1)
    if [ -n "$FULL_NETWORK" ]; then
        print_test 0 "Network '$NETWORK_NAME' exists (as $FULL_NETWORK)" "network_exists"
        
        # Inspect the network
        echo -e "\n  ${YELLOW}Network details:${NC}"
        docker network inspect "$NETWORK_NAME" --format '  Driver: {{.Driver}}' 2>/dev/null
        docker network inspect "$NETWORK_NAME" --format '  Scope: {{.Scope}}' 2>/dev/null
        
        # Check which containers are connected
        echo -e "\n  ${YELLOW}Containers connected to this network:${NC}"
        CONNECTED=$(docker network inspect "$FULL_NETWORK" --format '{{range .Containers}}  - {{.Name}}{{"\n"}}{{end}}' 2>/dev/null)
        if [ -n "$CONNECTED" ]; then
            echo "$CONNECTED"
            NUM_CONTAINERS=$(echo "$CONNECTED" | grep -c "-")
            print_test 0 "$NUM_CONTAINERS containers connected to docker-network"
        else
            print_test 1 "No containers connected to network"
        fi
    else
        print_test 1 "Network '$NETWORK_NAME' not found in docker network ls" "network_exists"
    fi
else
    print_test 1 "Could not extract network name from docker-compose.yml"
    echo -e "  ${YELLOW}→ Manually verify networks: section exists in docker-compose.yml${NC}"
fi

echo -e "\n${YELLOW}Student should explain docker-network in simple terms${NC}"

# ============================================
# 4. NGINX WITH SSL/TLS
# ============================================
print_header "4. NGINX WITH SSL/TLS"

echo -e "${YELLOW}Checking NGINX Dockerfile...${NC}"
if [ -f "srcs/requirements/nginx/Dockerfile" ]; then
    print_test 0 "NGINX Dockerfile exists"
fi

echo -e "\n${YELLOW}Testing HTTP (port 80) - Should FAIL or REDIRECT...${NC}"
# Extract domain name (first word only, in case of multiple domains)
DOMAIN_FULL=$(grep "DOMAIN_NAME" srcs/.env 2>/dev/null | cut -d'=' -f2 || echo "localhost")
DOMAIN=$(echo "$DOMAIN_FULL" | awk '{print $1}')
echo "  Testing HTTP on localhost:80..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://localhost:80" 2>/dev/null)
# If curl fails or returns empty, set to 000
if [ -z "$HTTP_RESPONSE" ]; then
    HTTP_RESPONSE="000"
fi
if [ "$HTTP_RESPONSE" = "000" ] || [ "$HTTP_RESPONSE" = "7" ]; then
    print_test 0 "HTTP port 80 correctly blocked/not accessible (Connection refused - good)"
elif [ "$HTTP_RESPONSE" = "301" ] || [ "$HTTP_RESPONSE" = "302" ]; then
    print_test 0 "HTTP redirects to HTTPS (status: $HTTP_RESPONSE)"
else
    print_test 1 "HTTP port 80 accessible (status: $HTTP_RESPONSE) - Should be blocked!"
fi

echo -e "\n${YELLOW}Testing HTTPS (port 443)...${NC}"
echo "  Testing HTTPS on localhost:443..."
HTTPS_RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://localhost:443" 2>/dev/null)
# If curl fails or returns empty, set to FAILED
if [ -z "$HTTPS_RESPONSE" ]; then
    HTTPS_RESPONSE="FAILED"
fi
if [ "$HTTPS_RESPONSE" = "200" ] || [ "$HTTPS_RESPONSE" = "301" ] || [ "$HTTPS_RESPONSE" = "302" ]; then
    print_test 0 "HTTPS port 443 accessible (status: $HTTPS_RESPONSE)" "https_accessible"
    echo -e "  ${GREEN}✓ Domain: $DOMAIN (ensure it resolves to localhost in /etc/hosts)${NC}"
else
    print_test 1 "HTTPS port 443 NOT accessible (status: $HTTPS_RESPONSE)" "https_accessible"
fi

echo -e "\n${YELLOW}Checking SSL/TLS certificate...${NC}"
if docker exec nginx ls /etc/nginx/ssl/ 2>/dev/null | grep -q ".crt\|.pem"; then
    print_test 0 "SSL certificate files found in /etc/nginx/ssl/" "ssl_cert"
    echo -e "  ${YELLOW}→ Certificate details:${NC}"
    docker exec nginx ls -la /etc/nginx/ssl/ 2>/dev/null | grep -E ".crt|.pem|.key"
elif docker exec nginx find /etc/ssl -name "*.crt" -o -name "*.pem" 2>/dev/null | grep -q "."; then
    print_test 0 "SSL certificate files found" "ssl_cert"
    echo -e "  ${YELLOW}→ Certificate location:${NC}"
    docker exec nginx find /etc/ssl -name "*.crt" -o -name "*.key" 2>/dev/null | head -5
else
    print_test 1 "SSL certificate files NOT found" "ssl_cert"
fi

echo -e "\n${YELLOW}Testing TLS version...${NC}"
TLS_VERSION=$(echo | openssl s_client -connect localhost:443 2>/dev/null | grep "Protocol" | awk '{print $3}')
if [[ "$TLS_VERSION" == "TLSv1.2" ]] || [[ "$TLS_VERSION" == "TLSv1.3" ]]; then
    print_test 0 "TLS version: $TLS_VERSION (acceptable)"
else
    echo -e "  ${YELLOW}TLS version: $TLS_VERSION (verify it's TLSv1.2 or TLSv1.3)${NC}"
fi

# ============================================
# 5. WORDPRESS WITH PHP-FPM
# ============================================
print_header "5. WORDPRESS WITH PHP-FPM"

echo -e "${YELLOW}Checking WordPress Dockerfile...${NC}"
if [ -f "srcs/requirements/wordpress/Dockerfile" ]; then
    print_test 0 "WordPress Dockerfile exists"
    
    # Check for actual nginx installation (not just comments)
    if grep -E "^[^#]*apt.*nginx|^[^#]*apk.*nginx|^FROM.*nginx" "srcs/requirements/wordpress/Dockerfile" > /dev/null; then
        print_test 1 "FORBIDDEN: NGINX installation found in WordPress Dockerfile"
    else
        print_test 0 "No NGINX installation in WordPress Dockerfile (good)"
    fi
    
    if grep -qi "php-fpm\|php.*fpm" "srcs/requirements/wordpress/Dockerfile"; then
        print_test 0 "PHP-FPM found in WordPress Dockerfile"
    fi
fi

echo -e "\n${YELLOW}Checking WordPress volume...${NC}"
docker volume ls
WP_VOLUME=$(docker volume ls --format '{{.Name}}' | grep -i "wordpress\|wp")
if [ -n "$WP_VOLUME" ]; then
    print_test 0 "WordPress volume found: $WP_VOLUME"
    echo -e "\n  ${YELLOW}Volume details:${NC}"
    docker volume inspect "$WP_VOLUME" | grep -A 5 "Mountpoint"
    
    MOUNTPOINT=$(docker volume inspect "$WP_VOLUME" --format '{{.Mountpoint}}')
    LOGIN=$(whoami)
    if [[ "$MOUNTPOINT" == *"/home/$LOGIN/data"* ]] || [[ "$MOUNTPOINT" == *"data"* ]]; then
        print_test 0 "Volume mountpoint contains correct path"
    else
        echo -e "  ${YELLOW}→ Verify mountpoint is at /home/$LOGIN/data/${NC}"
    fi
else
    print_test 1 "WordPress volume NOT found"
fi

echo -e "\n${YELLOW}WordPress accessibility and user check...${NC}"
DOMAIN_FULL=$(grep "DOMAIN_NAME" srcs/.env 2>/dev/null | cut -d'=' -f2 || echo "localhost")
DOMAIN=$(echo "$DOMAIN_FULL" | awk '{print $1}')
echo -e "  ${YELLOW}→ Open browser and visit: https://$DOMAIN${NC}"
echo -e "  ${YELLOW}→ You should see WordPress site (NOT installation page)${NC}"
echo -e "  ${YELLOW}→ Try adding a comment as a regular user${NC}"
echo -e "  ${YELLOW}→ Login to admin dashboard${NC}"
echo -e "  ${YELLOW}→ Edit a page and verify changes appear on the site${NC}"

echo -e "\n${YELLOW}Checking WordPress users in database...${NC}"
DB_NAME=$(grep "MYSQL_DATABASE" srcs/.env 2>/dev/null | cut -d'=' -f2 | tr -d ' \t\r' || echo "wordpress")
DB_USER=$(grep "MYSQL_USER" srcs/.env 2>/dev/null | cut -d'=' -f2 | tr -d ' \t\r' || echo "wpuser")
DB_PASS=$(grep "MYSQL_PASSWORD" srcs/.env 2>/dev/null | cut -d'=' -f2 | head -1 | tr -d ' \t\r' || echo "")

if [ -n "$DB_PASS" ]; then
    echo -e "  Querying WordPress users..."
    WP_USERS=$(docker exec mariadb mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "SELECT user_login, user_email FROM wp_users;" 2>/dev/null | tail -n +2)
    
    if [ -n "$WP_USERS" ]; then
        echo -e "\n  ${YELLOW}WordPress users:${NC}"
        echo "$WP_USERS"
        
        # Check if admin username contains 'admin'
        ADMIN_USER=$(echo "$WP_USERS" | head -1 | awk '{print $1}')
        if echo "$ADMIN_USER" | grep -qiE "admin|administrator"; then
            print_test 1 "FORBIDDEN: Admin username contains 'admin': $ADMIN_USER"
            echo -e "  ${RED}Username must NOT contain: admin, Admin, administrator, Administrator${NC}"
        else
            print_test 0 "Admin username is acceptable: $ADMIN_USER"
        fi
        
        # Verify two users exist
        USER_COUNT=$(echo "$WP_USERS" | wc -l)
        if [ "$USER_COUNT" -ge 2 ]; then
            print_test 0 "Two or more WordPress users exist (required)"
        else
            print_test 1 "Only $USER_COUNT user(s) found - need at least 2 (admin + regular user)"
        fi
    else
        echo -e "  ${YELLOW}→ Could not retrieve WordPress users${NC}"
    fi
else
    echo -e "  ${YELLOW}→ Could not find database password${NC}"
    echo -e "  ${YELLOW}→ Manually verify WordPress has 2 users and admin username is acceptable${NC}"
fi

# ============================================
# 6. MARIADB
# ============================================
print_header "6. MARIADB WITH VOLUME"

echo -e "${YELLOW}Checking MariaDB Dockerfile...${NC}"
if [ -f "srcs/requirements/mariadb/Dockerfile" ]; then
    print_test 0 "MariaDB Dockerfile exists"
    
    if grep -qi "nginx" "srcs/requirements/mariadb/Dockerfile"; then
        print_test 1 "FORBIDDEN: NGINX found in MariaDB Dockerfile"
    else
        print_test 0 "No NGINX in MariaDB Dockerfile (good)"
    fi
fi

echo -e "\n${YELLOW}Checking MariaDB volume...${NC}"
DB_VOLUME=$(docker volume ls --format '{{.Name}}' | grep -i "mariadb\|db\|database" | head -1)
if [ -n "$DB_VOLUME" ]; then
    print_test 0 "MariaDB volume found: $DB_VOLUME"
    echo -e "\n  ${YELLOW}Volume details:${NC}"
    docker volume inspect "$DB_VOLUME" | grep -A 5 "Mountpoint"
    
    MOUNTPOINT=$(docker volume inspect "$DB_VOLUME" --format '{{.Mountpoint}}')
    LOGIN=$(whoami)
    if [[ "$MOUNTPOINT" == *"/home/$LOGIN/data"* ]] || [[ "$MOUNTPOINT" == *"data"* ]]; then
        print_test 0 "Volume mountpoint contains correct path"
    else
        echo -e "  ${YELLOW}→ Verify mountpoint is at /home/$LOGIN/data/${NC}"
    fi
else
    print_test 1 "MariaDB volume NOT found"
fi

echo -e "\n${YELLOW}Testing MariaDB connection...${NC}"
DB_NAME=$(grep "MYSQL_DATABASE" srcs/.env 2>/dev/null | cut -d'=' -f2 | tr -d ' \t\r' || echo "wordpress")
DB_USER=$(grep "MYSQL_USER" srcs/.env 2>/dev/null | cut -d'=' -f2 | tr -d ' \t\r' || echo "wpuser")
DB_PASS=$(grep "MYSQL_PASSWORD" srcs/.env 2>/dev/null | cut -d'=' -f2 | head -1 | tr -d ' \t\r' || echo "")

echo -e "  Attempting to connect to database '$DB_NAME' as user '$DB_USER'..."
if docker exec mariadb mysql -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SHOW TABLES;" 2>/dev/null | grep -q "wp_"; then
    print_test 0 "Successfully connected to MariaDB"
    print_test 0 "Database is not empty (WordPress tables found)"
    echo -e "\n  ${YELLOW}Database tables:${NC}"
    docker exec mariadb mysql -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SHOW TABLES;" 2>/dev/null
else
    print_test 1 "Failed to connect to MariaDB or database is empty"
    echo -e "  ${YELLOW}→ Try manually: docker exec -it mariadb mysql -u$DB_USER -p${NC}"
fi

# ============================================
# 7. PERSISTENCE TEST
# ============================================
print_header "7. PERSISTENCE TEST"

echo -e "${YELLOW}This test requires a system reboot!${NC}"
echo -e "${YELLOW}Manual steps to verify persistence:${NC}"
echo -e "  1. Make a change to WordPress (edit a page, add a post, etc.)"
echo -e "  2. Stop all container
echo -e "  3. Run: docker compose -f srcs/docker-compose.yml down
echo -e "  4. Verify containers are stopped but volumes remain:
echo -e "  5. docker ps -a  # Should show no running containers
echo -e "  6. docker volume ls  # Should still show your volumes
echo -e "   7. Restart everything : make


# ============================================
# SUMMARY
# ============================================
# print_header "TEST SUMMARY"

# echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
# echo -e "${YELLOW}                 MANDATORY EVALUATION CHECKLIST${NC}"
# echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# echo -e "${BLUE}═══ CRITICAL SECURITY (Auto-fail if found) ═══${NC}"
# print_checklist "no_cred_leak" "No credentials/API keys/passwords in git repository"
# print_checklist "env_not_tracked" ".env file NOT tracked by git (must be in .gitignore)"
# echo -e "[ ] Secrets folder NOT tracked by git"
# echo -e "[ ] All credentials ONLY in .env during evaluation"
# echo -e ""

# echo -e "${BLUE}═══ PRELIMINARY CHECKS (Eval ends if failed) ═══${NC}"
# echo -e "[ ] Ran cleanup command before starting"
# print_checklist "srcs_exists" "srcs/ folder at root with docker-compose.yml"
# print_checklist "makefile_exists" "Makefile at root"
# print_checklist "env_exists" ".env file exists in srcs/"
# print_checklist "no_network_host" "No 'network: host' in docker-compose"
# print_checklist "no_links" "No 'links:' in docker-compose"
# print_checklist "has_networks" "Has 'networks:' declaration in docker-compose"
# print_checklist "no_link" "No '--link' in Makefile or any scripts"
# echo -e "[ ] No 'tail -f' in Dockerfiles ENTRYPOINT"
# echo -e "[ ] No background processes in ENTRYPOINT (e.g., 'nginx & bash')"
# echo -e "[ ] No 'bash' or 'sh' in ENTRYPOINT (except for running scripts)"
# echo -e "[ ] Entrypoint scripts don't run programs in background"
# echo -e "[ ] No infinite loops (sleep infinity, tail -f, while true)"
# echo -e "[ ] No 'latest' tag in any Dockerfile"
# echo -e ""

# echo -e "${BLUE}═══ DOCKER BASICS ═══${NC}"
# echo -e "[ ] One Dockerfile per service (nginx, wordpress, mariadb)"
# echo -e "[ ] All Dockerfiles exist and NOT empty"
# echo -e "[ ] Student wrote their own Dockerfiles (not copy-paste from internet)"
# echo -e "[ ] No ready-made Docker images from DockerHub used"
# echo -e "[ ] Base images: Alpine or Debian (penultimate stable version)"
# echo -e "[ ] Docker images have same name as corresponding service"
# echo -e "[ ] All services built via docker compose"
# echo -e "[ ] Containers have auto-restart policy (always/unless-stopped)"
# echo -e ""

# echo -e "${BLUE}═══ DOCKER NETWORK ═══${NC}"
# print_checklist "network_exists" "docker-network exists (visible in 'docker network ls')"
# echo -e "[ ] All containers connected to the network"
# echo -e "[ ] Student can explain docker-network in simple terms"
# echo -e ""

# echo -e "${BLUE}═══ NGINX WITH SSL/TLS ═══${NC}"
# echo -e "[ ] NGINX Dockerfile exists"
# print_checklist "nginx_running" "NGINX container running"
# echo -e "[ ] HTTP (port 80) NOT accessible or redirects to HTTPS"
# print_checklist "https_accessible" "HTTPS (port 443) IS accessible"
# print_checklist "ssl_cert" "SSL/TLS certificate present"
# echo -e "[ ] TLS version is v1.2 or v1.3"
# echo -e "[ ] NGINX is the sole entry point (only port 443 exposed)"
# echo -e ""

# echo -e "${BLUE}═══ WORDPRESS WITH PHP-FPM ═══${NC}"
# echo -e "[ ] WordPress Dockerfile exists"
# echo -e "[ ] NO NGINX in WordPress Dockerfile"
# echo -e "[ ] PHP-FPM installed and configured"
# print_checklist "wordpress_running" "WordPress container running"
# echo -e "[ ] WordPress volume exists"
# echo -e "[ ] Volume mountpoint at /home/login/data/"
# echo -e "[ ] WordPress accessible at https://login.42.fr"
# echo -e "[ ] NO WordPress installation page visible (already configured)"
# echo -e "[ ] Two users exist in WordPress database"
# echo -e "[ ] Admin username does NOT contain: admin/Admin/administrator/Administrator"
# echo -e "[ ] Can add comment as regular user"
# echo -e "[ ] Can login to admin dashboard"
# echo -e "[ ] Can edit pages from admin dashboard"
# echo -e "[ ] Page edits appear on website"
# echo -e ""

# echo -e "${BLUE}═══ MARIADB WITH VOLUME ═══${NC}"
# echo -e "[ ] MariaDB Dockerfile exists"
# echo -e "[ ] NO NGINX in MariaDB Dockerfile"
# print_checklist "mariadb_running" "MariaDB container running"
# echo -e "[ ] MariaDB volume exists"
# echo -e "[ ] Volume mountpoint at /home/login/data/"
# echo -e "[ ] Can login to database"
# echo -e "[ ] Database is NOT empty (contains WordPress tables)"
# echo -e ""

# echo -e "${BLUE}═══ DOMAIN AND CONFIGURATION ═══${NC}"
# echo -e "[ ] Domain name is login.42.fr (student's login)"
# echo -e "[ ] Domain points to local IP address"
# echo -e "[ ] Environment variables used (not hardcoded)"
# echo -e "[ ] Passwords stored in secrets or .env (not in Dockerfiles)"
# echo -e ""

# echo -e "${BLUE}═══ PERSISTENCE TEST (Must verify manually) ═══${NC}"
# echo -e "[ ] Make a change to WordPress website"
# echo -e "[ ] Run: sudo reboot"
# echo -e "[ ] After reboot, run: make"
# echo -e "[ ] WordPress changes still present"
# echo -e "[ ] MariaDB data still intact"
# echo -e ""

# echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
# echo -e "${YELLOW}                 PROJECT OVERVIEW QUESTIONS${NC}"
# echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# echo -e "${GREEN}Ask the student to explain:${NC}"
# echo -e "• How Docker and docker compose work"
# echo -e "• Difference between Docker image with/without docker compose"
# echo -e "• Benefits of Docker compared to VMs"
# echo -e "• Why this directory structure is required for the project"
# echo -e "• How they built their Dockerfiles (show they wrote it themselves)"
# echo -e "• How to login to MariaDB database"
# echo -e "• What docker-network does in simple terms"
# echo -e ""

# print_header "TEST COMPLETE"
# echo -e "${GREEN}✓ Automated tests completed${NC}"
# echo -e "${YELLOW}→ Remember to verify manual checks (persistence, user interaction, etc.)${NC}"
# echo -e "${YELLOW}→ Follow evaluation sheet for any additional questions${NC}"
# echo -e "${YELLOW}→ Check student's understanding through explanations${NC}\n"
