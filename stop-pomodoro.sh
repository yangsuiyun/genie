#!/bin/bash

echo "🛑 停止Pomodoro Genie服务"

# 停止Go API服务器
if [[ -f "api-server.pid" ]]; then
    kill $(cat api-server.pid) 2>/dev/null
    rm -f api-server.pid
    echo "✅ Go API服务器已停止"
fi

# 停止Flutter Web服务器
if [[ -f "flutter-web.pid" ]]; then
    kill $(cat flutter-web.pid) 2>/dev/null
    rm -f flutter-web.pid
    echo "✅ Flutter Web服务器已停止"
fi

# 清理端口上的进程
pkill -f "python3 -m http.server 3001" 2>/dev/null
pkill -f "go run main.go" 2>/dev/null

echo "🏁 所有服务已停止"
