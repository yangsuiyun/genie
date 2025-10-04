#!/bin/bash

echo "🛑 停止Pomodoro Genie所有服务"
echo "============================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 检测Docker权限
if docker ps &> /dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif sudo -n docker ps &> /dev/null 2>&1; then
    COMPOSE_CMD="sudo docker-compose"
else
    COMPOSE_CMD="sudo docker-compose"
    log_warning "需要sudo权限"
fi

# 停止Go API服务器
if [ -f "api-server.pid" ]; then
    API_PID=$(cat api-server.pid)
    log_info "停止Go API服务器 (PID: $API_PID)..."
    kill $API_PID 2>/dev/null && log_success "Go API服务器已停止" || log_warning "Go API服务器进程未找到"
    rm -f api-server.pid
fi

# 停止Docker服务
log_info "停止Docker服务..."

if [ -f "docker-compose.simple.yml" ]; then
    $COMPOSE_CMD -f docker-compose.simple.yml down
elif [ -f "docker-compose.yml" ]; then
    $COMPOSE_CMD -f docker-compose.yml down
fi

log_success "所有服务已停止"

# 清理日志文件
if [ -f "api-server.log" ]; then
    log_info "保留日志文件: api-server.log"
fi

echo ""
echo "✅ 服务停止完成"
echo "• Docker服务已停止"
echo "• Go API服务器已停止"
echo "• 日志文件已保留"