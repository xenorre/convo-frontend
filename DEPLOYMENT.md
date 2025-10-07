# 🚀 ConvoChat Frontend Deployment Guide

This guide covers deployment options for the ConvoChat React TypeScript frontend application.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Environment Setup](#environment-setup)
- [Docker Deployment](#docker-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Production Deployment](#production-deployment)
- [Monitoring & Health Checks](#monitoring--health-checks)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Development

```bash
# Clone and setup
git clone <your-repo-url>
cd convo-frontend

# Quick development start
./scripts/dev.sh

# Or with full backend stack
./scripts/dev.sh --with-backend
```

### Production

```bash
# Build and deploy to production
./scripts/production-deploy.sh deploy

# Or use the general deployment script
./scripts/deploy.sh production
```

## 🔧 Environment Setup

### 1. Environment Variables

Create environment files for each environment:

```bash
# Development
cp .env.example .env.local

# Staging
cp .env.example .env.staging

# Production
cp .env.example .env.production
```

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API URL | `https://api.yourapp.com/api` |
| `VITE_WS_URL` | WebSocket server URL | `wss://api.yourapp.com` |
| `VITE_NODE_ENV` | Environment name | `production` |
| `VITE_APP_NAME` | Application name | `ConvoChat` |
| `VITE_MAX_MESSAGE_LENGTH` | Max message length | `2000` |
| `VITE_MAX_FILE_SIZE` | Max file size in bytes | `5242880` |

### GitHub Secrets (for CI/CD)

Set these in your GitHub repository settings:

```
VITE_API_URL_DEVELOPMENT=http://localhost:3000/api
VITE_API_URL_STAGING=https://staging-api.yourapp.com/api
VITE_API_URL_PRODUCTION=https://api.yourapp.com/api

VITE_WS_URL_DEVELOPMENT=http://localhost:3000
VITE_WS_URL_STAGING=wss://staging-api.yourapp.com
VITE_WS_URL_PRODUCTION=wss://api.yourapp.com

SNYK_TOKEN=your_snyk_token (optional)
SLACK_WEBHOOK=your_slack_webhook (optional)
```

## 🐳 Docker Deployment

### Simple Docker Run

```bash
# Build the image
docker build -t convo-frontend .

# Run the container
docker run -d \
  --name convo-frontend \
  -p 8080:8080 \
  -e VITE_API_URL=https://api.yourapp.com/api \
  -e VITE_WS_URL=wss://api.yourapp.com \
  convo-frontend
```

### Using Docker Compose

```bash
# Development environment
docker-compose -f docker-compose.dev.yml up -d

# Production environment
docker-compose -f docker-compose.prod.yml up -d

# With monitoring stack
docker-compose -f docker-compose.prod.yml --profile with-monitoring up -d
```

### Multi-Architecture Builds

```bash
# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg VITE_API_URL=https://api.yourapp.com/api \
  --build-arg VITE_WS_URL=wss://api.yourapp.com \
  -t convo-frontend:latest \
  --push .
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The CI/CD pipeline automatically:

1. **Code Quality Checks**
   - Runs ESLint and TypeScript checks
   - Executes unit and integration tests
   - Performs security scans

2. **Build & Test**
   - Builds application for multiple environments
   - Analyzes bundle size
   - Runs accessibility tests

3. **Docker Build**
   - Creates optimized Docker images
   - Scans for vulnerabilities
   - Pushes to GitHub Container Registry

4. **Deployment**
   - Deploys to staging on `develop` branch
   - Deploys to production on release
   - Runs post-deployment health checks

### Manual Triggers

```bash
# Trigger deployment from command line
gh workflow run ci-cd.yml --ref main

# Create a release (triggers production deployment)
gh release create v1.0.0 --title "Release v1.0.0" --notes "Production release"
```

## 🏭 Production Deployment

### Prerequisites

1. **Infrastructure Setup**
   ```bash
   # Ensure Docker is installed and running
   docker --version
   
   # Verify network connectivity to backend
   curl -f https://api.yourapp.com/health
   ```

2. **SSL Certificate**
   ```bash
   # If using custom SSL, place certificates in ./ssl/
   mkdir -p ssl
   cp your-cert.pem ssl/
   cp your-key.pem ssl/
   ```

### Deployment Methods

#### Method 1: Automated Script (Recommended)

```bash
# Full production deployment with safety checks
./scripts/production-deploy.sh deploy

# Verify deployment
./scripts/production-deploy.sh verify

# Rollback if needed
./scripts/production-deploy.sh rollback
```

#### Method 2: Manual Docker Compose

```bash
# Set environment variables
export VITE_API_URL=https://api.yourapp.com/api
export VITE_WS_URL=wss://api.yourapp.com

# Deploy with production compose file
docker-compose -f docker-compose.prod.yml up -d

# Check container health
docker ps
docker logs convo-frontend-prod
```

#### Method 3: Kubernetes (Advanced)

```bash
# Apply Kubernetes manifests (if available)
kubectl apply -f k8s/production/

# Check deployment status
kubectl get pods -l app=convo-frontend
kubectl logs -l app=convo-frontend
```

### Zero-Downtime Deployment

The production script automatically performs zero-downtime deployments:

1. **Blue-Green Deployment**
   - Builds new container alongside existing
   - Health checks new container
   - Switches traffic only when healthy
   - Removes old container

2. **Health Verification**
   - HTTP health endpoint checks
   - Response time monitoring
   - Error rate validation

## 📊 Monitoring & Health Checks

### Health Endpoints

| Endpoint | Description | Expected Response |
|----------|-------------|-------------------|
| `/health` | Basic health check | `200 OK` |
| `/health/detailed` | Detailed health info | JSON with metrics |

### Container Health Checks

Docker containers include built-in health checks:

```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# View health check logs
docker inspect convo-frontend --format='{{json .State.Health}}'
```

### Monitoring Stack

Enable monitoring with Docker Compose profiles:

```bash
# Start with monitoring
docker-compose -f docker-compose.prod.yml --profile with-monitoring up -d

# Access monitoring dashboards
open http://localhost:9090  # Prometheus
open http://localhost:3100  # Loki
```

### Key Metrics

- **Performance**: Page load time, bundle size, render time
- **Errors**: JavaScript errors, network failures, 4xx/5xx responses
- **Resources**: Memory usage, CPU utilization, disk space
- **Business**: User actions, feature usage, conversion rates

## 🔧 Troubleshooting

### Common Issues

#### Build Failures

```bash
# Check Node.js version
node --version  # Should be 20+

# Clear dependencies and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build
```

#### Docker Issues

```bash
# Check Docker daemon
docker info

# Clean up Docker resources
docker system prune -f
docker volume prune -f

# Check container logs
docker logs convo-frontend -f
```

#### Environment Variables

```bash
# Verify environment variables in container
docker exec convo-frontend env | grep VITE_

# Check build-time variables
docker image inspect convo-frontend --format='{{json .Config.Env}}'
```

#### Network Connectivity

```bash
# Test API connectivity from container
docker exec convo-frontend curl -f https://api.yourapp.com/health

# Check nginx configuration
docker exec convo-frontend nginx -t
```

### Performance Issues

1. **Bundle Size Too Large**
   ```bash
   # Analyze bundle
   npm run analyze
   
   # Check for large dependencies
   npx webpack-bundle-analyzer dist/assets/*.js
   ```

2. **Slow Page Load**
   ```bash
   # Enable performance monitoring
   docker exec convo-frontend tail -f /var/log/nginx/access.log
   
   # Check resource loading
   curl -w "@curl-format.txt" -o /dev/null -s https://yourapp.com
   ```

3. **Memory Issues**
   ```bash
   # Monitor container resources
   docker stats convo-frontend
   
   # Check application memory usage
   docker exec convo-frontend cat /proc/meminfo
   ```

### Deployment Rollback

If issues occur after deployment:

```bash
# Quick rollback using script
./scripts/production-deploy.sh rollback

# Manual rollback using Docker
docker stop convo-frontend-prod
docker run -d --name convo-frontend-prod \
  -p 8080:8080 \
  convo-frontend:previous-version
```

### Health Check Failures

```bash
# Debug health endpoint
curl -v http://localhost:8080/health

# Check application logs
docker logs convo-frontend -f --tail 100

# Inspect container filesystem
docker exec -it convo-frontend sh
```

### CI/CD Pipeline Issues

1. **GitHub Actions Failures**
   ```bash
   # Check workflow status
   gh run list --workflow=ci-cd.yml
   
   # View specific run logs
   gh run view <run-id>
   ```

2. **Docker Registry Issues**
   ```bash
   # Login to GitHub Container Registry
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   
   # Test image pull
   docker pull ghcr.io/username/convo-frontend:latest
   ```

## 📞 Support

- **Issues**: Create GitHub issue with deployment logs
- **Documentation**: Check `PRODUCTION_CHECKLIST.md` for pre-deployment checks
- **Monitoring**: Use built-in health endpoints for status checks
- **Logs**: Check Docker container logs and nginx access logs

## 🔍 Additional Resources

- [Production Checklist](./PRODUCTION_CHECKLIST.md)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)

---

**Note**: Always test deployments in a staging environment before production deployment.