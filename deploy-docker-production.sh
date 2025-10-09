#!/bin/bash

# 🍅 Pomodoro Genie Docker 生产环境部署脚本
# 一键部署完整的Pomodoro Genie应用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 配置变量
APP_NAME="Pomodoro Genie"
APP_VERSION="1.0.0"
COMPOSE_FILE="docker-compose.production.yml"
ENV_FILE=".env"

echo -e "${BLUE}🍅 ${APP_NAME} Docker 生产环境部署脚本${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "应用名称: ${APP_NAME}"
echo -e "版本: ${APP_VERSION}"
echo -e "配置文件: ${COMPOSE_FILE}"
echo ""

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}📋 检查系统要求...${NC}"
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装，请先安装Docker${NC}"
        echo -e "${YELLOW}💡 安装命令: curl -fsSL https://get.docker.com | sh${NC}"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose未安装${NC}"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker服务未运行，请启动Docker服务${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 系统要求检查通过${NC}"
}

# 检查环境配置
check_environment() {
    echo -e "${YELLOW}⚙️ 检查环境配置...${NC}"
    
    # 检查环境变量文件
    if [ ! -f "${ENV_FILE}" ]; then
        echo -e "${YELLOW}⚠️ 环境变量文件 ${ENV_FILE} 不存在${NC}"
        echo -e "${BLUE}📝 从模板创建环境变量文件...${NC}"
        cp env.production.template "${ENV_FILE}"
        echo -e "${YELLOW}⚠️ 请编辑 ${ENV_FILE} 文件，设置正确的配置值${NC}"
        echo -e "${YELLOW}⚠️ 特别是数据库密码、JWT密钥等敏感信息${NC}"
        read -p "按Enter键继续，或Ctrl+C取消..."
    fi
    
    # 检查必要的环境变量
    source "${ENV_FILE}"
    if [ -z "${POSTGRES_PASSWORD}" ] || [ "${POSTGRES_PASSWORD}" = "your_secure_password_here" ]; then
        echo -e "${RED}❌ 请设置POSTGRES_PASSWORD${NC}"
        exit 1
    fi
    
    if [ -z "${JWT_SECRET}" ] || [ "${JWT_SECRET}" = "your_jwt_secret_key_here_must_be_very_long_and_secure" ]; then
        echo -e "${RED}❌ 请设置JWT_SECRET${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 环境配置检查通过${NC}"
}

# 创建必要的目录
create_directories() {
    echo -e "${YELLOW}📁 创建必要的目录...${NC}"
    
    mkdir -p ssl
    mkdir -p logs
    mkdir -p backups
    
    echo -e "${GREEN}✅ 目录创建完成${NC}"
}

# 停止现有服务
stop_existing_services() {
    echo -e "${YELLOW}🛑 停止现有服务...${NC}"
    
    if docker-compose -f "${COMPOSE_FILE}" ps -q | grep -q .; then
        docker-compose -f "${COMPOSE_FILE}" down
        echo -e "${GREEN}✅ 现有服务已停止${NC}"
    else
        echo -e "${BLUE}ℹ️ 没有运行中的服务${NC}"
    fi
}

# 构建镜像
build_images() {
    echo -e "${YELLOW}🔨 构建Docker镜像...${NC}"
    
    # 构建后端镜像
    echo -e "${BLUE}📦 构建后端API镜像...${NC}"
    docker build -f Dockerfile.backend -t pomodoro-backend:latest .
    
    # 构建前端镜像
    echo -e "${BLUE}📦 构建Web前端镜像...${NC}"
    docker build -f Dockerfile.web -t pomodoro-web:latest .
    
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 启动服务
start_services() {
    echo -e "${YELLOW}🚀 启动服务...${NC}"
    
    # 启动数据库服务
    echo -e "${BLUE}🗄️ 启动数据库服务...${NC}"
    docker-compose -f "${COMPOSE_FILE}" up -d postgres redis
    
    # 等待数据库就绪
    echo -e "${BLUE}⏳ 等待数据库就绪...${NC}"
    sleep 10
    
    # 启动后端服务
    echo -e "${BLUE}🔧 启动后端API服务...${NC}"
    docker-compose -f "${COMPOSE_FILE}" up -d backend
    
    # 等待后端就绪
    echo -e "${BLUE}⏳ 等待后端服务就绪...${NC}"
    sleep 15
    
    # 启动前端服务
    echo -e "${BLUE}🌐 启动Web前端服务...${NC}"
    docker-compose -f "${COMPOSE_FILE}" up -d web
    
    # 启动Nginx代理 (可选)
    echo -e "${BLUE}🔄 启动Nginx代理...${NC}"
    docker-compose -f "${COMPOSE_FILE}" up -d nginx
    
    echo -e "${GREEN}✅ 所有服务启动完成${NC}"
}

# 健康检查
health_check() {
    echo -e "${YELLOW}🏥 执行健康检查...${NC}"
    
    # 检查后端API
    echo -e "${BLUE}🔍 检查后端API...${NC}"
    if curl -f http://localhost:8081/health &> /dev/null; then
        echo -e "${GREEN}✅ 后端API健康${NC}"
    else
        echo -e "${RED}❌ 后端API不健康${NC}"
        return 1
    fi
    
    # 检查Web前端
    echo -e "${BLUE}🔍 检查Web前端...${NC}"
    if curl -f http://localhost:8080/health &> /dev/null; then
        echo -e "${GREEN}✅ Web前端健康${NC}"
    else
        echo -e "${RED}❌ Web前端不健康${NC}"
        return 1
    fi
    
    # 检查Nginx代理
    echo -e "${BLUE}🔍 检查Nginx代理...${NC}"
    if curl -f http://localhost/health &> /dev/null; then
        echo -e "${GREEN}✅ Nginx代理健康${NC}"
    else
        echo -e "${YELLOW}⚠️ Nginx代理可能未配置SSL${NC}"
    fi
    
    echo -e "${GREEN}✅ 健康检查完成${NC}"
}

# 显示部署信息
show_deployment_info() {
    echo -e "${GREEN}🎉 部署完成！${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${PURPLE}📱 访问地址:${NC}"
    echo -e "  • Web应用: ${GREEN}http://localhost:8080${NC}"
    echo -e "  • API接口: ${GREEN}http://localhost:8081${NC}"
    echo -e "  • Nginx代理: ${GREEN}http://localhost${NC}"
    echo ""
    echo -e "${PURPLE}🔧 管理命令:${NC}"
    echo -e "  • 查看状态: ${YELLOW}docker-compose -f ${COMPOSE_FILE} ps${NC}"
    echo -e "  • 查看日志: ${YELLOW}docker-compose -f ${COMPOSE_FILE} logs -f${NC}"
    echo -e "  • 停止服务: ${YELLOW}docker-compose -f ${COMPOSE_FILE} down${NC}"
    echo -e "  • 重启服务: ${YELLOW}docker-compose -f ${COMPOSE_FILE} restart${NC}"
    echo ""
    echo -e "${PURPLE}📊 服务状态:${NC}"
    docker-compose -f "${COMPOSE_FILE}" ps
}

# 主函数
main() {
    check_requirements
    check_environment
    create_directories
    stop_existing_services
    build_images
    start_services
    
    # 等待服务完全启动
    echo -e "${BLUE}⏳ 等待服务完全启动...${NC}"
    sleep 30
    
    health_check
    show_deployment_info
}

# 错误处理
trap 'echo -e "${RED}❌ 部署过程中发生错误${NC}"; exit 1' ERR

# 执行主函数
main "$@"
