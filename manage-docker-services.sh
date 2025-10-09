#!/bin/bash

# 🍅 Pomodoro Genie Docker 服务管理脚本
# 用于管理Docker容器的启动、停止、重启等操作

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
COMPOSE_FILE="docker-compose.production.yml"
ENV_FILE=".env"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}🍅 ${APP_NAME} Docker 服务管理脚本${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo ""
    echo -e "${PURPLE}用法:${NC}"
    echo "  $0 [命令]"
    echo ""
    echo -e "${PURPLE}命令:${NC}"
    echo "  start     启动所有服务"
    echo "  stop      停止所有服务"
    echo "  restart   重启所有服务"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  logs-f    实时查看服务日志"
    echo "  health    健康检查"
    echo "  clean     清理未使用的资源"
    echo "  backup    备份数据"
    echo "  restore   恢复数据"
    echo "  update    更新服务"
    echo "  help      显示此帮助信息"
    echo ""
    echo -e "${PURPLE}示例:${NC}"
    echo "  $0 start"
    echo "  $0 logs-f"
    echo "  $0 health"
}

# 检查Docker环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker服务未运行${NC}"
        exit 1
    fi
}

# 启动服务
start_services() {
    echo -e "${YELLOW}🚀 启动 ${APP_NAME} 服务...${NC}"
    
    check_docker
    
    if [ ! -f "${COMPOSE_FILE}" ]; then
        echo -e "${RED}❌ 配置文件 ${COMPOSE_FILE} 不存在${NC}"
        exit 1
    fi
    
    if [ ! -f "${ENV_FILE}" ]; then
        echo -e "${RED}❌ 环境变量文件 ${ENV_FILE} 不存在${NC}"
        exit 1
    fi
    
    docker-compose -f "${COMPOSE_FILE}" up -d
    
    echo -e "${GREEN}✅ 服务启动完成${NC}"
    show_status
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}🛑 停止 ${APP_NAME} 服务...${NC}"
    
    check_docker
    
    docker-compose -f "${COMPOSE_FILE}" down
    
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 重启服务
restart_services() {
    echo -e "${YELLOW}🔄 重启 ${APP_NAME} 服务...${NC}"
    
    stop_services
    sleep 5
    start_services
}

# 查看服务状态
show_status() {
    echo -e "${BLUE}📊 ${APP_NAME} 服务状态${NC}"
    echo -e "${BLUE}========================${NC}"
    
    check_docker
    
    docker-compose -f "${COMPOSE_FILE}" ps
    
    echo ""
    echo -e "${PURPLE}🌐 访问地址:${NC}"
    echo -e "  • Web应用: ${GREEN}http://localhost:8080${NC}"
    echo -e "  • API接口: ${GREEN}http://localhost:8081${NC}"
    echo -e "  • Nginx代理: ${GREEN}http://localhost${NC}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📋 ${APP_NAME} 服务日志${NC}"
    echo -e "${BLUE}========================${NC}"
    
    check_docker
    
    docker-compose -f "${COMPOSE_FILE}" logs --tail=100
}

# 实时查看日志
show_logs_follow() {
    echo -e "${BLUE}📋 ${APP_NAME} 实时日志${NC}"
    echo -e "${BLUE}========================${NC}"
    echo -e "${YELLOW}按 Ctrl+C 退出日志查看${NC}"
    echo ""
    
    check_docker
    
    docker-compose -f "${COMPOSE_FILE}" logs -f
}

# 健康检查
health_check() {
    echo -e "${BLUE}🏥 ${APP_NAME} 健康检查${NC}"
    echo -e "${BLUE}========================${NC}"
    
    check_docker
    
    # 检查后端API
    echo -e "${YELLOW}🔍 检查后端API...${NC}"
    if curl -f http://localhost:8081/health &> /dev/null; then
        echo -e "${GREEN}✅ 后端API健康${NC}"
    else
        echo -e "${RED}❌ 后端API不健康${NC}"
    fi
    
    # 检查Web前端
    echo -e "${YELLOW}🔍 检查Web前端...${NC}"
    if curl -f http://localhost:8080/health &> /dev/null; then
        echo -e "${GREEN}✅ Web前端健康${NC}"
    else
        echo -e "${RED}❌ Web前端不健康${NC}"
    fi
    
    # 检查Nginx代理
    echo -e "${YELLOW}🔍 检查Nginx代理...${NC}"
    if curl -f http://localhost/health &> /dev/null; then
        echo -e "${GREEN}✅ Nginx代理健康${NC}"
    else
        echo -e "${YELLOW}⚠️ Nginx代理可能未配置SSL${NC}"
    fi
    
    echo ""
    echo -e "${PURPLE}📊 容器健康状态:${NC}"
    docker-compose -f "${COMPOSE_FILE}" ps
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}🧹 清理Docker资源...${NC}"
    
    check_docker
    
    # 停止并删除容器
    docker-compose -f "${COMPOSE_FILE}" down --remove-orphans
    
    # 清理未使用的镜像
    echo -e "${BLUE}🗑️ 清理未使用的镜像...${NC}"
    docker image prune -f
    
    # 清理未使用的卷
    echo -e "${BLUE}🗑️ 清理未使用的卷...${NC}"
    docker volume prune -f
    
    # 清理未使用的网络
    echo -e "${BLUE}🗑️ 清理未使用的网络...${NC}"
    docker network prune -f
    
    echo -e "${GREEN}✅ 资源清理完成${NC}"
}

# 备份数据
backup_data() {
    echo -e "${YELLOW}💾 备份 ${APP_NAME} 数据...${NC}"
    
    check_docker
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${BACKUP_DIR}"
    
    # 备份PostgreSQL数据
    echo -e "${BLUE}🗄️ 备份PostgreSQL数据...${NC}"
    docker-compose -f "${COMPOSE_FILE}" exec -T postgres pg_dump -U postgres pomodoro_genie > "${BACKUP_DIR}/postgres_backup.sql"
    
    # 备份Redis数据
    echo -e "${BLUE}🚀 备份Redis数据...${NC}"
    docker-compose -f "${COMPOSE_FILE}" exec -T redis redis-cli --rdb - > "${BACKUP_DIR}/redis_backup.rdb"
    
    # 备份配置文件
    echo -e "${BLUE}⚙️ 备份配置文件...${NC}"
    cp "${ENV_FILE}" "${BACKUP_DIR}/"
    cp "${COMPOSE_FILE}" "${BACKUP_DIR}/"
    
    echo -e "${GREEN}✅ 数据备份完成: ${BACKUP_DIR}${NC}"
}

# 恢复数据
restore_data() {
    echo -e "${YELLOW}📥 恢复 ${APP_NAME} 数据...${NC}"
    
    if [ -z "$1" ]; then
        echo -e "${RED}❌ 请指定备份目录${NC}"
        echo -e "${YELLOW}用法: $0 restore <backup_directory>${NC}"
        exit 1
    fi
    
    BACKUP_DIR="$1"
    
    if [ ! -d "${BACKUP_DIR}" ]; then
        echo -e "${RED}❌ 备份目录不存在: ${BACKUP_DIR}${NC}"
        exit 1
    fi
    
    check_docker
    
    # 停止服务
    docker-compose -f "${COMPOSE_FILE}" down
    
    # 恢复PostgreSQL数据
    if [ -f "${BACKUP_DIR}/postgres_backup.sql" ]; then
        echo -e "${BLUE}🗄️ 恢复PostgreSQL数据...${NC}"
        docker-compose -f "${COMPOSE_FILE}" up -d postgres
        sleep 10
        docker-compose -f "${COMPOSE_FILE}" exec -T postgres psql -U postgres -d pomodoro_genie < "${BACKUP_DIR}/postgres_backup.sql"
    fi
    
    # 恢复Redis数据
    if [ -f "${BACKUP_DIR}/redis_backup.rdb" ]; then
        echo -e "${BLUE}🚀 恢复Redis数据...${NC}"
        docker-compose -f "${COMPOSE_FILE}" up -d redis
        sleep 5
        docker-compose -f "${COMPOSE_FILE}" exec -T redis redis-cli --pipe < "${BACKUP_DIR}/redis_backup.rdb"
    fi
    
    # 启动所有服务
    docker-compose -f "${COMPOSE_FILE}" up -d
    
    echo -e "${GREEN}✅ 数据恢复完成${NC}"
}

# 更新服务
update_services() {
    echo -e "${YELLOW}🔄 更新 ${APP_NAME} 服务...${NC}"
    
    check_docker
    
    # 拉取最新镜像
    echo -e "${BLUE}📥 拉取最新镜像...${NC}"
    docker-compose -f "${COMPOSE_FILE}" pull
    
    # 重新构建和启动
    echo -e "${BLUE}🔨 重新构建和启动服务...${NC}"
    docker-compose -f "${COMPOSE_FILE}" up -d --build
    
    echo -e "${GREEN}✅ 服务更新完成${NC}"
    show_status
}

# 主函数
main() {
    case "${1:-help}" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        logs-f)
            show_logs_follow
            ;;
        health)
            health_check
            ;;
        clean)
            clean_resources
            ;;
        backup)
            backup_data
            ;;
        restore)
            restore_data "$2"
            ;;
        update)
            update_services
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
