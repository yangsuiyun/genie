#!/bin/bash

# Pomodoro Genie 启动脚本
# 启动前端和后端服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        log_warn "端口 $port 被占用，正在终止占用进程..."
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# 检查Flutter环境
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter 未安装或未在PATH中"
        log_info "请确保Flutter已安装并配置PATH: export PATH=\"\$PATH:\$HOME/flutter/bin\""
        exit 1
    fi
}

# 检查Go环境
check_go() {
    if ! command -v go &> /dev/null; then
        log_error "Go 未安装或未在PATH中"
        exit 1
    fi
}

# 启动前端
start_frontend() {
    log_info "启动Flutter前端..."
    
    # 设置Flutter环境变量
    export PATH="$PATH:$HOME/flutter/bin"
    export PUB_HOSTED_URL=https://pub.flutter-io.cn
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    
    cd mobile
    
    # 检查依赖
    if [ ! -f "pubspec.lock" ]; then
        log_info "安装Flutter依赖..."
        flutter pub get
    fi
    
    # 启动Flutter应用
    log_info "启动Flutter Web服务器 (端口 3001)..."
    flutter run -d web-server --web-port 3001 &
    FRONTEND_PID=$!
    
    cd ..
    
    log_info "前端启动完成，PID: $FRONTEND_PID"
}

# 启动后端
start_backend() {
    log_info "启动Go后端..."
    
    cd backend
    
    # 检查依赖
    if [ ! -f "go.sum" ]; then
        log_info "下载Go依赖..."
        go mod download
    fi
    
    # 启动Go应用
    log_info "启动Go服务器 (端口 8081)..."
    go run cmd/main.go &
    BACKEND_PID=$!
    
    cd ..
    
    log_info "后端启动完成，PID: $BACKEND_PID"
}

# 主函数
main() {
    log_info "🚀 启动 Pomodoro Genie..."
    
    # 检查环境
    check_flutter
    
    # 检查端口
    check_port 3001
    
    # 启动服务
    start_frontend
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 5
    
    # 检查服务状态
    if curl -s http://localhost:3001 > /dev/null; then
        log_info "✅ 前端服务运行正常: http://localhost:3001"
    else
        log_warn "⚠️  前端服务可能未正常启动"
    fi
    
    log_info "🎉 前端服务已启动！"
    log_info "前端: http://localhost:3001"
    log_info ""
    log_info "按 Ctrl+C 停止服务"
    
    # 等待用户中断
    wait
}

# 清理函数
cleanup() {
    log_info "正在停止服务..."
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    log_info "服务已停止"
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 运行主函数
main