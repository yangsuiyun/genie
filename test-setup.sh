#!/bin/bash

echo "🧪 测试Docker镜像和配置"
echo "====================="

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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查Docker命令
if docker ps &> /dev/null; then
    DOCKER_CMD="docker"
    COMPOSE_CMD="docker-compose"
    log_success "Docker 可以无sudo运行"
elif sudo docker ps &> /dev/null 2>&1; then
    DOCKER_CMD="sudo docker"
    COMPOSE_CMD="sudo docker-compose"
    log_warning "Docker 需要sudo权限"
else
    log_error "Docker 不可用"
    exit 1
fi

# 测试镜像拉取
images=(
    "postgres:15-alpine"
    "postgrest/postgrest:v12.0.2"
    "dpage/pgadmin4:latest"
    "redis:7-alpine"
    "nginx:alpine"
)

echo ""
log_info "测试Docker镜像拉取..."

for image in "${images[@]}"; do
    echo -n "正在测试 $image ... "
    if $DOCKER_CMD pull $image &> /dev/null; then
        log_success "成功"
    else
        log_error "失败"
        echo "尝试从国内镜像源拉取..."

        # 尝试使用阿里云镜像
        if [[ $image == postgres* ]]; then
            alt_image="registry.cn-hangzhou.aliyuncs.com/library/$image"
        elif [[ $image == redis* ]]; then
            alt_image="registry.cn-hangzhou.aliyuncs.com/library/$image"
        elif [[ $image == nginx* ]]; then
            alt_image="registry.cn-hangzhou.aliyuncs.com/library/$image"
        else
            alt_image="$image"
        fi

        if $DOCKER_CMD pull $alt_image &> /dev/null; then
            log_success "从镜像源成功拉取: $alt_image"
            # 重新标记镜像
            $DOCKER_CMD tag $alt_image $image
        else
            log_error "镜像拉取失败: $image"
        fi
    fi
done

echo ""
log_info "验证docker-compose配置..."

# 验证简化配置
if $COMPOSE_CMD -f docker-compose.simple.yml config &> /dev/null; then
    log_success "简化配置有效"
else
    log_error "简化配置无效"
fi

# 验证原始配置
if $COMPOSE_CMD -f docker-compose.yml config &> /dev/null; then
    log_success "原始配置有效"
else
    log_warning "原始配置可能有问题"
fi

echo ""
log_info "检查端口占用..."

ports=(3000 5432 54321 6379 8080)
available_ports=()
occupied_ports=()

for port in "${ports[@]}"; do
    if lsof -i:$port &> /dev/null; then
        occupied_ports+=($port)
        echo "  ⚠️  端口 $port 被占用"
    else
        available_ports+=($port)
        echo "  ✅ 端口 $port 可用"
    fi
done

echo ""
if [ ${#occupied_ports[@]} -gt 0 ]; then
    log_warning "以下端口被占用: ${occupied_ports[*]}"
    echo "请停止占用这些端口的服务或修改docker-compose.yml中的端口映射"
    echo ""
    echo "查看端口占用详情:"
    for port in "${occupied_ports[@]}"; do
        echo "  端口 $port: $(lsof -i:$port | tail -n +2 | head -1 | awk '{print $1, $2}')"
    done
else
    log_success "所有需要的端口都可用"
fi

echo ""
log_info "推荐启动命令:"
echo ""
echo "使用简化配置 (推荐):"
echo "  $COMPOSE_CMD -f docker-compose.simple.yml up -d"
echo ""
echo "使用原始配置:"
echo "  $COMPOSE_CMD up -d"
echo ""
echo "检查服务状态:"
echo "  $COMPOSE_CMD ps"
echo ""
echo "查看日志:"
echo "  $COMPOSE_CMD logs -f"
echo ""
echo "停止服务:"
echo "  $COMPOSE_CMD down"

echo ""
echo "🌐 启动后可访问的服务:"
echo "  • 主页/API网关: http://localhost:8080"
echo "  • 数据库管理: http://localhost:8080/admin"
echo "  • REST API: http://localhost:54321"
echo "  • PostgreSQL: localhost:5432"
echo "  • Redis: localhost:6379"