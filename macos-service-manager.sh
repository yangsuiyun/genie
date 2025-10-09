#!/bin/bash

# 🍎 macOS生产环境启动脚本
# PomodoroGenie - 生产环境服务管理

set -e

# 配置变量
APP_NAME="PomodoroGenie"
APP_DIR="/Applications/${APP_NAME}"
PID_FILE="${APP_DIR}/logs/app.pid"
LOG_FILE="${APP_DIR}/logs/app.log"
ERROR_LOG="${APP_DIR}/logs/error.log"
CONFIG_FILE="${APP_DIR}/config/macos-production.config"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查应用是否运行
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# 启动应用
start_app() {
    echo -e "${BLUE}🚀 启动 ${APP_NAME}...${NC}"
    
    if is_running; then
        echo -e "${YELLOW}⚠️ ${APP_NAME} 已经在运行中${NC}"
        return 0
    fi
    
    # 检查应用目录
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${RED}❌ 应用目录不存在: ${APP_DIR}${NC}"
        echo -e "${YELLOW}💡 请先运行部署脚本: ./deploy-macbook-production.sh${NC}"
        exit 1
    fi
    
    # 创建日志目录
    mkdir -p "${APP_DIR}/logs"
    
    # 启动Web服务器
    cd "$APP_DIR"
    nohup python3 -m http.server 3001 --bind 0.0.0.0 > "$LOG_FILE" 2> "$ERROR_LOG" &
    echo $! > "$PID_FILE"
    
    # 等待服务启动
    sleep 2
    
    if is_running; then
        echo -e "${GREEN}✅ ${APP_NAME} 启动成功${NC}"
        echo -e "${BLUE}🌐 访问地址: http://localhost:3001${NC}"
        echo -e "${BLUE}📋 PID: $(cat $PID_FILE)${NC}"
    else
        echo -e "${RED}❌ ${APP_NAME} 启动失败${NC}"
        echo -e "${YELLOW}📋 错误日志: ${ERROR_LOG}${NC}"
        exit 1
    fi
}

# 停止应用
stop_app() {
    echo -e "${BLUE}🛑 停止 ${APP_NAME}...${NC}"
    
    if ! is_running; then
        echo -e "${YELLOW}⚠️ ${APP_NAME} 未运行${NC}"
        return 0
    fi
    
    PID=$(cat "$PID_FILE")
    kill "$PID" 2>/dev/null || true
    
    # 等待进程结束
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # 强制杀死进程
    if ps -p "$PID" > /dev/null 2>&1; then
        kill -9 "$PID" 2>/dev/null || true
    fi
    
    rm -f "$PID_FILE"
    echo -e "${GREEN}✅ ${APP_NAME} 已停止${NC}"
}

# 重启应用
restart_app() {
    echo -e "${BLUE}🔄 重启 ${APP_NAME}...${NC}"
    stop_app
    sleep 2
    start_app
}

# 查看状态
status_app() {
    echo -e "${BLUE}📊 ${APP_NAME} 状态${NC}"
    echo -e "${BLUE}==================${NC}"
    
    if is_running; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}✅ 状态: 运行中${NC}"
        echo -e "📋 PID: ${PID}"
        echo -e "🌐 访问地址: http://localhost:3001"
        echo -e "📁 工作目录: ${APP_DIR}"
        
        # 显示进程信息
        echo -e "\n${YELLOW}📋 进程信息:${NC}"
        ps -p "$PID" -o pid,ppid,user,time,command
        
        # 显示端口占用
        echo -e "\n${YELLOW}📋 端口占用:${NC}"
        lsof -i :3001 2>/dev/null || echo "端口3001未被占用"
        
    else
        echo -e "${RED}❌ 状态: 未运行${NC}"
    fi
    
    # 显示日志文件
    echo -e "\n${YELLOW}📋 日志文件:${NC}"
    if [ -f "$LOG_FILE" ]; then
        echo -e "📄 应用日志: ${LOG_FILE} ($(du -h "$LOG_FILE" | cut -f1))"
    fi
    if [ -f "$ERROR_LOG" ]; then
        echo -e "📄 错误日志: ${ERROR_LOG} ($(du -h "$ERROR_LOG" | cut -f1))"
    fi
}

# 查看日志
logs_app() {
    echo -e "${BLUE}📄 ${APP_NAME} 日志${NC}"
    echo -e "${BLUE}==================${NC}"
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}📋 应用日志 (最后50行):${NC}"
        tail -50 "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️ 日志文件不存在: ${LOG_FILE}${NC}"
    fi
    
    if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
        echo -e "\n${YELLOW}📋 错误日志 (最后20行):${NC}"
        tail -20 "$ERROR_LOG"
    fi
}

# 实时日志
follow_logs() {
    echo -e "${BLUE}📄 ${APP_NAME} 实时日志${NC}"
    echo -e "${BLUE}====================${NC}"
    echo -e "${YELLOW}💡 按 Ctrl+C 退出${NC}\n"
    
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️ 日志文件不存在: ${LOG_FILE}${NC}"
    fi
}

# 健康检查
health_check() {
    echo -e "${BLUE}🏥 ${APP_NAME} 健康检查${NC}"
    echo -e "${BLUE}====================${NC}"
    
    # 检查进程
    if is_running; then
        echo -e "${GREEN}✅ 进程状态: 正常${NC}"
    else
        echo -e "${RED}❌ 进程状态: 异常${NC}"
        return 1
    fi
    
    # 检查端口
    if lsof -i :3001 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 端口状态: 正常${NC}"
    else
        echo -e "${RED}❌ 端口状态: 异常${NC}"
        return 1
    fi
    
    # 检查HTTP响应
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 | grep -q "200"; then
        echo -e "${GREEN}✅ HTTP响应: 正常${NC}"
    else
        echo -e "${RED}❌ HTTP响应: 异常${NC}"
        return 1
    fi
    
    # 检查磁盘空间
    DISK_USAGE=$(df -h "$APP_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 90 ]; then
        echo -e "${GREEN}✅ 磁盘空间: 正常 (${DISK_USAGE}% 使用)${NC}"
    else
        echo -e "${YELLOW}⚠️ 磁盘空间: 警告 (${DISK_USAGE}% 使用)${NC}"
    fi
    
    echo -e "\n${GREEN}🎉 健康检查完成${NC}"
}

# 显示帮助
show_help() {
    echo -e "${BLUE}🍎 ${APP_NAME} 服务管理脚本${NC}"
    echo -e "${BLUE}============================${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo -e "  $0 {start|stop|restart|status|logs|follow|health|help}"
    echo ""
    echo -e "${YELLOW}命令:${NC}"
    echo -e "  start    - 启动应用"
    echo -e "  stop     - 停止应用"
    echo -e "  restart  - 重启应用"
    echo -e "  status   - 查看状态"
    echo -e "  logs     - 查看日志"
    echo -e "  follow   - 实时日志"
    echo -e "  health   - 健康检查"
    echo -e "  help     - 显示帮助"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo -e "  $0 start     # 启动应用"
    echo -e "  $0 status    # 查看状态"
    echo -e "  $0 logs      # 查看日志"
}

# 主函数
main() {
    case "${1:-help}" in
        start)
            start_app
            ;;
        stop)
            stop_app
            ;;
        restart)
            restart_app
            ;;
        status)
            status_app
            ;;
        logs)
            logs_app
            ;;
        follow)
            follow_logs
            ;;
        health)
            health_check
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
