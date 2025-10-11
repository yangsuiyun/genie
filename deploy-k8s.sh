#!/bin/bash

# 🍅 Pomodoro Genie Kubernetes部署脚本
# 用于部署应用到Kubernetes集群

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

# 检查kubectl是否安装
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl未安装，请先安装kubectl"
        exit 1
    fi
    log_success "kubectl已安装"
}

# 检查kubectl连接
check_kubectl_connection() {
    log_info "检查Kubernetes集群连接..."
    
    if kubectl cluster-info &> /dev/null; then
        log_success "Kubernetes集群连接正常"
        kubectl cluster-info
    else
        log_error "无法连接到Kubernetes集群"
        log_info "请确保kubeconfig配置正确"
        exit 1
    fi
}

# 创建命名空间
create_namespace() {
    log_info "创建命名空间..."
    
    kubectl apply -f k8s/secrets.yaml
    
    if [ $? -eq 0 ]; then
        log_success "命名空间和密钥创建成功"
    else
        log_error "命名空间创建失败"
        exit 1
    fi
}

# 部署PostgreSQL
deploy_postgres() {
    log_info "部署PostgreSQL数据库..."
    
    kubectl apply -f k8s/postgres-deployment.yaml
    
    log_info "等待PostgreSQL启动..."
    kubectl wait --for=condition=ready pod -l app=postgres -n pomodoro-genie --timeout=300s
    
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL部署成功"
    else
        log_error "PostgreSQL部署失败"
        exit 1
    fi
}

# 部署后端服务
deploy_backend() {
    log_info "部署后端服务..."
    
    kubectl apply -f k8s/backend-deployment.yaml
    
    log_info "等待后端服务启动..."
    kubectl wait --for=condition=ready pod -l app=pomodoro-backend -n pomodoro-genie --timeout=300s
    
    if [ $? -eq 0 ]; then
        log_success "后端服务部署成功"
    else
        log_error "后端服务部署失败"
        exit 1
    fi
}

# 部署前端服务
deploy_frontend() {
    log_info "部署前端服务..."
    
    kubectl apply -f k8s/frontend-deployment.yaml
    
    log_info "等待前端服务启动..."
    kubectl wait --for=condition=ready pod -l app=pomodoro-frontend -n pomodoro-genie --timeout=300s
    
    if [ $? -eq 0 ]; then
        log_success "前端服务部署成功"
    else
        log_error "前端服务部署失败"
        exit 1
    fi
}

# 配置Ingress
deploy_ingress() {
    log_info "配置Ingress..."
    
    kubectl apply -f k8s/ingress.yaml
    
    if [ $? -eq 0 ]; then
        log_success "Ingress配置成功"
    else
        log_warning "Ingress配置失败，可能需要安装Ingress Controller"
    fi
}

# 显示部署状态
show_status() {
    log_info "部署状态："
    
    echo ""
    echo "📊 Pods状态："
    kubectl get pods -n pomodoro-genie
    
    echo ""
    echo "🌐 Services状态："
    kubectl get services -n pomodoro-genie
    
    echo ""
    echo "🔗 Ingress状态："
    kubectl get ingress -n pomodoro-genie
    
    echo ""
    echo "💾 PVC状态："
    kubectl get pvc -n pomodoro-genie
}

# 获取访问信息
get_access_info() {
    log_info "获取访问信息..."
    
    echo ""
    echo "🌍 访问方式："
    echo "1. 通过Ingress访问："
    echo "   - 前端: http://pomodoro-genie.local"
    echo "   - API: http://pomodoro-genie.local/api"
    echo ""
    echo "2. 通过端口转发访问："
    echo "   kubectl port-forward -n pomodoro-genie service/pomodoro-frontend-service 3001:80"
    echo "   kubectl port-forward -n pomodoro-genie service/pomodoro-backend-service 8081:8081"
    echo ""
    echo "3. 查看日志："
    echo "   kubectl logs -n pomodoro-genie -l app=pomodoro-backend"
    echo "   kubectl logs -n pomodoro-genie -l app=pomodoro-frontend"
}

# 清理部署
cleanup() {
    log_warning "清理Pomodoro Genie部署..."
    
    kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
    kubectl delete -f k8s/frontend-deployment.yaml --ignore-not-found=true
    kubectl delete -f k8s/backend-deployment.yaml --ignore-not-found=true
    kubectl delete -f k8s/postgres-deployment.yaml --ignore-not-found=true
    kubectl delete -f k8s/secrets.yaml --ignore-not-found=true
    
    log_success "清理完成"
}

# 主函数
main() {
    log_info "🍅 Pomodoro Genie Kubernetes部署开始"
    
    # 检查环境
    check_kubectl
    check_kubectl_connection
    
    # 部署服务
    create_namespace
    deploy_postgres
    deploy_backend
    deploy_frontend
    deploy_ingress
    
    # 显示状态
    show_status
    get_access_info
    
    log_success "🍅 Pomodoro Genie部署完成！"
}

# 显示帮助
show_help() {
    echo "🍅 Pomodoro Genie Kubernetes部署脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --status      显示部署状态"
    echo "  --cleanup     清理所有部署"
    echo "  --help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                    # 完整部署"
    echo "  $0 --status           # 查看状态"
    echo "  $0 --cleanup          # 清理部署"
}

# 处理参数
case "$1" in
    --status)
        show_status
        get_access_info
        ;;
    --cleanup)
        cleanup
        ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac
