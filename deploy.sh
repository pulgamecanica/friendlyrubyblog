#!/bin/bash
set -e

echo "========================================="
echo "Friendly Ruby Blog - Deploy Script"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Load .env file if it exists
if [ -f .env ]; then
    print_success "Loading environment variables from .env"
    export $(grep -v '^#' .env | xargs)
else
    print_warning "No .env file found, using environment variables"
fi

echo ""
echo "Checking environment variables..."
MISSING_VARS=0

check_var() {
    if [ -z "${!1}" ]; then
        print_error "$1 is not set"
        MISSING_VARS=$((MISSING_VARS + 1))
    else
        print_success "$1 is set"
    fi
}

check_var "KAMAL_REGISTRY_PASSWORD"
check_var "POSTGRES_PASSWORD"
check_var "DATABASE_URL"
check_var "SECRET_KEY_BASE"
check_var "AWS_ACCESS_KEY_ID"
check_var "AWS_SECRET_ACCESS_KEY"

echo ""

if [ $MISSING_VARS -gt 0 ]; then
    print_error "Missing $MISSING_VARS required environment variable(s)"
    echo ""
    echo "Please run ./setup_production.sh for setup instructions"
    exit 1
fi

# Check if this is the first deployment
FIRST_DEPLOY=false
if ! ssh ssh_pt "docker ps | grep -q friendlyrubyblog" 2>/dev/null; then
    FIRST_DEPLOY=true
fi

if [ "$FIRST_DEPLOY" = true ]; then
    echo "This appears to be your first deployment."
    echo ""
    echo "This will:"
    echo "  1. Build and push Docker image to GitHub Container Registry"
    echo "  2. Deploy PostgreSQL database"
    echo "  3. Deploy the Rails application"
    echo "  4. Set up SSL with Let's Encrypt"
    echo "  5. Configure the proxy"
    echo ""
    echo "⏱️  This will take 5-10 minutes."
    echo ""
    read -p "Continue with initial setup? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi

    echo ""
    print_warning "Running: kamal setup"
    echo ""
    kamal setup

    echo ""
    print_success "Initial deployment complete!"
    echo ""
    echo "Setting up monitoring..."
    ./monitoring_setup.sh

else
    echo "Deploying updates to production..."
    echo ""
    read -p "Continue with deployment? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi

    echo ""
    print_warning "Running: kamal deploy"
    echo ""
    kamal deploy

    echo ""
    print_success "Deployment complete!"
fi

echo ""
echo "========================================="
echo "Deployment Summary"
echo "========================================="
echo ""
echo "URL: https://evil-penguin.com"
echo "Server: 148.71.60.228"
echo ""
echo "Useful commands:"
echo "  kamal app logs -f    # Follow application logs"
echo "  kamal console        # Open Rails console"
echo "  kamal app details    # View container status"
echo ""
echo "Health check logs:"
echo "  ssh ssh_pt 'tail -f /var/log/friendlyrubyblog_health.log'"
echo ""
echo "========================================="
