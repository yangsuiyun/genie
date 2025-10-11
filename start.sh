#!/bin/bash

# 🍅 Pomodoro Genie - 统一启动脚本
# 启动前端和后端服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
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
    
    # 检查Flutter版本
    FLUTTER_VERSION=$(flutter --version | head -n1 | awk '{print $2}')
    log_info "✅ Flutter 版本检查通过: $FLUTTER_VERSION"
}

# 检查Go环境
check_go() {
    if ! command -v go &> /dev/null; then
        log_error "Go 未安装或未在PATH中"
        exit 1
    fi
    
    # 检查Go版本
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    REQUIRED_VERSION="1.21"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        log_error "Go 版本过低，需要 1.21+，当前版本: $GO_VERSION"
        exit 1
    fi
    
    log_info "✅ Go 版本检查通过: $GO_VERSION"
}

# 检查PostgreSQL环境
check_postgresql() {
    if command -v psql &> /dev/null; then
        log_info "✅ PostgreSQL 客户端已安装"
    else
        log_warn "PostgreSQL 客户端未安装，后端服务可能无法连接数据库"
    fi
}

# 启动前端
start_frontend() {
    log_info "🚀 启动Flutter前端..."
    
    # 设置Flutter环境变量
    export PATH="$PATH:$HOME/flutter/bin"
    export PUB_HOSTED_URL=https://pub.flutter-io.cn
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    
    cd mobile
    
    # 检查依赖
    if [ ! -f "pubspec.lock" ]; then
        log_info "📦 安装Flutter依赖..."
        flutter pub get
    fi
    
    # 启动Flutter应用
    log_info "🌐 启动Flutter Web服务器 (端口 3001)..."
    flutter run -d web-server --web-port 3001 &
    FRONTEND_PID=$!
    
    cd ..
    
    log_info "✅ 前端启动完成，PID: $FRONTEND_PID"
}

# 启动后端
start_backend() {
    log_info "🔧 启动Go后端..."
    
    cd backend
    
    # 设置环境变量
    export GIN_MODE=${GIN_MODE:-debug}
    export PORT=${PORT:-8081}
    export DB_HOST=${DB_HOST:-localhost}
    export DB_PORT=${DB_PORT:-5432}
    export DB_USER=${DB_USER:-postgres}
    export DB_PASSWORD=${DB_PASSWORD:-postgres}
    export DB_NAME=${DB_NAME:-pomodoro_genie}
    export DB_SSLMODE=${DB_SSLMODE:-disable}
    export DB_LOG_LEVEL=${DB_LOG_LEVEL:-info}
    
    log_debug "环境配置:"
    log_debug "   - 端口: $PORT"
    log_debug "   - 数据库: $DB_HOST:$DB_PORT/$DB_NAME"
    log_debug "   - 模式: $GIN_MODE"
    
    # 检查数据库连接（可选）
    if command -v psql &> /dev/null; then
        log_info "🔍 检查数据库连接..."
        if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" &> /dev/null; then
            log_info "✅ 数据库连接正常"
        else
            log_warn "⚠️  数据库连接失败，请检查配置"
            log_warn "   提示: 确保 PostgreSQL 正在运行，并且数据库 '$DB_NAME' 已创建"
        fi
    fi
    
    # 检查依赖
    if [ ! -f "go.sum" ]; then
        log_info "📦 下载Go依赖..."
        go mod tidy
    fi
    
    # 启动Go应用
    log_info "🚀 启动Go服务器 (端口 $PORT)..."
    go run cmd/main.go &
    BACKEND_PID=$!
    
    cd ..
    
    log_info "✅ 后端启动完成，PID: $BACKEND_PID"
}

# 检查服务状态
check_services() {
    log_info "🔍 检查服务状态..."
    
    # 等待服务启动
    sleep 5
    
    # 检查前端服务
    if curl -s http://localhost:3001 > /dev/null 2>&1; then
        log_info "✅ 前端服务运行正常: http://localhost:3001"
    else
        log_warn "⚠️  前端服务可能未正常启动"
    fi
    
    # 检查后端服务
    if curl -s http://localhost:8081/health > /dev/null 2>&1; then
        log_info "✅ 后端服务运行正常: http://localhost:8081"
    else
        log_warn "⚠️  后端服务可能未正常启动"
    fi
}

# 显示服务信息
show_services() {
    log_info "🎉 Pomodoro Genie 服务已启动！"
    echo ""
    echo "📱 前端应用: http://localhost:3001"
    echo "🔧 后端API: http://localhost:8081"
    echo "📊 健康检查: http://localhost:8081/health"
    echo "📖 API文档: http://localhost:8081/docs"
    echo ""
    echo "按 Ctrl+C 停止所有服务"
    echo ""
}

# 主函数
main() {
    log_info "🍅 启动 Pomodoro Genie..."
    
    # 检查环境
    check_flutter
    check_go
    check_postgresql
    
    # 检查端口
    check_port 3001
    check_port 8081
    
    # 启动服务
    start_frontend
    start_backend
    
    # 检查服务状态
    check_services
    
    # 显示服务信息
    show_services
    
    # 等待用户中断
    wait
}

# 清理函数
cleanup() {
    log_info "🛑 正在停止服务..."
    
    if [ ! -z "$FRONTEND_PID" ]; then
        log_info "停止前端服务 (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$BACKEND_PID" ]; then
        log_info "停止后端服务 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    # 清理构建文件
    if [ -f "backend/pomodoro-backend" ]; then
        rm -f backend/pomodoro-backend
    fi
    
    log_info "✅ 所有服务已停止"
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 运行主函数
main
