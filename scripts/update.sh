#!/bin/bash

# Pomodoro Timer Update Script

set -e

echo "🍅 Updating Pomodoro Timer Dependencies..."

# Update Go dependencies
echo "🔄 Updating Go dependencies..."
go mod tidy
go mod download

# Update frontend dependencies  
echo "🔄 Updating frontend dependencies..."
cd frontend
npm update
npm audit fix --force 2>/dev/null || true
cd ..

# Update Wails if available
echo "🔄 Checking for Wails updates..."
wails version
echo "To update Wails run: go install github.com/wailsapp/wails/v2/cmd/wails@latest"

echo "✅ Update completed!"
echo "🔧 Run './scripts/dev.sh' to start development"
echo "🔨 Run './scripts/build.sh' to build the application"