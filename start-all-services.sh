#!/bin/bash

echo "🚀 启动Pomodoro Genie完整应用栈"
echo "================================"

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

# 检测Docker权限
if docker ps &> /dev/null 2>&1; then
    DOCKER_CMD="docker"
    COMPOSE_CMD="docker-compose"
    log_success "Docker权限正常"
elif sudo -n docker ps &> /dev/null 2>&1; then
    DOCKER_CMD="sudo docker"
    COMPOSE_CMD="sudo docker-compose"
    log_warning "需要sudo权限运行Docker"
else
    log_error "Docker权限问题，请先运行以下命令："
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    echo "或者使用sudo权限："
    echo "  sudo ./start-all-services.sh"
    exit 1
fi

echo ""
log_info "步骤1: 检查和启动数据库服务"
echo "================================"

# 检查docker-compose配置文件
if [ -f "docker-compose.simple.yml" ]; then
    DEFAULT_COMPOSE_FILE="docker-compose.simple.yml"
    log_info "发现简化配置文件"
elif [ -f "docker-compose.yml" ]; then
    DEFAULT_COMPOSE_FILE="docker-compose.yml"
    log_info "发现标准配置文件"
else
    log_error "未找到docker-compose配置文件"
    exit 1
fi

echo "使用配置文件: $DEFAULT_COMPOSE_FILE"

# 检查服务状态
echo ""
log_info "检查当前服务状态..."
$COMPOSE_CMD -f $DEFAULT_COMPOSE_FILE ps

echo ""
log_info "启动/更新数据库服务..."
$COMPOSE_CMD -f $DEFAULT_COMPOSE_FILE up -d

# 等待服务启动
echo ""
log_info "等待服务启动完成..."
sleep 10

echo ""
log_info "检查服务健康状态..."
$COMPOSE_CMD -f $DEFAULT_COMPOSE_FILE ps

echo ""
log_success "数据库服务启动完成"

echo ""
log_info "步骤2: 准备Go后端服务"
echo "=========================="

# 检查Go是否安装
if ! command -v go &> /dev/null; then
    log_error "Go未安装，请先安装Go 1.21+"
    echo "安装方法："
    echo "  wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz"
    echo "  sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz"
    echo "  export PATH=\$PATH:/usr/local/go/bin"
    exit 1
fi

log_success "Go已安装: $(go version)"

# 进入后端目录
cd backend || {
    log_error "backend目录不存在"
    exit 1
}

# 初始化Go模块
if [ ! -f "go.mod" ]; then
    log_info "初始化Go模块..."
    go mod init github.com/pomodoro-team/pomodoro-app/backend
fi

# 安装依赖
log_info "安装Go依赖..."
go mod tidy

# 检查是否有main.go
if [ ! -f "main.go" ] && [ ! -f "cmd/server/main.go" ]; then
    log_warning "未找到main.go，创建简单的服务器..."

    mkdir -p cmd/server
    cat > cmd/server/main.go << 'EOF'
package main

import (
    "log"
    "net/http"
    "os"

    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
)

func main() {
    // 加载环境变量
    if err := godotenv.Load("../../.env"); err != nil {
        log.Println("未找到.env文件，使用默认配置")
    }

    // 创建Gin路由
    r := gin.Default()

    // 健康检查
    r.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "status": "ok",
            "message": "Pomodoro Genie API正在运行",
            "version": "1.0.0",
        })
    })

    // API版本1路由组
    v1 := r.Group("/v1")
    {
        // 认证路由
        auth := v1.Group("/auth")
        {
            auth.POST("/register", func(c *gin.Context) {
                c.JSON(200, gin.H{"message": "注册端点 - 开发中"})
            })
            auth.POST("/login", func(c *gin.Context) {
                c.JSON(200, gin.H{"message": "登录端点 - 开发中"})
            })
        }

        // 任务路由
        tasks := v1.Group("/tasks")
        {
            tasks.GET("/", func(c *gin.Context) {
                c.JSON(200, gin.H{"message": "任务列表 - 开发中"})
            })
            tasks.POST("/", func(c *gin.Context) {
                c.JSON(201, gin.H{"message": "创建任务 - 开发中"})
            })
        }

        // Pomodoro路由
        pomodoro := v1.Group("/pomodoro")
        {
            pomodoro.POST("/sessions", func(c *gin.Context) {
                c.JSON(201, gin.H{"message": "开始Pomodoro会话 - 开发中"})
            })
        }

        // 报告路由
        reports := v1.Group("/reports")
        {
            reports.GET("/", func(c *gin.Context) {
                c.JSON(200, gin.H{"message": "生成报告 - 开发中"})
            })
        }
    }

    // 获取端口
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("🚀 Pomodoro Genie API启动在端口 %s", port)
    log.Printf("🔗 健康检查: http://localhost:%s/health", port)
    log.Printf("📊 API文档: http://localhost:%s/v1", port)

    if err := r.Run(":" + port); err != nil {
        log.Fatal("服务器启动失败:", err)
    }
}
EOF

    # 添加基础依赖到go.mod
    go get github.com/gin-gonic/gin
    go get github.com/joho/godotenv

    log_success "创建了基础API服务器"
fi

# 返回根目录
cd ..

echo ""
log_info "步骤3: 启动Go后端API"
echo "===================="

# 后台启动Go服务器
log_info "启动Go API服务器..."

# 设置环境变量
export PORT=8080
export GIN_MODE=debug

# 启动服务器 (后台运行)
cd backend
if [ -f "cmd/server/main.go" ]; then
    nohup go run cmd/server/main.go > ../api-server.log 2>&1 &
    API_PID=$!
    echo $API_PID > ../api-server.pid
    log_success "Go API服务器已启动 (PID: $API_PID)"
    log_info "日志文件: $(pwd)/../api-server.log"
elif [ -f "main.go" ]; then
    nohup go run main.go > ../api-server.log 2>&1 &
    API_PID=$!
    echo $API_PID > ../api-server.pid
    log_success "Go API服务器已启动 (PID: $API_PID)"
else
    log_warning "未找到可执行的Go文件，跳过API服务器启动"
fi

cd ..

# 等待API服务器启动
sleep 5

echo ""
log_info "步骤4: 测试服务连接"
echo "=================="

# 测试数据库连接
log_info "测试数据库连接..."
if [ "$DEFAULT_COMPOSE_FILE" = "docker-compose.simple.yml" ]; then
    DB_PORT=5432
    API_URL="http://localhost:54321"
    ADMIN_URL="http://localhost:8080/admin"
    GATEWAY_URL="http://localhost:8080"
else
    DB_PORT=5432
    API_URL="http://localhost:54321"
    ADMIN_URL="http://localhost:3000"
    GATEWAY_URL="http://localhost:8080"
fi

# 测试PostgreSQL
if nc -z localhost $DB_PORT 2>/dev/null; then
    log_success "PostgreSQL数据库连接正常 (端口$DB_PORT)"
else
    log_warning "PostgreSQL数据库连接失败"
fi

# 测试PostgREST API
if curl -s $API_URL >/dev/null 2>&1; then
    log_success "PostgREST API连接正常 ($API_URL)"
else
    log_warning "PostgREST API连接失败"
fi

# 测试Go API
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    log_success "Go API服务器连接正常 (http://localhost:8080)"
else
    log_warning "Go API服务器可能还在启动中..."
fi

echo ""
log_info "步骤5: 准备前端应用"
echo "=================="

# 检查Flutter
if command -v flutter &> /dev/null; then
    log_success "Flutter已安装: $(flutter --version | head -1)"

    # 进入mobile目录
    if [ -d "mobile" ]; then
        cd mobile

        log_info "安装Flutter依赖..."
        flutter pub get

        log_info "检查Flutter设备..."
        flutter devices

        cd ..
        log_success "Flutter应用准备就绪"
    else
        log_warning "mobile目录不存在"
    fi
else
    log_warning "Flutter未安装，跳过移动应用"
    log_info "安装Flutter: ./install-flutter.sh"
fi

echo ""
echo "🎉 所有服务启动完成！"
echo "==================="

echo ""
echo "📊 服务访问地址："
echo "================================"

if [ "$DEFAULT_COMPOSE_FILE" = "docker-compose.simple.yml" ]; then
    echo "🌐 主页/网关:     http://localhost:8080"
    echo "🗄️ 数据库管理:    http://localhost:8080/admin"
    echo "🔌 REST API:      http://localhost:54321"
    echo "🚀 Go API:        http://localhost:8080/health"
    echo "🗃️ PostgreSQL:    localhost:5432"
    echo "⚡ Redis:         localhost:6379"
else
    echo "🎨 Supabase Studio: http://localhost:3000"
    echo "🔌 REST API:        http://localhost:54321"
    echo "🚀 Go API:          http://localhost:8080/health"
    echo "🗃️ PostgreSQL:      localhost:5432"
    echo "⚡ Realtime:        http://localhost:4000"
    echo "📊 Meta API:        http://localhost:8080"
fi

echo ""
echo "📱 应用启动："
echo "================================"
echo "• 移动应用:  cd mobile && flutter run"
echo "• Web应用:   cd mobile && flutter run -d web"
echo "• 桌面应用:  cd desktop && cargo tauri dev"

echo ""
echo "🧪 测试命令："
echo "================================"
echo "• API健康检查:  curl http://localhost:8080/health"
echo "• 数据库测试:   psql -h localhost -p 5432 -U postgres -d postgres"
echo "• 手动测试:     cd backend/tests/manual && make test-all"

echo ""
echo "📊 监控命令："
echo "================================"
echo "• 查看服务状态: $COMPOSE_CMD -f $DEFAULT_COMPOSE_FILE ps"
echo "• 查看日志:     $COMPOSE_CMD -f $DEFAULT_COMPOSE_FILE logs -f"
echo "• 查看API日志:  tail -f api-server.log"

echo ""
echo "🛑 停止服务："
echo "================================"
echo "• 停止数据库:   $COMPOSE_CMD -f $DEFAULT_COMPOSE_FILE down"
echo "• 停止API:      kill \$(cat api-server.pid) 2>/dev/null"
echo "• 停止所有:     ./stop-all-services.sh"

echo ""
echo "🎯 下一步："
echo "================================"
echo "1. 测试API连接:    curl http://localhost:8080/health"
echo "2. 访问数据库界面: 浏览器打开相应的管理地址"
echo "3. 启动Flutter应用: cd mobile && flutter run"
echo "4. 运行测试套件:   cd backend/tests/manual && make validate-setup"

echo ""
log_success "Pomodoro Genie应用栈启动完成！🎉"