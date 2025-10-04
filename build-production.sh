#!/bin/bash

# Pomodoro Genie生产环境构建脚本
echo "🏗️ Building Pomodoro Genie for Production"
echo "========================================"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# 1. 构建Flutter Web生产版本
log_info "构建Flutter Web生产版本..."
cd mobile
flutter build web --release --web-renderer html

if [ $? -eq 0 ]; then
    log_success "Flutter Web构建完成"
else
    log_warning "Flutter Web构建失败，继续使用静态版本"
fi

# 2. 构建Go API生产版本
log_info "构建Go API生产版本..."
cd ../backend
go build -o pomodoro-api main.go

if [ $? -eq 0 ]; then
    log_success "Go API构建完成"
else
    log_warning "Go API构建失败"
fi

# 3. 创建生产环境目录
log_info "创建生产环境目录..."
cd ..
mkdir -p production/{web,api,config}

# 4. 复制文件到生产目录
log_info "复制文件到生产目录..."

# 复制Web文件
if [ -d "mobile/build/web" ]; then
    cp -r mobile/build/web/* production/web/
    log_success "Flutter Web文件已复制"
else
    # 使用静态HTML版本作为备份
    cp mobile/web/index_demo.html production/web/index.html
    cp mobile/web/manifest.json production/web/
    log_success "静态HTML文件已复制"
fi

# 复制API文件
if [ -f "backend/pomodoro-api" ]; then
    cp backend/pomodoro-api production/api/
    chmod +x production/api/pomodoro-api
    log_success "API文件已复制"
fi

# 复制配置文件
cp docker-compose.yml production/config/
cp .env production/config/
log_success "配置文件已复制"

log_success "生产环境构建完成！"
echo ""
echo "📁 生产文件位置:"
echo "   Web应用: ./production/web/"
echo "   API服务: ./production/api/"
echo "   配置文件: ./production/config/"
echo ""
echo "🚀 下一步: 部署到生产服务器"