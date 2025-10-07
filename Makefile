# ConvoChat Frontend Makefile

.PHONY: help install dev build test lint format clean docker-build docker-dev deploy health-check

# Default target
.DEFAULT_GOAL := help

# Variables
NODE_VERSION := $(shell node --version 2>/dev/null || echo "not installed")
NPM_VERSION := $(shell npm --version 2>/dev/null || echo "not installed")
DOCKER_VERSION := $(shell docker --version 2>/dev/null || echo "not installed")

help: ## Display this help message
	@echo "ConvoChat Frontend - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "System Information:"
	@echo "  Node.js: $(NODE_VERSION)"
	@echo "  npm: $(NPM_VERSION)"
	@echo "  Docker: $(DOCKER_VERSION)"

install: ## Install dependencies
	@echo "Installing dependencies..."
	npm ci

dev: ## Start development server
	@echo "Starting development server..."
	npm run dev

build: ## Build for production
	@echo "Building for production..."
	npm run build

test: ## Run tests
	@echo "Running tests..."
	npm test

test-watch: ## Run tests in watch mode
	@echo "Running tests in watch mode..."
	npm run test:watch

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	npm run test:coverage

lint: ## Run linter
	@echo "Running linter..."
	npm run lint

lint-fix: ## Fix linting issues
	@echo "Fixing linting issues..."
	npm run lint:fix

format: ## Format code
	@echo "Formatting code..."
	npm run format

type-check: ## Run TypeScript type checking
	@echo "Running TypeScript type checking..."
	npm run type-check

preview: ## Preview production build
	@echo "Starting preview server..."
	npm run preview

clean: ## Clean build artifacts and dependencies
	@echo "Cleaning build artifacts..."
	rm -rf dist build node_modules/.cache
	@echo "Cleaning dependencies..."
	rm -rf node_modules package-lock.json

clean-all: clean ## Clean everything including node_modules
	@echo "Full clean completed"

docker-build: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t convochat-frontend:latest .

docker-build-dev: ## Build development Docker image
	@echo "Building development Docker image..."
	docker build -f Dockerfile.dev -t convochat-frontend:dev .

docker-dev: ## Start development with Docker Compose
	@echo "Starting development environment with Docker..."
	./scripts/dev.sh

docker-prod: ## Start production environment with Docker Compose
	@echo "Starting production environment with Docker..."
	docker-compose -f docker-compose.prod.yml up -d

docker-stop: ## Stop all Docker services
	@echo "Stopping Docker services..."
	docker-compose down
	docker-compose -f docker-compose.dev.yml down
	docker-compose -f docker-compose.prod.yml down

docker-logs: ## View Docker logs
	@echo "Viewing Docker logs..."
	docker-compose logs -f

deploy-dev: ## Deploy to development environment
	@echo "Deploying to development..."
	./scripts/deploy.sh development

deploy-staging: ## Deploy to staging environment
	@echo "Deploying to staging..."
	./scripts/deploy.sh staging

deploy-prod: ## Deploy to production environment
	@echo "Deploying to production..."
	./scripts/production-deploy.sh

health-check: ## Check application health
	@echo "Checking application health..."
	@if [ -f "./scripts/health-check.sh" ]; then \
		./scripts/health-check.sh; \
	else \
		curl -f http://localhost:3000/health || echo "Health check failed"; \
	fi

backup: ## Create backup before deployment
	@echo "Creating backup..."
	mkdir -p backups
	tar -czf backups/backup-$$(date +%Y%m%d-%H%M%S).tar.gz --exclude=node_modules --exclude=dist --exclude=.git .

setup: ## Initial project setup
	@echo "Setting up ConvoChat Frontend..."
	@echo "1. Installing dependencies..."
	make install
	@echo "2. Running initial build..."
	make build
	@echo "3. Running tests..."
	make test
	@echo "Setup complete! Run 'make dev' to start development."

ci: ## Run CI pipeline locally
	@echo "Running CI pipeline..."
	make install
	make lint
	make type-check
	make test
	make build
	@echo "CI pipeline completed successfully!"

deps-check: ## Check for dependency updates
	@echo "Checking for dependency updates..."
	npm outdated

deps-update: ## Update dependencies
	@echo "Updating dependencies..."
	npm update

security-check: ## Run security audit
	@echo "Running security audit..."
	npm audit

security-fix: ## Fix security vulnerabilities
	@echo "Fixing security vulnerabilities..."
	npm audit fix

size-analysis: ## Analyze bundle size
	@echo "Analyzing bundle size..."
	npm run build
	@if command -v npx >/dev/null 2>&1; then \
		npx vite-bundle-analyzer dist/stats.json; \
	else \
		echo "Bundle analyzer not available. Install vite-bundle-analyzer for detailed analysis."; \
		du -sh dist/*; \
	fi

lighthouse: ## Run Lighthouse audit
	@echo "Running Lighthouse audit..."
	@if command -v lighthouse >/dev/null 2>&1; then \
		lighthouse http://localhost:3000 --output html --output-path ./lighthouse-report.html; \
		echo "Lighthouse report generated: lighthouse-report.html"; \
	else \
		echo "Lighthouse not installed. Install with: npm install -g @lhci/cli"; \
	fi

performance: ## Run performance tests
	@echo "Running performance analysis..."
	make build
	make size-analysis

release: ## Create a new release
	@echo "Creating release..."
	@if [ -z "$(VERSION)" ]; then \
		echo "Please specify VERSION: make release VERSION=1.0.0"; \
		exit 1; \
	fi
	@echo "Updating version to $(VERSION)..."
	npm version $(VERSION)
	@echo "Building for production..."
	make build
	@echo "Running tests..."
	make test
	@echo "Release $(VERSION) ready!"

info: ## Display project information
	@echo "ConvoChat Frontend Project Information"
	@echo "======================================"
	@echo "Node.js version: $(NODE_VERSION)"
	@echo "npm version: $(NPM_VERSION)"
	@echo "Docker version: $(DOCKER_VERSION)"
	@echo ""
	@echo "Project structure:"
	@find . -type f -name "*.json" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" | head -10
	@echo ""
	@echo "Available scripts:"
	@npm run | grep -E "^  [a-zA-Z]" | head -10