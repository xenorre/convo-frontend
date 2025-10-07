#!/bin/bash
# =======================================================
# Quick Development Setup Script
# =======================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
    echo -e "${BLUE}[DEV]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log "Starting Docker..."
    open -a Docker
    echo "Waiting for Docker to start..."
    while ! docker info > /dev/null 2>&1; do
        sleep 2
    done
fi

cd "$PROJECT_ROOT"

# Create .env.local if it doesn't exist
if [ ! -f ".env.local" ]; then
    log "Creating .env.local from .env.example..."
    cp .env.example .env.local
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    log "Installing dependencies..."
    npm install
fi

# Start development environment
log "Starting development environment..."

# Option to run with or without backend
if [ "${1:-}" = "--with-backend" ]; then
    log "Starting with full backend stack..."
    docker-compose -f docker-compose.dev.yml --profile with-backend up -d
    
    echo ""
    log_success "Development environment started!"
    echo "Frontend: http://localhost:3000"
    echo "Backend: http://localhost:8000"
    echo "MongoDB: mongodb://localhost:27017"
else
    log "Starting frontend only..."
    npm run dev &
    DEV_PID=$!
    
    echo ""
    log_success "Development server started!"
    echo "Frontend: http://localhost:3000"
    echo ""
    echo "Press Ctrl+C to stop"
    
    # Wait for Ctrl+C
    trap "kill $DEV_PID 2>/dev/null || true; exit" INT
    wait $DEV_PID
fi