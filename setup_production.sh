#!/bin/bash
set -e

echo "========================================="
echo "Friendly Ruby Blog - Production Setup"
echo "========================================="
echo ""

# Load .env file if it exists
if [ -f .env ]; then
    echo "✓ Loading environment variables from .env"
    export $(grep -v '^#' .env | xargs)
    echo ""
else
    echo "⚠ No .env file found, using environment variables"
    echo ""
fi

# Check if required environment variables are set
check_env_var() {
    if [ -z "${!1}" ]; then
        echo "ERROR: $1 is not set!"
        echo "Please run: export $1=your_value"
        return 1
    else
        echo "✓ $1 is set"
        return 0
    fi
}

echo "Checking required environment variables..."
echo ""

MISSING_VARS=0

check_env_var "KAMAL_REGISTRY_PASSWORD" || MISSING_VARS=$((MISSING_VARS + 1))
check_env_var "AWS_ACCESS_KEY_ID" || MISSING_VARS=$((MISSING_VARS + 1))
check_env_var "AWS_SECRET_ACCESS_KEY" || MISSING_VARS=$((MISSING_VARS + 1))
check_env_var "SECRET_KEY_BASE" || MISSING_VARS=$((MISSING_VARS + 1))
check_env_var "POSTGRES_PASSWORD" || MISSING_VARS=$((MISSING_VARS + 1))
check_env_var "DATABASE_URL" || MISSING_VARS=$((MISSING_VARS + 1))

echo ""

if [ $MISSING_VARS -gt 0 ]; then
    echo "========================================="
    echo "Missing $MISSING_VARS required environment variable(s)"
    echo "========================================="
    echo ""
    echo "Quick setup guide:"
    echo ""
    echo "1. GitHub Container Registry Token:"
    echo "   Create at: https://github.com/settings/tokens/new"
    echo "   Scopes: write:packages, read:packages"
    echo "   export KAMAL_REGISTRY_PASSWORD=your_github_token"
    echo ""
    echo "2. PostgreSQL Password (choose a strong password):"
    echo "   export POSTGRES_PASSWORD=\$(openssl rand -hex 32)"
    echo ""
    echo "3. Database URL:"
    echo "   export DATABASE_URL=postgresql://friendlyrubyblog:\$POSTGRES_PASSWORD@friendlyrubyblog-db:5432/friendlyrubyblog_production"
    echo ""
    echo "4. Secret Key Base:"
    echo "   export SECRET_KEY_BASE=\$(openssl rand -hex 64)"
    echo ""
    echo "5. AWS Credentials (for file storage):"
    echo "   export AWS_ACCESS_KEY_ID=your_aws_key"
    echo "   export AWS_SECRET_ACCESS_KEY=your_aws_secret"
    echo ""
    exit 1
fi

echo "========================================="
echo "All environment variables are set!"
echo "========================================="
echo ""
echo "Proceeding with deployment..."
echo ""

# Install kamal if not already installed
if ! command -v kamal &> /dev/null; then
    echo "Installing Kamal..."
    gem install kamal
fi

# Check server connectivity
echo "Testing SSH connection to server..."
if ssh -o ConnectTimeout=5 ssh_pt "echo 'Connection successful'"; then
    echo "✓ Server connection successful"
else
    echo "ERROR: Cannot connect to server via ssh_pt"
    exit 1
fi

echo ""
echo "========================================="
echo "Ready to deploy!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Run: kamal setup     (first time only - sets up server and database)"
echo "2. Run: kamal deploy    (deploy the application)"
echo "3. Run: kamal app logs  (view application logs)"
echo ""
echo "Your app will be available at: https://evil-penguin.com"
echo ""
