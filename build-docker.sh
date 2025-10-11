#!/bin/bash

# 🍅 Pomodoro Genie Docker构建脚本
# 用于构建前端和后端Docker镜像

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

# 检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker未运行，请先启动Docker"
        exit 1
    fi
    log_success "Docker运行正常"
}

# 构建后端镜像
build_backend() {
    log_info "开始构建后端镜像..."
    
    cd backend
    
    # 检查Dockerfile是否存在
    if [ ! -f "Dockerfile" ]; then
        log_error "后端Dockerfile不存在"
        exit 1
    fi
    
    # 构建镜像
    docker build -t pomodoro-genie/backend:latest .
    
    if [ $? -eq 0 ]; then
        log_success "后端镜像构建成功"
    else
        log_error "后端镜像构建失败"
        exit 1
    fi
    
    cd ..
}

# 构建前端镜像
build_frontend() {
    log_info "开始构建前端镜像..."
    
    cd mobile
    
    # 检查Dockerfile是否存在
    if [ ! -f "Dockerfile" ]; then
        log_error "前端Dockerfile不存在"
        exit 1
    fi
    
    # 构建镜像
    docker build -t pomodoro-genie/frontend:latest .
    
    if [ $? -eq 0 ]; then
        log_success "前端镜像构建成功"
    else
        log_error "前端镜像构建失败"
        exit 1
    fi
    
    cd ..
}

# 验证镜像
verify_images() {
    log_info "验证构建的镜像..."
    
    # 检查后端镜像
    if docker images | grep -q "pomodoro-genie/backend"; then
        log_success "后端镜像验证成功"
        docker images | grep "pomodoro-genie/backend"
    else
        log_error "后端镜像验证失败"
        exit 1
    fi
    
    # 检查前端镜像
    if docker images | grep -q "pomodoro-genie/frontend"; then
        log_success "前端镜像验证成功"
        docker images | grep "pomodoro-genie/frontend"
    else
        log_error "前端镜像验证失败"
        exit 1
    fi
}

# 清理旧镜像（可选）
cleanup_old_images() {
    log_info "清理旧的Docker镜像..."
    
    # 删除悬空镜像
    docker image prune -f
    
    log_success "清理完成"
}

# 主函数
main() {
    log_info "🍅 Pomodoro Genie Docker构建开始"
    
    # 检查Docker
    check_docker
    
    # 构建镜像
    build_backend
    build_frontend
    
    # 验证镜像
    verify_images
    
    # 清理（可选）
    if [ "$1" = "--cleanup" ]; then
        cleanup_old_images
    fi
    
    log_success "🍅 所有镜像构建完成！"
    log_info "使用 'docker-compose up' 启动本地环境"
    log_info "使用 'kubectl apply -f k8s/' 部署到Kubernetes"
}

# 显示帮助
show_help() {
    echo "🍅 Pomodoro Genie Docker构建脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --cleanup    构建完成后清理旧镜像"
    echo "  --help       显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                    # 构建所有镜像"
    echo "  $0 --cleanup          # 构建并清理"
}

# 处理参数
case "$1" in
    --help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
