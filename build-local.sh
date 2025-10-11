#!/bin/bash

# 🍅 Pomodoro Genie 本地构建和启动脚本
# 绕过Docker网络问题，使用本地编译和运行

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

# 检查Go环境
check_go() {
    if ! command -v go &> /dev/null; then
        log_error "Go未安装，请先安装Go"
        exit 1
    fi
    
    GO_VERSION=$(go version | cut -d' ' -f3)
    log_success "Go已安装: $GO_VERSION"
}

# 检查Flutter环境
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_warning "Flutter未安装，将跳过前端构建"
        return 1
    fi
    
    FLUTTER_VERSION=$(flutter --version | head -1)
    log_success "Flutter已安装: $FLUTTER_VERSION"
    return 0
}

# 检查PostgreSQL
check_postgres() {
    if ! command -v psql &> /dev/null; then
        log_warning "PostgreSQL客户端未安装，将使用Docker运行数据库"
        return 1
    fi
    
    log_success "PostgreSQL客户端已安装"
    return 0
}

# 启动PostgreSQL数据库
start_postgres() {
    log_info "启动PostgreSQL数据库..."
    
    # 检查是否已有PostgreSQL容器运行
    if docker ps | grep -q "postgres"; then
        log_info "PostgreSQL容器已在运行"
        return 0
    fi
    
    # 启动PostgreSQL容器
    docker run -d \
        --name pomodoro-postgres \
        -e POSTGRES_DB=pomodoro_genie \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=postgres \
        -p 5432:5432 \
        postgres:15-alpine
    
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL容器启动成功"
        
        # 等待数据库启动
        log_info "等待数据库启动..."
        sleep 10
        
        # 测试连接
        for i in {1..30}; do
            if docker exec pomodoro-postgres pg_isready -U postgres > /dev/null 2>&1; then
                log_success "数据库连接成功"
                return 0
            fi
            sleep 2
        done
        
        log_error "数据库启动超时"
        return 1
    else
        log_error "PostgreSQL容器启动失败"
        return 1
    fi
}

# 构建后端
build_backend() {
    log_info "构建后端服务..."
    
    cd backend
    
    # 检查go.mod
    if [ ! -f "go.mod" ]; then
        log_error "go.mod文件不存在"
        exit 1
    fi
    
    # 下载依赖
    log_info "下载Go依赖..."
    go mod download
    
    # 构建应用
    log_info "编译后端应用..."
    go build -o main cmd/main_simple.go
    
    if [ $? -eq 0 ]; then
        log_success "后端构建成功"
    else
        log_error "后端构建失败"
        exit 1
    fi
    
    cd ..
}

# 构建前端
build_frontend() {
    if ! check_flutter; then
        log_warning "跳过前端构建"
        return 0
    fi
    
    log_info "构建前端应用..."
    
    cd mobile
    
    # 检查pubspec.yaml
    if [ ! -f "pubspec.yaml" ]; then
        log_error "pubspec.yaml文件不存在"
        exit 1
    fi
    
    # 获取依赖
    log_info "获取Flutter依赖..."
    flutter pub get
    
    # 构建Web应用
    log_info "构建Flutter Web应用..."
    flutter build web --release
    
    if [ $? -eq 0 ]; then
        log_success "前端构建成功"
    else
        log_error "前端构建失败"
        exit 1
    fi
    
    cd ..
}

# 启动后端服务
start_backend() {
    log_info "启动后端服务..."
    
    cd backend
    
    # 设置环境变量
    export PORT=8081
    export GIN_MODE=release
    export DB_HOST=localhost
    export DB_PORT=5432
    export DB_USER=postgres
    export DB_PASSWORD=postgres
    export DB_NAME=pomodoro_genie
    export DB_SSLMODE=disable
    export DB_LOG_LEVEL=info
    export JWT_SECRET=pomodoro-genie-jwt-secret
    export JWT_EXPIRE_HOURS=24
    export CORS_ALLOWED_ORIGINS=http://localhost:3001
    
    # 后台启动后端服务
    nohup ./main > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    
    # 等待服务启动
    sleep 5
    
    # 检查服务是否启动
    if curl -f http://localhost:8081/health > /dev/null 2>&1; then
        log_success "后端服务启动成功 (PID: $BACKEND_PID)"
        echo $BACKEND_PID > ../logs/backend.pid
    else
        log_error "后端服务启动失败"
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    
    cd ..
}

# 启动前端服务
start_frontend() {
    log_info "启动前端服务..."
    
    # 检查是否有nginx
    if command -v nginx &> /dev/null; then
        # 使用nginx启动前端
        cd mobile/build/web
        
        # 创建nginx配置
        cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 3001;
        server_name localhost;
        root .;
        index index.html;
        
        location / {
            try_files $uri $uri/ /index.html;
        }
        
        location /health {
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
        
        # 启动nginx
        nginx -c $(pwd)/nginx.conf -p $(pwd)
        
        if [ $? -eq 0 ]; then
            log_success "前端服务启动成功 (nginx)"
        else
            log_error "前端服务启动失败"
            exit 1
        fi
        
        cd ../../..
    else
        # 使用Python简单HTTP服务器
        cd mobile/build/web
        
        python3 -m http.server 3001 &
        FRONTEND_PID=$!
        
        sleep 2
        
        if curl -f http://localhost:3001 > /dev/null 2>&1; then
            log_success "前端服务启动成功 (Python HTTP Server, PID: $FRONTEND_PID)"
            echo $FRONTEND_PID > ../../logs/frontend.pid
        else
            log_error "前端服务启动失败"
            kill $FRONTEND_PID 2>/dev/null || true
            exit 1
        fi
        
        cd ../../..
    fi
}

# 显示访问信息
show_access_info() {
    log_success "🍅 Pomodoro Genie 启动完成！"
    echo ""
    echo "🌍 访问地址："
    echo "  前端: http://localhost:3001"
    echo "  后端API: http://localhost:8081"
    echo "  健康检查: http://localhost:8081/health"
    echo ""
    echo "📊 服务状态："
    echo "  后端PID: $(cat logs/backend.pid 2>/dev/null || echo '未知')"
    echo "  前端PID: $(cat logs/frontend.pid 2>/dev/null || echo '未知')"
    echo ""
    echo "📝 日志文件："
    echo "  后端日志: logs/backend.log"
    echo "  前端日志: logs/frontend.log"
    echo ""
    echo "🛑 停止服务："
    echo "  ./stop-local.sh"
}

# 创建日志目录
create_logs_dir() {
    mkdir -p logs
}

# 主函数
main() {
    log_info "🍅 Pomodoro Genie 本地构建和启动开始"
    
    # 创建日志目录
    create_logs_dir
    
    # 检查环境
    check_go
    
    # 启动数据库
    start_postgres
    
    # 构建应用
    build_backend
    build_frontend
    
    # 启动服务
    start_backend
    start_frontend
    
    # 显示访问信息
    show_access_info
}

# 显示帮助
show_help() {
    echo "🍅 Pomodoro Genie 本地构建和启动脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help        显示此帮助信息"
    echo ""
    echo "环境要求:"
    echo "  - Go 1.21+"
    echo "  - Flutter (可选)"
    echo "  - Docker (用于PostgreSQL)"
    echo ""
    echo "示例:"
    echo "  $0                    # 完整构建和启动"
}

# 处理参数
case "$1" in
    --help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac
