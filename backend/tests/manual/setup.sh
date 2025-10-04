#!/bin/bash

# Pomodoro Genie Manual Testing Setup Script
set -e

echo "🍅 Pomodoro Genie Manual Testing Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo ""
log_info "Checking prerequisites..."

# Check Go installation
if ! command -v go &> /dev/null; then
    log_error "Go is not installed. Please install Go 1.21+ and try again."
    exit 1
fi

go_version=$(go version | awk '{print $3}' | sed 's/go//')
log_success "Go $go_version is installed"

# Check curl
if ! command -v curl &> /dev/null; then
    log_error "curl is not installed. Please install curl and try again."
    exit 1
fi
log_success "curl is available"

# Check jq
if ! command -v jq &> /dev/null; then
    log_error "jq is not installed. Please install jq and try again."
    log_info "Ubuntu/Debian: sudo apt-get install jq"
    log_info "macOS: brew install jq"
    exit 1
fi
log_success "jq is available"

# Check make
if ! command -v make &> /dev/null; then
    log_error "make is not installed. Please install make and try again."
    exit 1
fi
log_success "make is available"

# Create environment file
echo ""
log_info "Setting up environment configuration..."

if [ ! -f ".env" ]; then
    cp .env.example .env
    log_success "Environment file created (.env)"
    log_warning "Please review and update .env file with your specific configuration"
else
    log_info "Environment file already exists"
fi

# Create reports directory
if [ ! -d "reports" ]; then
    mkdir -p reports
    log_success "Reports directory created"
else
    log_info "Reports directory already exists"
fi

# Initialize Go module if needed
echo ""
log_info "Setting up Go module..."

if [ ! -f "../../../go.mod" ]; then
    cd ../../..
    go mod init github.com/pomodoro-team/pomodoro-app
    log_success "Go module initialized"
    cd backend/tests/manual
else
    log_info "Go module already exists"
fi

# Check if backend dependencies are available
echo ""
log_info "Checking backend setup..."

if [ -f "../../../go.mod" ]; then
    cd ../../..
    if ! go mod download &> /dev/null; then
        log_warning "Some Go dependencies may be missing"
        log_info "You may need to run 'go mod tidy' in the project root"
    else
        log_success "Go dependencies are available"
    fi
    cd backend/tests/manual
fi

# Test backend connectivity (if running)
echo ""
log_info "Testing backend connectivity..."

BACKEND_URL=${BACKEND_URL:-"http://localhost:3000/v1"}

if curl -s -f "${BACKEND_URL}/health" > /dev/null 2>&1; then
    log_success "Backend is running and accessible at $BACKEND_URL"
else
    log_warning "Backend is not currently running at $BACKEND_URL"
    log_info "You'll need to start the backend before running tests"
    log_info "Use: make run-backend (or start manually)"
fi

# Validate script permissions
echo ""
log_info "Setting up script permissions..."

chmod +x validate_scenarios.sh
chmod +x setup.sh
log_success "Script permissions configured"

# Display next steps
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "==========="
echo "1. Review and update the .env file if needed:"
echo "   nano .env"
echo ""
echo "2. Start the backend server (if not running):"
echo "   make run-backend"
echo ""
echo "3. Run a quick validation:"
echo "   make validate-setup"
echo ""
echo "4. Execute a smoke test:"
echo "   make smoke-test"
echo ""
echo "5. Run the complete test suite:"
echo "   make test-all"
echo ""
echo "Available commands:"
echo "   make help           - Show all available commands"
echo "   make help-scenarios - Show detailed scenario information"
echo "   make smoke-test     - Quick validation test"
echo "   make test-all       - Complete test suite"
echo "   make test-scenario-X - Run specific scenario (1-5)"
echo "   make clean-reports  - Clean up old reports"
echo ""

# Optional: Start backend automatically
read -p "Would you like to try starting the backend now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    log_info "Attempting to start backend..."
    if make run-backend; then
        log_success "Backend started successfully"
    else
        log_warning "Backend startup failed - you may need to configure it manually"
    fi
fi