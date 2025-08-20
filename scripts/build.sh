#!/bin/bash

# Pomodoro Timer Build Script

set -e

echo "🍅 Building Pomodoro Timer..."

# Check if wails is installed
if ! command -v wails &> /dev/null; then
    echo "❌ Wails not installed. Installing Wails..."
    go install github.com/wailsapp/wails/v2/cmd/wails@latest
fi

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend
npm install
cd ..

# Build the application
echo "🔨 Building application..."
wails build

echo "✅ Build completed!"
echo "📦 Executable located at: build/bin/"

# List available builds
ls -la build/bin/
