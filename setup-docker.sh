#!/bin/bash

# Docker Compose Setup Script for Pomodoro Genie
set -e

echo "🐳 Docker Compose Setup for Pomodoro Genie"
echo "=========================================="

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed!"
    echo ""
    echo "Install Docker with:"
    echo "curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "sudo sh get-docker.sh"
    echo "sudo usermod -aG docker \$USER"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose is not installed!"
    echo ""
    echo "Install Docker Compose with:"
    echo "sudo curl -L \"https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo "sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi

log_success "Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1) is installed"
log_success "Docker Compose $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1) is installed"

# Check Docker permissions
if ! docker ps &> /dev/null; then
    log_warning "Docker requires sudo or user needs to be in docker group"
    echo ""
    echo "To fix this, run:"
    echo "sudo usermod -aG docker \$USER"
    echo "newgrp docker"
    echo ""
    echo "Or use sudo with docker commands."
    echo ""

    read -p "Continue with sudo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    DOCKER_CMD="sudo docker"
    COMPOSE_CMD="sudo docker-compose"
else
    DOCKER_CMD="docker"
    COMPOSE_CMD="docker-compose"
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    log_info "Creating .env file from template..."

    # Generate secure values
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-32)
    SUPABASE_ANON_KEY=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-32)
    SUPABASE_SERVICE_ROLE_KEY=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-32)

    cat > .env << EOF
# Supabase Configuration
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRY_LIMIT=3600
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}
PGRST_DB_SCHEMAS=public,storage,graphql_public

# API Configuration
API_PORT=8080
API_HOST=localhost
GIN_MODE=debug

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Origin,Content-Type,Accept,Authorization,X-Requested-With

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE=100

# Firebase Cloud Messaging (FCM) - Update these with your actual values
FCM_SERVER_KEY=your-fcm-server-key
FCM_PROJECT_ID=your-firebase-project-id
EOF

    log_success ".env file created with secure generated values"
else
    log_info ".env file already exists"
fi

# Check if database migrations exist
if [ ! -f "backend/migrations/init.sql" ]; then
    log_warning "Database migration file not found at backend/migrations/init.sql"
    log_info "Creating placeholder migration file..."

    mkdir -p backend/migrations
    cat > backend/migrations/init.sql << 'EOF'
-- Pomodoro Genie Database Initialization
-- This file will be executed when the database container starts

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_version BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'pending',
    due_date TIMESTAMP WITH TIME ZONE,
    reminder_date TIMESTAMP WITH TIME ZONE,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_version BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create subtasks table
CREATE TABLE IF NOT EXISTS subtasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create pomodoro_sessions table
CREATE TABLE IF NOT EXISTS pomodoro_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'work',
    planned_duration INTEGER NOT NULL,
    actual_duration INTEGER,
    status VARCHAR(20) DEFAULT 'active',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_subtasks_task_id ON subtasks(task_id);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_id ON pomodoro_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_task_id ON pomodoro_sessions(task_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subtasks_updated_at ON subtasks;
CREATE TRIGGER update_subtasks_updated_at BEFORE UPDATE ON subtasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pomodoro_sessions_updated_at ON pomodoro_sessions;
CREATE TRIGGER update_pomodoro_sessions_updated_at BEFORE UPDATE ON pomodoro_sessions FOR EACH ROW EXECUTE FUNCTION update_pomodoro_sessions_updated_at_column();

COMMIT;
EOF

    log_success "Placeholder database migration created"
fi

# Pull Docker images
log_info "Pulling Docker images..."
$COMPOSE_CMD pull

# Start services
log_info "Starting Supabase services..."
$COMPOSE_CMD up -d

# Wait for services to be ready
log_info "Waiting for services to start..."
sleep 10

# Check service status
log_info "Checking service status..."
$COMPOSE_CMD ps

# Test database connection
log_info "Testing database connection..."
if $DOCKER_CMD exec pomodoro_supabase_db pg_isready -U postgres > /dev/null 2>&1; then
    log_success "Database is ready"
else
    log_warning "Database may still be starting up"
fi

# Display connection information
echo ""
log_success "🎉 Supabase is running!"
echo ""
echo "📋 Service URLs:"
echo "  • Supabase Studio: http://localhost:3000"
echo "  • PostgreSQL:      localhost:5432"
echo "  • PostgREST API:    http://localhost:54321"
echo "  • Realtime:         http://localhost:4000"
echo "  • Meta API:         http://localhost:8080"
echo ""
echo "🔑 Database Connection:"
echo "  • Host:     localhost"
echo "  • Port:     5432"
echo "  • Database: postgres"
echo "  • User:     postgres"
echo "  • Password: (check .env file)"
echo ""
echo "🧪 For manual testing:"
echo "  • Update BACKEND_URL in backend/tests/manual/.env"
echo "  • Update DATABASE_URL to: postgresql://postgres:$(grep POSTGRES_PASSWORD .env | cut -d'=' -f2)@localhost:5432/postgres"
echo ""
echo "🛑 To stop services:"
echo "  $COMPOSE_CMD down"
echo ""
echo "🗑️ To remove all data:"
echo "  $COMPOSE_CMD down -v"
EOF