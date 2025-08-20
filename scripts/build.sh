#!/bin/bash

# 构建脚本 - Build Script

set -e

echo "🚀 开始构建项目..."

# 检查依赖
echo "📦 检查依赖..."
if ! command -v go &> /dev/null; then
    echo "❌ Go 未安装，请先安装 Go"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，请先安装 Node.js"
    exit 1
fi

# 构建后端
echo "🔧 构建后端..."
cd backend
go mod download
go mod tidy
go build -o bin/server cmd/server/main.go
echo "✅ 后端构建完成"

# 构建前端
echo "🎨 构建前端..."
cd ../frontend
npm ci
npm run build
echo "✅ 前端构建完成"

# 回到项目根目录
cd ..

echo "🎉 项目构建完成！"
echo "📁 后端可执行文件: backend/bin/server"
echo "📁 前端构建文件: frontend/dist/"
