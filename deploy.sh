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
