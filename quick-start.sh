#!/bin/bash

echo "🚀 Pomodoro Genie 快速启动"
echo "========================"

# 检测Docker权限
if docker ps &> /dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
    echo "✅ 使用Docker (无sudo)"
elif sudo docker ps &> /dev/null 2>&1; then
    COMPOSE_CMD="sudo docker-compose"
    echo "⚠️  使用Docker (需要sudo)"
else
    echo "❌ Docker不可用，请先安装Docker"
    exit 1
fi

# 选择配置文件
echo ""
echo "请选择启动配置:"
echo "1) 简化配置 (推荐) - PostgreSQL + PostgREST + pgAdmin + Redis + Nginx"
echo "2) 原始配置 - 完整Supabase栈"
echo "3) 仅数据库 - 只启动PostgreSQL"

read -p "请输入选择 (1-3): " choice

case $choice in
    1)
        COMPOSE_FILE="docker-compose.simple.yml"
        echo "✅ 使用简化配置"
        ;;
    2)
        COMPOSE_FILE="docker-compose.yml"
        echo "✅ 使用原始配置"
        ;;
    3)
        # 创建仅数据库的配置
        cat > docker-compose.db-only.yml << EOF
version: '3.8'
services:
  db:
    container_name: pomodoro_postgres_only
    image: postgres:15-alpine
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    volumes:
      - ./backend/migrations/init.sql:/docker-entrypoint-initdb.d/01-init.sql:ro
      - pomodoro_db_only:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pomodoro_db_only:
EOF
        COMPOSE_FILE="docker-compose.db-only.yml"
        echo "✅ 使用仅数据库配置"
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "🔍 检查端口占用..."

if [ "$choice" = "1" ]; then
    ports=(3000 5432 54321 6379 8080)
elif [ "$choice" = "2" ]; then
    ports=(3000 5432 54321 4000 8080)
else
    ports=(5432)
fi

for port in "${ports[@]}"; do
    if lsof -i:$port &> /dev/null 2>&1; then
        echo "⚠️  端口 $port 被占用"
        echo "   进程: $(lsof -i:$port | tail -n +2 | head -1 | awk '{print $1, $2}')"
        read -p "继续启动吗? (y/N): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            echo "❌ 启动取消"
            exit 1
        fi
        break
    fi
done

echo ""
echo "📦 启动服务..."
echo "执行命令: $COMPOSE_CMD -f $COMPOSE_FILE up -d"

$COMPOSE_CMD -f $COMPOSE_FILE up -d

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 服务启动成功!"
    echo ""
    echo "📊 服务状态:"
    $COMPOSE_CMD -f $COMPOSE_FILE ps

    echo ""
    echo "🌐 可访问的服务:"

    if [ "$choice" = "1" ]; then
        echo "  • 主页/API网关: http://localhost:8080"
        echo "  • 数据库管理: http://localhost:8080/admin"
        echo "  • REST API: http://localhost:54321"
        echo "  • PostgreSQL: localhost:5432"
        echo "  • Redis: localhost:6379"
    elif [ "$choice" = "2" ]; then
        echo "  • Supabase Studio: http://localhost:3000"
        echo "  • REST API: http://localhost:54321"
        echo "  • PostgreSQL: localhost:5432"
        echo "  • Realtime: http://localhost:4000"
        echo "  • Meta API: http://localhost:8080"
    else
        echo "  • PostgreSQL: localhost:5432"
        echo "  • 数据库: postgres"
        echo "  • 用户: postgres"
        echo "  • 密码: 查看.env文件"
    fi

    echo ""
    echo "🔧 管理命令:"
    echo "  查看日志: $COMPOSE_CMD -f $COMPOSE_FILE logs -f"
    echo "  停止服务: $COMPOSE_CMD -f $COMPOSE_FILE down"
    echo "  重启服务: $COMPOSE_CMD -f $COMPOSE_FILE restart"
    echo "  查看状态: $COMPOSE_CMD -f $COMPOSE_FILE ps"

    echo ""
    echo "🧪 测试连接:"
    echo "  数据库: psql -h localhost -p 5432 -U postgres -d postgres"
    if [ "$choice" = "1" ]; then
        echo "  API健康检查: curl http://localhost:8080/health"
        echo "  REST API: curl http://localhost:54321/"
    fi

else
    echo ""
    echo "❌ 启动失败!"
    echo "查看错误日志: $COMPOSE_CMD -f $COMPOSE_FILE logs"
fi