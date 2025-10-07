#!/bin/bash

# ConvoChat Frontend - Quick Start Script
# This script sets up the development environment quickly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SKIP_INSTALL=false
SKIP_BUILD=false
SKIP_TEST=false
START_DEV=false
USE_DOCKER=false

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check Node.js
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION"
        
        # Check if version is >= 18
        NODE_MAJOR=$(echo $NODE_VERSION | sed 's/v\([0-9]*\).*/\1/')
        if [ "$NODE_MAJOR" -lt 18 ]; then
            print_error "Node.js version 18 or higher is required. Found: $NODE_VERSION"
            exit 1
        fi
    else
        print_error "Node.js not found. Please install Node.js 18 or higher."
        exit 1
    fi
    
    # Check npm
    if command -v npm >/dev/null 2>&1; then
        NPM_VERSION=$(npm --version)
        print_success "npm found: $NPM_VERSION"
    else
        print_error "npm not found. Please install npm."
        exit 1
    fi
    
    # Check Docker (optional)
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker found: $DOCKER_VERSION"
        HAS_DOCKER=true
    else
        print_warning "Docker not found. Docker features will be unavailable."
        HAS_DOCKER=false
    fi
    
    # Check Docker Compose (optional)
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker Compose found: $COMPOSE_VERSION"
        HAS_COMPOSE=true
    else
        print_warning "Docker Compose not found. Docker Compose features will be unavailable."
        HAS_COMPOSE=false
    fi
}

setup_environment() {
    print_header "Setting Up Environment"
    
    # Copy example environment file if it doesn't exist
    if [ ! -f ".env.local" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env.local
            print_success "Created .env.local from .env.example"
            print_info "Please review and update .env.local with your configuration"
        else
            print_warning ".env.example not found. You may need to create environment configuration manually."
        fi
    else
        print_info ".env.local already exists"
    fi
    
    # Create necessary directories
    mkdir -p logs backups temp
    print_success "Created necessary directories"
}

install_dependencies() {
    if [ "$SKIP_INSTALL" = true ]; then
        print_info "Skipping dependency installation"
        return
    fi
    
    print_header "Installing Dependencies"
    
    if [ -f "package-lock.json" ]; then
        npm ci
        print_success "Dependencies installed with npm ci"
    else
        npm install
        print_success "Dependencies installed with npm install"
    fi
}

build_application() {
    if [ "$SKIP_BUILD" = true ]; then
        print_info "Skipping build"
        return
    fi
    
    print_header "Building Application"
    
    npm run build
    print_success "Application built successfully"
}

run_tests() {
    if [ "$SKIP_TEST" = true ]; then
        print_info "Skipping tests"
        return
    fi
    
    print_header "Running Tests"
    
    # Run linting
    if npm run lint >/dev/null 2>&1; then
        print_success "Linting passed"
    else
        print_warning "Linting issues found. Run 'npm run lint:fix' to auto-fix."
    fi
    
    # Run type checking
    if npm run type-check >/dev/null 2>&1; then
        print_success "Type checking passed"
    else
        print_error "Type checking failed"
        return 1
    fi
    
    # Run unit tests
    npm test -- --run
    print_success "Tests passed"
}

start_development() {
    if [ "$START_DEV" = false ]; then
        return
    fi
    
    print_header "Starting Development Server"
    
    if [ "$USE_DOCKER" = true ]; then
        if [ "$HAS_DOCKER" = true ] && [ "$HAS_COMPOSE" = true ]; then
            print_info "Starting development server with Docker..."
            docker-compose -f docker-compose.dev.yml up -d
            print_success "Development server started with Docker"
            print_info "Frontend: http://localhost:3000"
            if docker-compose -f docker-compose.dev.yml ps | grep -q backend; then
                print_info "Backend: http://localhost:3001"
            fi
        else
            print_error "Docker or Docker Compose not available. Cannot start with Docker."
            exit 1
        fi
    else
        print_info "Starting development server..."
        print_success "Development server will start shortly"
        print_info "Frontend will be available at: http://localhost:3000"
        npm run dev
    fi
}

show_usage() {
    cat << EOF
ConvoChat Frontend Quick Start Script

Usage: $0 [OPTIONS]

Options:
    --skip-install      Skip dependency installation
    --skip-build        Skip application build
    --skip-test         Skip running tests
    --dev               Start development server after setup
    --docker            Use Docker for development server
    --help              Show this help message

Examples:
    $0                  # Full setup (install, build, test)
    $0 --dev            # Full setup and start development server
    $0 --docker --dev   # Full setup and start with Docker
    $0 --skip-test --dev # Setup without tests and start dev server

EOF
}

main() {
    print_header "ConvoChat Frontend Quick Start"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-install)
                SKIP_INSTALL=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-test)
                SKIP_TEST=true
                shift
                ;;
            --dev)
                START_DEV=true
                shift
                ;;
            --docker)
                USE_DOCKER=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Run setup steps
    check_requirements
    setup_environment
    install_dependencies
    build_application
    run_tests
    
    print_header "Setup Complete!"
    print_success "ConvoChat Frontend is ready for development"
    
    if [ "$START_DEV" = false ]; then
        echo -e "\n${GREEN}Next steps:${NC}"
        echo -e "  • Review and update ${YELLOW}.env.local${NC} with your configuration"
        echo -e "  • Start development server: ${BLUE}npm run dev${NC}"
        echo -e "  • Or use Docker: ${BLUE}./scripts/dev.sh${NC}"
        echo -e "  • View available commands: ${BLUE}make help${NC}"
    else
        start_development
    fi
    
    echo -e "\n${GREEN}Happy coding! 🚀${NC}\n"
}

# Check if running directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi