#!/bin/bash

# Pomodoro Genie Project Management API Startup Script
# This script starts the new project management API with database integration

echo "🍅 Starting Pomodoro Genie Project Management API..."

# Set environment variables for development
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=postgres
export DB_NAME=pomodoro_genie
export DB_SSLMODE=disable
export PORT=8081
export GIN_MODE=debug

# Check if PostgreSQL is running
echo "📊 Checking PostgreSQL connection..."
if ! docker ps | grep -q postgres; then
    echo "⚠️ PostgreSQL container not found. Starting with docker-compose..."
    docker-compose up -d postgres
    echo "⏳ Waiting for PostgreSQL to be ready..."
    sleep 5
fi

# Install dependencies if needed
echo "📦 Installing Go dependencies..."
go mod tidy

# Run the API server
echo "🚀 Starting API server on port $PORT..."
echo "🔗 API will be available at: http://localhost:$PORT"
echo "📋 Projects API: http://localhost:$PORT/v1/projects"
echo "🩺 Health check: http://localhost:$PORT/health"
echo ""
echo "💡 Test with: curl -H 'Authorization: Bearer valid-token' http://localhost:$PORT/v1/projects"
echo ""

# Build and run the new API
go run ./cmd/main.go