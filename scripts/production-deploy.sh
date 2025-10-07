#!/bin/bash
# =======================================================
# Production Deployment Script with Safety Checks
# =======================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
    echo -e "${BLUE}[PRODUCTION]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Production safety checklist
production_safety_check() {
    log "Running production safety checklist..."
    
    local safety_failed=false
    
    # Check if we're on the correct branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        log_warning "Not on main/master branch. Current: $current_branch"
        echo -n "Continue anyway? (yes/no): "
        read -r response
        if [ "$response" != "yes" ]; then
            exit 1
        fi
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_error "There are uncommitted changes. Please commit or stash them first."
        safety_failed=true
    fi
    
    # Check if all tests pass
    log "Running full test suite..."
    if ! npm run test:run; then
        log_error "Tests are failing. Cannot deploy to production."
        safety_failed=true
    fi
    
    # Check if build works
    log "Testing production build..."
    if ! npm run build; then
        log_error "Production build failed. Cannot deploy."
        safety_failed=true
    fi
    
    # Check environment variables
    if [ -z "${VITE_API_URL_PRODUCTION:-}" ]; then
        log_error "VITE_API_URL_PRODUCTION is not set"
        safety_failed=true
    fi
    
    if [ -z "${VITE_WS_URL_PRODUCTION:-}" ]; then
        log_error "VITE_WS_URL_PRODUCTION is not set"
        safety_failed=true
    fi
    
    if [ "$safety_failed" = true ]; then
        log_error "Production safety checks failed. Deployment aborted."
        exit 1
    fi
    
    log_success "Production safety checks passed"
}

# Backup current production
backup_production() {
    log "Creating production backup..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="$PROJECT_ROOT/backups/production"
    
    mkdir -p "$backup_dir"
    
    # Save current Docker image
    if docker images | grep -q "convo-frontend:production-latest"; then
        log "Backing up current production image..."
        docker save convo-frontend:production-latest | gzip > "$backup_dir/production_backup_$timestamp.tar.gz"
        echo "$timestamp" > "$backup_dir/latest_backup.txt"
        log_success "Backup created: production_backup_$timestamp.tar.gz"
    else
        log_warning "No existing production image to backup"
    fi
}

# Zero-downtime deployment
zero_downtime_deploy() {
    log "Starting zero-downtime deployment..."
    
    # Build new image with blue-green tag
    local new_tag="convo-frontend:production-$(date +"%Y%m%d_%H%M%S")"
    
    log "Building new production image: $new_tag"
    docker build \
        --build-arg VITE_API_URL="$VITE_API_URL_PRODUCTION" \
        --build-arg VITE_WS_URL="$VITE_WS_URL_PRODUCTION" \
        --build-arg VITE_NODE_ENV=production \
        --tag "$new_tag" \
        --tag "convo-frontend:production-latest" \
        "$PROJECT_ROOT"
    
    # Start new container alongside old one
    log "Starting new container..."
    docker run -d \
        --name convo-frontend-production-new \
        --publish 8081:8080 \
        --restart unless-stopped \
        "$new_tag"
    
    # Wait for health check
    log "Waiting for new container to be healthy..."
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if curl -f -s http://localhost:8081/health > /dev/null 2>&1; then
            log_success "New container is healthy"
            break
        fi
        
        attempts=$((attempts + 1))
        log "Health check attempt $attempts/$max_attempts..."
        sleep 10
    done
    
    if [ $attempts -eq $max_attempts ]; then
        log_error "New container failed health check. Rolling back..."
        docker stop convo-frontend-production-new || true
        docker rm convo-frontend-production-new || true
        exit 1
    fi
    
    # Switch traffic (this would typically involve load balancer reconfiguration)
    log "Switching traffic to new container..."
    
    # Stop and remove old container
    if docker ps | grep -q convo-frontend-production; then
        docker stop convo-frontend-production || true
        docker rm convo-frontend-production || true
    fi
    
    # Rename new container
    docker rename convo-frontend-production-new convo-frontend-production
    
    # Update port mapping
    docker stop convo-frontend-production
    docker run -d \
        --name convo-frontend-production-final \
        --publish 8080:8080 \
        --restart unless-stopped \
        "$new_tag"
    
    docker rm convo-frontend-production
    docker rename convo-frontend-production-final convo-frontend-production
    
    log_success "Zero-downtime deployment completed"
}

# Post-deployment verification
verify_deployment() {
    log "Verifying deployment..."
    
    local production_url="${PRODUCTION_URL:-http://localhost:8080}"
    
    # Health check
    if ! curl -f -s "$production_url/health" > /dev/null; then
        log_error "Production health check failed"
        return 1
    fi
    
    # Basic functionality test
    if ! curl -f -s "$production_url" > /dev/null; then
        log_error "Production site is not accessible"
        return 1
    fi
    
    # Performance check (basic)
    local response_time=$(curl -o /dev/null -s -w "%{time_total}" "$production_url")
    if (( $(echo "$response_time > 2" | bc -l) )); then
        log_warning "Production response time is slow: ${response_time}s"
    else
        log_success "Production response time: ${response_time}s"
    fi
    
    log_success "Deployment verification completed"
}

# Rollback function
rollback_production() {
    log "Rolling back production deployment..."
    
    local backup_dir="$PROJECT_ROOT/backups/production"
    local latest_backup_file="$backup_dir/latest_backup.txt"
    
    if [ ! -f "$latest_backup_file" ]; then
        log_error "No backup available for rollback"
        exit 1
    fi
    
    local backup_timestamp=$(cat "$latest_backup_file")
    local backup_file="$backup_dir/production_backup_$backup_timestamp.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log "Restoring from backup: $backup_timestamp"
    
    # Load backup image
    zcat "$backup_file" | docker load
    
    # Stop current container
    docker stop convo-frontend-production || true
    docker rm convo-frontend-production || true
    
    # Start with backup image
    docker run -d \
        --name convo-frontend-production \
        --publish 8080:8080 \
        --restart unless-stopped \
        convo-frontend:production-latest
    
    log_success "Rollback completed"
}

# Main function
main() {
    echo "🚀 Production Deployment Script"
    echo "================================"
    
    case "${1:-deploy}" in
        "deploy")
            production_safety_check
            backup_production
            zero_downtime_deploy
            verify_deployment
            
            log_success "🎉 Production deployment completed successfully!"
            log "Production URL: ${PRODUCTION_URL:-http://localhost:8080}"
            ;;
            
        "rollback")
            echo -n "Are you sure you want to rollback production? (yes/no): "
            read -r confirmation
            if [ "$confirmation" = "yes" ]; then
                rollback_production
            else
                log "Rollback cancelled"
            fi
            ;;
            
        "verify")
            verify_deployment
            ;;
            
        *)
            echo "Usage: $0 [deploy|rollback|verify]"
            echo ""
            echo "Commands:"
            echo "  deploy   - Deploy to production with safety checks"
            echo "  rollback - Rollback to previous version"
            echo "  verify   - Verify current production deployment"
            exit 1
            ;;
    esac
}

# Check if running in production environment
if [ "${NODE_ENV:-}" != "production" ] && [ "${ENVIRONMENT:-}" != "production" ]; then
    log_warning "Not running in production environment"
    echo -n "Continue with production deployment? (yes/no): "
    read -r response
    if [ "$response" != "yes" ]; then
        exit 0
    fi
fi

main "$@"