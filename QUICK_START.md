# Quick Start - Deploy to Production

## 1️⃣ Set Environment Variables (One-time setup)

```bash
# Create GitHub Personal Access Token at:
# https://github.com/settings/tokens/new
# Scopes needed: write:packages, read:packages

export KAMAL_REGISTRY_PASSWORD=ghp_your_github_token_here
export POSTGRES_PASSWORD=$(openssl rand -hex 32)
export DATABASE_URL=postgresql://friendlyrubyblog:$POSTGRES_PASSWORD@friendlyrubyblog-db:5432/friendlyrubyblog_production
export SECRET_KEY_BASE=$(openssl rand -hex 64)
export AWS_ACCESS_KEY_ID=your_aws_key
export AWS_SECRET_ACCESS_KEY=your_aws_secret
```

**💡 TIP**: Save these to your `~/.bashrc` or `~/.zshrc` so they persist!

## 2️⃣ Verify Setup

```bash
./setup_production.sh
```

## 3️⃣ First-Time Deployment

```bash
# This sets up everything: PostgreSQL, SSL, and deploys the app
kamal setup
```

⏱️ **This will take 5-10 minutes**. It will:
- Deploy PostgreSQL database container
- Build and push your Docker image to GitHub Container Registry
- Deploy the Rails application
- Set up SSL certificates from Let's Encrypt
- Configure Traefik proxy

## 4️⃣ Setup Monitoring

```bash
./monitoring_setup.sh
```

## 5️⃣ Verify Deployment

Visit: **https://evil-penguin.com**

Check logs:
```bash
kamal app logs
```

---

## Daily Operations

### Deploy New Changes

```bash
git add .
git commit -m "Your changes"
git push
kamal deploy
```

### View Logs

```bash
kamal app logs -f
```

### Rails Console

```bash
kamal console
```

### Check Health

```bash
ssh ssh_pt 'tail -f /var/log/friendlyrubyblog_health.log'
```

---

## Need Help?

See **DEPLOYMENT.md** for detailed documentation and troubleshooting.
