#!/bin/bash

# Pomodoro Timer Development Script

set -e

echo "🍅 Starting Pomodoro Timer Development Environment..."

# Check if wails is installed
if ! command -v wails &> /dev/null; then
    echo "❌ Wails not installed. Installing Wails..."
    go install github.com/wailsapp/wails/v2/cmd/wails@latest
fi

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not installed, please install Node.js first"
    exit 1
fi

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend
npm install

# Start Wails development mode
echo "🚀 Starting Wails development server..."
cd ..
wails dev
