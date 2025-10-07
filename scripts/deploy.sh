#!/bin/bash
# =======================================================
# ConvoChat Frontend Deployment Script
# =======================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$PROJECT_ROOT/logs/deploy_$TIMESTAMP.log"

# Default values
ENVIRONMENT="development"
BUILD_ONLY=false
FORCE_REBUILD=false
SKIP_TESTS=false
SKIP_BACKUP=false

# Ensure logs directory exists
mkdir -p "$PROJECT_ROOT/logs"

# =====================================
# Logging Functions
# =====================================
log() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# =====================================
# Helper Functions
# =====================================
usage() {
    cat << EOF
Usage: $0 [OPTIONS] ENVIRONMENT

ENVIRONMENT:
    development    Deploy to development environment
    staging        Deploy to staging environment  
    production     Deploy to production environment

OPTIONS:
    -h, --help           Show this help message
    -b, --build-only     Only build, don't deploy
    -f, --force-rebuild  Force rebuild even if no changes
    -t, --skip-tests     Skip running tests
    -s, --skip-backup    Skip backup creation (not recommended for production)
    
EXAMPLES:
    $0 development
    $0 staging --build-only
    $0 production --force-rebuild

EOF
}

cleanup() {
    log "Cleaning up temporary files..."
    # Add cleanup commands here
    rm -rf "$PROJECT_ROOT/temp_deploy" 2>/dev/null || true
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if required commands exist
    local required_commands=("docker" "docker-compose" "npm" "git")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' not found. Please install it first."
            exit 1
        fi
    done
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

load_environment_config() {
    local env_file="$PROJECT_ROOT/.env.$ENVIRONMENT"
    
    if [ ! -f "$env_file" ]; then
        log_warning "Environment file $env_file not found. Using defaults."
        return
    fi
    
    log "Loading environment configuration from $env_file"
    
    # Export environment variables
    set -o allexport
    source "$env_file"
    set +o allexport
    
    log_success "Environment configuration loaded"
}

run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        log_warning "Skipping tests as requested"
        return
    fi
    
    log "Running tests..."
    cd "$PROJECT_ROOT"
    
    npm ci --silent
    npm run test:run
    npm run lint
    
    log_success "All tests passed"
}

build_application() {
    log "Building application for $ENVIRONMENT..."
    cd "$PROJECT_ROOT"
    
    # Set build environment variables
    export VITE_NODE_ENV="$ENVIRONMENT"
    
    # Build the application
    npm run build
    
    # Analyze bundle if not production
    if [ "$ENVIRONMENT" != "production" ]; then
        npm run analyze || log_warning "Bundle analysis failed"
    fi
    
    log_success "Application built successfully"
}

build_docker_image() {
    log "Building Docker image for $ENVIRONMENT..."
    
    local image_tag="convo-frontend:$ENVIRONMENT-$TIMESTAMP"
    local latest_tag="convo-frontend:$ENVIRONMENT-latest"
    
    # Build with proper build args
    docker build \
        --build-arg VITE_API_URL="${VITE_API_URL:-http://localhost:3000/api}" \
        --build-arg VITE_WS_URL="${VITE_WS_URL:-http://localhost:3000}" \
        --build-arg VITE_NODE_ENV="$ENVIRONMENT" \
        --tag "$image_tag" \
        --tag "$latest_tag" \
        "$PROJECT_ROOT"
    
    # Clean up old images to save space
    docker image prune -f
    
    log_success "Docker image built: $image_tag"
    echo "$image_tag" > "$PROJECT_ROOT/.last_image_tag"
}

create_backup() {
    if [ "$SKIP_BACKUP" = true ]; then
        log_warning "Skipping backup as requested"
        return
    fi
    
    if [ "$ENVIRONMENT" = "development" ]; then
        log "Skipping backup for development environment"
        return
    fi
    
    log "Creating backup for $ENVIRONMENT environment..."
    
    local backup_dir="$PROJECT_ROOT/backups/$ENVIRONMENT"
    local backup_file="$backup_dir/backup_$TIMESTAMP.tar.gz"
    
    mkdir -p "$backup_dir"
    
    # Create backup of current deployment
    if docker ps | grep -q "convo-frontend-$ENVIRONMENT"; then
        log "Creating container backup..."
        docker save "convo-frontend:$ENVIRONMENT-latest" | gzip > "$backup_file"
        log_success "Backup created: $backup_file"
    else
        log "No existing container found, skipping backup"
    fi
}

deploy_to_environment() {
    log "Deploying to $ENVIRONMENT environment..."
    
    cd "$PROJECT_ROOT"
    
    case "$ENVIRONMENT" in
        "development")
            deploy_development
            ;;
        "staging")
            deploy_staging
            ;;
        "production")
            deploy_production
            ;;
        *)
            log_error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
}

deploy_development() {
    log "Starting development deployment..."
    
    # Use development docker-compose
    docker-compose -f docker-compose.dev.yml down || true
    docker-compose -f docker-compose.dev.yml up -d
    
    wait_for_health_check "http://localhost:3000"
    log_success "Development environment deployed successfully"
}

deploy_staging() {
    log "Starting staging deployment..."
    
    # Pull latest images and deploy
    docker-compose -f docker-compose.prod.yml down || true
    docker-compose -f docker-compose.prod.yml up -d
    
    wait_for_health_check "${STAGING_URL:-http://localhost:8080}"
    log_success "Staging environment deployed successfully"
}

deploy_production() {
    log "Starting production deployment..."
    
    # Extra confirmation for production
    echo -n "Are you sure you want to deploy to PRODUCTION? (yes/no): "
    read -r confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log "Production deployment cancelled by user"
        exit 0
    fi
    
    # Zero-downtime deployment for production
    docker-compose -f docker-compose.prod.yml up -d --no-deps frontend
    
    wait_for_health_check "${PRODUCTION_URL:-http://localhost:8080}"
    
    # Remove old containers after successful deployment
    docker system prune -f
    
    log_success "Production environment deployed successfully"
}

wait_for_health_check() {
    local url="$1"
    local max_attempts=30
    local attempt=1
    
    log "Waiting for application to be healthy at $url..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url/health" > /dev/null 2>&1; then
            log_success "Application is healthy"
            return 0
        fi
        
        log "Health check attempt $attempt/$max_attempts failed, waiting 10 seconds..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    log_error "Application failed to become healthy after $max_attempts attempts"
    return 1
}

run_post_deployment_tests() {
    log "Running post-deployment tests..."
    
    local base_url
    case "$ENVIRONMENT" in
        "development")
            base_url="http://localhost:3000"
            ;;
        "staging")
            base_url="${STAGING_URL:-http://localhost:8080}"
            ;;
        "production")
            base_url="${PRODUCTION_URL:-http://localhost:8080}"
            ;;
    esac
    
    # Basic smoke tests
    if ! curl -f -s "$base_url" > /dev/null; then
        log_error "Smoke test failed: Application not accessible at $base_url"
        return 1
    fi
    
    if ! curl -f -s "$base_url/health" > /dev/null; then
        log_error "Health check failed at $base_url/health"
        return 1
    fi
    
    log_success "Post-deployment tests passed"
}

# =====================================
# Main Execution
# =====================================
main() {
    log "Starting deployment script at $(date)"
    log "Environment: $ENVIRONMENT"
    log "Build only: $BUILD_ONLY"
    log "Force rebuild: $FORCE_REBUILD"
    log "Skip tests: $SKIP_TESTS"
    log "Skip backup: $SKIP_BACKUP"
    
    check_prerequisites
    load_environment_config
    
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    fi
    
    build_application
    
    if [ "$BUILD_ONLY" = false ]; then
        create_backup
        build_docker_image
        deploy_to_environment
        run_post_deployment_tests
        
        log_success "🎉 Deployment completed successfully!"
        log "Application URL: $(get_app_url)"
        log "Logs saved to: $LOG_FILE"
    else
        log_success "Build completed successfully"
    fi
}

get_app_url() {
    case "$ENVIRONMENT" in
        "development")
            echo "http://localhost:3000"
            ;;
        "staging")
            echo "${STAGING_URL:-http://localhost:8080}"
            ;;
        "production")
            echo "${PRODUCTION_URL:-http://localhost:8080}"
            ;;
    esac
}

# =====================================
# Parse Command Line Arguments
# =====================================
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -f|--force-rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        -t|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -s|--skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        development|staging|production)
            ENVIRONMENT="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"