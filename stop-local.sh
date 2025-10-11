#!/bin/bash

# 🍅 Pomodoro Genie 停止本地服务脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 停止后端服务
stop_backend() {
    if [ -f "logs/backend.pid" ]; then
        BACKEND_PID=$(cat logs/backend.pid)
        log_info "停止后端服务 (PID: $BACKEND_PID)..."
        
        if kill $BACKEND_PID 2>/dev/null; then
            log_success "后端服务已停止"
        else
            log_warning "后端服务可能已经停止"
        fi
        
        rm -f logs/backend.pid
    else
        log_warning "未找到后端服务PID文件"
    fi
}

# 停止前端服务
stop_frontend() {
    if [ -f "logs/frontend.pid" ]; then
        FRONTEND_PID=$(cat logs/frontend.pid)
        log_info "停止前端服务 (PID: $FRONTEND_PID)..."
        
        if kill $FRONTEND_PID 2>/dev/null; then
            log_success "前端服务已停止"
        else
            log_warning "前端服务可能已经停止"
        fi
        
        rm -f logs/frontend.pid
    else
        log_warning "未找到前端服务PID文件"
    fi
}

# 停止PostgreSQL容器
stop_postgres() {
    log_info "停止PostgreSQL容器..."
    
    if docker ps | grep -q "pomodoro-postgres"; then
        docker stop pomodoro-postgres
        docker rm pomodoro-postgres
        log_success "PostgreSQL容器已停止并删除"
    else
        log_warning "PostgreSQL容器未运行"
    fi
}

# 清理进程
cleanup_processes() {
    log_info "清理相关进程..."
    
    # 停止可能的后端进程
    pkill -f "backend/main" 2>/dev/null || true
    
    # 停止可能的前端进程
    pkill -f "python3 -m http.server 3001" 2>/dev/null || true
    
    # 停止nginx进程（如果存在）
    pkill -f "nginx.*3001" 2>/dev/null || true
    
    log_success "进程清理完成"
}

# 显示状态
show_status() {
    log_info "服务状态检查："
    
    echo ""
    echo "🔍 端口占用情况："
    if lsof -i :8081 >/dev/null 2>&1; then
        echo "  端口8081: 被占用"
    else
        echo "  端口8081: 空闲"
    fi
    
    if lsof -i :3001 >/dev/null 2>&1; then
        echo "  端口3001: 被占用"
    else
        echo "  端口3001: 空闲"
    fi
    
    if lsof -i :5432 >/dev/null 2>&1; then
        echo "  端口5432: 被占用"
    else
        echo "  端口5432: 空闲"
    fi
    
    echo ""
    echo "🐳 Docker容器状态："
    if docker ps | grep -q "postgres"; then
        echo "  PostgreSQL: 运行中"
    else
        echo "  PostgreSQL: 已停止"
    fi
}

# 主函数
main() {
    log_info "🍅 Pomodoro Genie 停止服务开始"
    
    # 停止服务
    stop_backend
    stop_frontend
    stop_postgres
    
    # 清理进程
    cleanup_processes
    
    # 显示状态
    show_status
    
    log_success "🍅 所有服务已停止！"
}

# 显示帮助
show_help() {
    echo "🍅 Pomodoro Genie 停止本地服务脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --status      显示服务状态"
    echo "  --help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                    # 停止所有服务"
    echo "  $0 --status           # 查看服务状态"
}

# 处理参数
case "$1" in
    --status)
        show_status
        ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac
