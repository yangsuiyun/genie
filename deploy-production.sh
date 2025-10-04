#!/bin/bash

# Pomodoro Genie生产环境部署脚本
echo "🚀 Deploying Pomodoro Genie to Production"
echo "========================================"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

# 检查环境变量文件
if [ ! -f ".env" ]; then
    log_warning ".env文件不存在，从模板创建..."
    cp .env.example .env
    log_info "请编辑.env文件设置生产环境变量"
    exit 1
fi

# 构建生产版本
log_info "构建生产版本..."
bash build-production.sh

if [ $? -ne 0 ]; then
    log_error "构建失败"
    exit 1
fi

# 停止现有服务
log_info "停止现有服务..."
docker-compose -f docker-compose.production.yml down

# 构建Docker镜像
log_info "构建Docker镜像..."
docker-compose -f docker-compose.production.yml build --no-cache

# 启动生产服务
log_info "启动生产服务..."
docker-compose -f docker-compose.production.yml up -d

# 等待服务启动
log_info "等待服务启动..."
sleep 30

# 健康检查
log_info "执行健康检查..."

# 检查数据库
if docker-compose -f docker-compose.production.yml exec -T database pg_isready -U postgres; then
    log_success "数据库健康检查通过"
else
    log_error "数据库健康检查失败"
fi

# 检查Redis
if docker-compose -f docker-compose.production.yml exec -T redis redis-cli ping | grep -q PONG; then
    log_success "Redis健康检查通过"
else
    log_error "Redis健康检查失败"
fi

# 检查API
if curl -f http://localhost:8081/health > /dev/null 2>&1; then
    log_success "API健康检查通过"
else
    log_error "API健康检查失败"
fi

# 检查Web服务
if curl -f http://localhost > /dev/null 2>&1; then
    log_success "Web服务健康检查通过"
else
    log_error "Web服务健康检查失败"
fi

# 显示服务状态
echo ""
log_info "服务状态:"
docker-compose -f docker-compose.production.yml ps

echo ""
log_success "生产环境部署完成！"
echo ""
echo "🌐 访问地址:"
echo "   Web应用: http://localhost (HTTP) 或 https://localhost (HTTPS)"
echo "   API接口: http://localhost/api"
echo "   健康检查: http://localhost/health"
echo ""
echo "📊 监控地址:"
echo "   Prometheus: http://localhost:9090"
echo ""
echo "🔧 管理命令:"
echo "   查看日志: docker-compose -f docker-compose.production.yml logs -f"
echo "   重启服务: docker-compose -f docker-compose.production.yml restart"
echo "   停止服务: docker-compose -f docker-compose.production.yml down"
echo ""

# SSL证书提醒
if [ ! -d "ssl" ]; then
    log_warning "SSL证书目录不存在"
    echo "🔐 设置HTTPS证书:"
    echo "   1. 创建ssl目录: mkdir ssl"
    echo "   2. 将证书文件放入: ssl/fullchain.pem 和 ssl/privkey.pem"
    echo "   3. 或使用Let's Encrypt:"
    echo "      certbot certonly --webroot -w /var/www/certbot -d your-domain.com"
fi