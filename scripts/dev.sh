#!/bin/bash

# 开发环境启动脚本 - Development Script

set -e

echo "🚀 启动开发环境..."

# 检查是否安装了必要的工具
if ! command -v go &> /dev/null; then
    echo "❌ Go 未安装，请先安装 Go"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，请先安装 Node.js"
    exit 1
fi

# 检查环境文件
if [ ! -f "backend/.env" ]; then
    echo "⚠️ 后端 .env 文件不存在，正在复制示例文件..."
    cp backend/env.example backend/.env
    echo "📝 请编辑 backend/.env 文件配置你的环境变量"
fi

if [ ! -f "frontend/.env" ]; then
    echo "⚠️ 前端 .env 文件不存在，正在创建..."
    cat > frontend/.env << EOF
VITE_API_BASE_URL=http://localhost:8080/api/v1
VITE_APP_TITLE=Genie
EOF
fi

# 安装依赖
echo "📦 安装后端依赖..."
cd backend
go mod download

echo "📦 安装前端依赖..."
cd ../frontend
npm install

# 启动开发服务器
echo "🎯 启动开发服务器..."
cd ..

# 使用 trap 确保子进程在脚本退出时被清理
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# 启动后端
echo "🔧 启动后端服务器 (localhost:8080)..."
cd backend && go run cmd/server/main.go &

# 启动前端
echo "🎨 启动前端服务器 (localhost:3000)..."
cd ../frontend && npm run dev &

# 等待服务器启动
sleep 3

echo "✅ 开发环境已启动！"
echo "🌐 前端: http://localhost:3000"
echo "🔧 后端: http://localhost:8080"
echo "📚 API文档: http://localhost:8080/swagger/"
echo ""
echo "按 Ctrl+C 停止所有服务"

# 保持脚本运行
wait
