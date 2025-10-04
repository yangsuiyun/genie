#!/bin/bash

echo "🐳 启动 Pomodoro Genie Docker 服务"
echo "=================================="

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在，从模板创建..."
    cp .env.example .env
fi

echo "📋 当前配置："
echo "  - 数据库端口: 5432"
echo "  - API端口: 54321"
echo "  - Studio端口: 3000"
echo "  - Realtime端口: 4000"
echo "  - Meta API端口: 8080"
echo ""

echo "🚀 启动所有服务..."

# 请用户手动运行docker-compose命令
echo "请在终端中运行以下命令："
echo ""
echo "  sudo docker-compose up -d"
echo ""
echo "或者如果你已经修复了Docker权限："
echo "  docker-compose up -d"
echo ""
echo "启动后，可以通过以下命令检查状态："
echo "  sudo docker-compose ps"
echo ""
echo "查看日志："
echo "  sudo docker-compose logs -f"
echo ""
echo "停止服务："
echo "  sudo docker-compose down"
echo ""
echo "🌐 服务将在以下地址可用："
echo "  • Supabase Studio: http://localhost:3000"
echo "  • PostgreSQL: localhost:5432"
echo "  • PostgREST API: http://localhost:54321"
echo "  • Realtime: http://localhost:4000"
echo "  • Meta API: http://localhost:8080"