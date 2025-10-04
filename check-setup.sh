#!/bin/bash

echo "🔍 Pomodoro Genie 设置检查"
echo "========================"

# 检查必需文件
echo "📁 文件检查："
if [ -f "docker-compose.yml" ]; then
    echo "  ✅ docker-compose.yml 存在"
else
    echo "  ❌ docker-compose.yml 缺失"
fi

if [ -f ".env" ]; then
    echo "  ✅ .env 文件存在"
else
    echo "  ❌ .env 文件缺失"
fi

if [ -f "backend/migrations/init.sql" ]; then
    echo "  ✅ 数据库迁移文件存在"
else
    echo "  ❌ 数据库迁移文件缺失"
fi

echo ""

# 检查Docker
echo "🐳 Docker 检查："
if command -v docker &> /dev/null; then
    echo "  ✅ Docker 已安装: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
else
    echo "  ❌ Docker 未安装"
fi

if command -v docker-compose &> /dev/null; then
    echo "  ✅ Docker Compose 已安装: $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)"
else
    echo "  ❌ Docker Compose 未安装"
fi

# 检查Docker权限
echo ""
echo "🔐 权限检查："
if docker ps &> /dev/null; then
    echo "  ✅ Docker 可以无sudo运行"
    DOCKER_CMD="docker-compose"
elif sudo docker ps &> /dev/null 2>&1; then
    echo "  ⚠️  Docker 需要sudo权限"
    DOCKER_CMD="sudo docker-compose"
else
    echo "  ❌ Docker 不可用"
    exit 1
fi

echo ""

# 检查端口占用
echo "🔌 端口检查："
ports=(3000 5432 54321 4000 8080)
for port in "${ports[@]}"; do
    if lsof -i:$port &> /dev/null; then
        echo "  ⚠️  端口 $port 被占用"
    else
        echo "  ✅ 端口 $port 可用"
    fi
done

echo ""
echo "🚀 准备启动？"
echo "   运行: $DOCKER_CMD up -d"
echo ""
echo "📊 手动测试设置："
echo "   cd backend/tests/manual"
echo "   make validate-setup"