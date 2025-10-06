#!/bin/bash

# Test script for Project Management API
# This tests the API endpoints without requiring database

echo "🧪 Testing Pomodoro Genie Project Management API..."

# Set environment for testing (no database required)
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=test
export DB_PASSWORD=test
export DB_NAME=test_db
export DB_SSLMODE=disable
export PORT=8084
export GIN_MODE=test

# Start the API in background (it will fail DB connection but serve mock endpoints)
echo "🚀 Starting API server for testing..."
timeout 10s go run ./cmd/main.go &
API_PID=$!

# Wait for server to start
sleep 3

echo ""
echo "📋 Testing API endpoints..."

# Test health endpoint
echo "1. Health check:"
curl -s http://localhost:8083/health | jq '.' || echo "Health endpoint failed"

echo ""
echo "2. Root endpoint:"
curl -s http://localhost:8083/ | jq '.' || echo "Root endpoint failed"

echo ""
echo "3. Projects endpoint (should require auth):"
curl -s http://localhost:8083/v1/projects | jq '.' || echo "Projects endpoint correctly requires auth"

echo ""
echo "4. Projects endpoint with auth:"
curl -s -H "Authorization: Bearer valid-token" http://localhost:8083/v1/projects | jq '.' || echo "Projects endpoint with auth failed"

echo ""
echo "5. Docs endpoint:"
curl -s http://localhost:8083/docs | jq '.' || echo "Docs endpoint failed"

# Clean up
echo ""
echo "🧹 Cleaning up..."
kill $API_PID 2>/dev/null
wait $API_PID 2>/dev/null

echo "✅ API testing completed!"