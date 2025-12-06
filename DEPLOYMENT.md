# Friendly Ruby Blog - Production Deployment Guide

This guide will help you deploy the Friendly Ruby Blog to production on `evil-penguin.com`.

## Prerequisites

- Server with Docker installed: `148.71.60.228` (accessible via `ssh_pt`)
- Domain: `evil-penguin.com` (DNS pointing to server)
- Ports open: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- GitHub account with access to push to `pulgamecanica/friendlyrubyblog`

## Step 1: Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens/new
2. Token name: `Kamal Deployment Token`
3. Select scopes:
   - ✓ `write:packages`
   - ✓ `read:packages`
4. Click "Generate token"
5. **IMPORTANT**: Copy the token immediately (you won't see it again)

## Step 2: Set Environment Variables

Run these commands in your terminal:

```bash
# GitHub Container Registry token (from Step 1)
export KAMAL_REGISTRY_PASSWORD=your_github_token_here

# PostgreSQL password (generate a secure password)
export POSTGRES_PASSWORD=$(openssl rand -hex 32)

# Database URL (uses the PostgreSQL password above)
export DATABASE_URL=postgresql://friendlyrubyblog:$POSTGRES_PASSWORD@friendlyrubyblog-db:5432/friendlyrubyblog_production

# Secret key base for Rails
export SECRET_KEY_BASE=$(openssl rand -hex 64)

# AWS credentials for file storage
export AWS_ACCESS_KEY_ID=your_aws_access_key_id
export AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
```

**TIP**: Add these to your `~/.bashrc` or `~/.zshrc` to persist them:
```bash
echo "export KAMAL_REGISTRY_PASSWORD=your_token" >> ~/.bashrc
echo "export POSTGRES_PASSWORD=your_password" >> ~/.bashrc
# ... etc
```

## Step 3: Verify Setup

Run the setup verification script:

```bash
./setup_production.sh
```

This will check that all required environment variables are set and verify server connectivity.

## Step 4: Install Kamal

If you don't have Kamal installed:

```bash
gem install kamal
```

## Step 5: Deploy to Production

### First-time deployment:

```bash
# Setup server infrastructure and PostgreSQL database
kamal setup

# This will:
# - Install Docker on the server (if needed)
# - Create Docker network
# - Deploy PostgreSQL database
# - Deploy the application
# - Set up SSL with Let's Encrypt
# - Configure the proxy
```

### Subsequent deployments:

```bash
# Deploy new version of the application
kamal deploy
```

## Step 6: Set Up Monitoring

After the first successful deployment, set up health checks:

```bash
./monitoring_setup.sh
```

This installs a cron job that checks your application every 5 minutes and logs to `/var/log/friendlyrubyblog_health.log`.

## Useful Commands

### Application Management

```bash
# View application logs
kamal app logs

# Follow logs in real-time
kamal app logs -f

# Open Rails console
kamal console

# Open shell in container
kamal shell

# Restart application
kamal app restart

# View container details
kamal app details
```

### Database Management

```bash
# View database logs
kamal accessory logs db

# Restart database
kamal accessory restart db

# Open database console
kamal dbc
```

### SSL/Proxy Management

```bash
# View proxy logs
kamal proxy logs

# Restart proxy (useful if SSL renewal fails)
kamal proxy restart

# Force SSL certificate renewal
kamal proxy boot --reboot
```

### Monitoring

```bash
# View health check logs
ssh ssh_pt 'tail -f /var/log/friendlyrubyblog_health.log'

# Check running containers
ssh ssh_pt 'docker ps'

# Check disk usage
ssh ssh_pt 'df -h'

# Check Docker volumes
ssh ssh_pt 'docker volume ls'
```

### Rollback

```bash
# Rollback to previous version
kamal rollback [VERSION]

# List available versions
kamal app images
```

## Configuration Files

- `config/deploy.yml` - Main Kamal configuration
- `.kamal/secrets` - Secret variables (pulled from environment)
- `.kamal/hooks/pre-deploy` - Runs before deployment
- `.kamal/hooks/post-deploy` - Runs after deployment

## Deployment Architecture

```
Internet
    ↓
evil-penguin.com (148.71.60.228)
    ↓
Kamal Proxy (Traefik) - Handles SSL/HTTPS
    ↓
friendlyrubyblog-web (Rails app on port 80)
    ↓
friendlyrubyblog-db (PostgreSQL on port 5432)
```

## Troubleshooting

### SSL Certificate Issues

If Let's Encrypt fails:
```bash
# Check proxy logs
kamal proxy logs

# Reboot proxy
kamal proxy boot --reboot
```

### Database Connection Issues

```bash
# Check database is running
kamal accessory details db

# Check database logs
kamal accessory logs db

# Verify DATABASE_URL is correct
kamal app exec -i "env | grep DATABASE_URL"
```

### Application Won't Start

```bash
# Check application logs
kamal app logs

# Check if database migrations ran
kamal app exec -i "bin/rails db:migrate:status"

# Run migrations manually
kamal app exec -i "bin/rails db:migrate"
```

### Image Build Fails

```bash
# Build locally to see detailed errors
docker build -t friendlyrubyblog .

# Check if all secrets are set
kamal secrets
```

## Security Notes

1. **Never commit secrets** to Git - always use environment variables
2. **Master key** is read from `config/master.key` - keep this file secure
3. **PostgreSQL** is only accessible from localhost (127.0.0.1:5432)
4. **SSL certificates** are auto-renewed by Let's Encrypt
5. **Container runs as non-root** user (UID 1000) for security

## Monitoring & Alerts

Current monitoring includes:
- ✓ Automated health checks every 5 minutes
- ✓ HTTP status code verification
- ✓ Docker container status checks
- ✓ Application and database logs

To add custom alerts, edit the health check script:
```bash
ssh ssh_pt 'sudo nano /usr/local/bin/friendlyrubyblog_health_check.sh'
```

## Support

For issues:
1. Check application logs: `kamal app logs`
2. Check proxy logs: `kamal proxy logs`
3. Check database logs: `kamal accessory logs db`
4. Review this guide's troubleshooting section

## URLs

- **Production**: https://evil-penguin.com
- **Repository**: https://github.com/pulgamecanica/friendlyrubyblog
- **Server**: 148.71.60.228 (ssh_pt)
