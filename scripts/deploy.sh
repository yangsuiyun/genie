#!/bin/bash

# 部署脚本 - Deploy Script

set -e

echo "🚀 开始部署..."

# 环境变量检查
if [ -z "$DEPLOY_TOKEN" ]; then
    echo "❌ DEPLOY_TOKEN 环境变量未设置"
    exit 1
fi

# 构建项目
echo "📦 构建项目..."
./scripts/build.sh

# 创建部署包
echo "📦 创建部署包..."
mkdir -p deploy
cp -r backend/bin deploy/
cp -r frontend/dist deploy/static
cp backend/env.example deploy/.env.example

# 压缩部署包
echo "🗜️ 压缩部署包..."
tar -czf deploy.tar.gz -C deploy .

echo "✅ 部署包创建完成: deploy.tar.gz"

# 这里可以添加实际的部署逻辑
# 例如：上传到服务器、Docker 构建等

echo "🎉 部署完成！"
