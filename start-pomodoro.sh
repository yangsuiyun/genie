#!/bin/bash

# 🍅 Pomodoro Genie 快速启动脚本
# 支持MacBook和Android设备通过网络访问

echo "🍅 启动Pomodoro Genie服务"
echo "=============================="

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# 获取本机IP地址
get_local_ip() {
    # 尝试多种方法获取本机IP
    local ip=""

    # 方法1: ip命令
    if command -v ip >/dev/null 2>&1; then
        ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[0-9.]+' | head -1)
    fi

    # 方法2: ifconfig
    if [[ -z "$ip" ]] && command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig | grep -E "inet.*broadcast" | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    fi

    # 方法3: hostname命令
    if [[ -z "$ip" ]] && command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi

    # 默认值
    if [[ -z "$ip" ]]; then
        ip="localhost"
    fi

    echo "$ip"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # 端口被占用
    else
        return 1  # 端口空闲
    fi
}

# 启动Go API服务
start_api_server() {
    log_info "检查Go API服务器..."

    if check_port 8081; then
        log_success "Go API服务器已运行在端口8081"
    else
        log_info "启动Go API服务器..."
        cd backend 2>/dev/null || {
            log_warning "backend目录不存在，跳过Go API服务器"
            return 1
        }

        if [[ -f "main.go" ]]; then
            nohup go run main.go > ../api-server.log 2>&1 &
            echo $! > ../api-server.pid
            sleep 2

            if check_port 8081; then
                log_success "Go API服务器启动成功"
            else
                log_error "Go API服务器启动失败"
            fi
        else
            log_warning "main.go不存在，跳过Go API服务器"
        fi
        cd ..
    fi
}

# 启动Flutter Web服务
start_flutter_web() {
    log_info "检查Flutter Web服务..."

    if check_port 3001; then
        log_success "Flutter Web已运行在端口3001"
    else
        log_info "启动Flutter Web服务器..."
        cd mobile/build/web 2>/dev/null || {
            log_warning "Flutter构建目录不存在，需要先构建应用"
            cd mobile 2>/dev/null || {
                log_error "mobile目录不存在"
                return 1
            }

            # 检查Flutter是否可用
            if ! command -v flutter >/dev/null 2>&1; then
                if [[ -f "/home/suiyun/flutter/bin/flutter" ]]; then
                    export PATH="/home/suiyun/flutter/bin:$PATH"
                else
                    log_error "Flutter未安装"
                    return 1
                fi
            fi

            log_info "构建Flutter Web应用..."
            flutter build web --release
            cd build/web
        }

        log_info "启动HTTP服务器..."
        nohup python3 -m http.server 3001 --bind 0.0.0.0 > ../../../flutter-web.log 2>&1 &
        echo $! > ../../../flutter-web.pid
        sleep 2

        if check_port 3001; then
            log_success "Flutter Web服务器启动成功"
        else
            log_error "Flutter Web服务器启动失败"
        fi
        cd ../../..
    fi
}

# 显示访问信息
show_access_info() {
    local ip=$(get_local_ip)

    echo ""
    log_success "🎉 Pomodoro Genie启动完成！"
    echo ""
    echo "📱 访问方式:"
    echo "=================================================="
    echo ""
    echo "🖥️  MacBook (本地访问):"
    echo "   http://localhost:3001"
    echo ""
    echo "🌐 MacBook/Android (网络访问):"
    echo "   http://$ip:3001"
    echo ""
    echo "🔧 API服务器:"
    echo "   http://$ip:8081"
    echo "   健康检查: http://$ip:8081/health"
    echo ""
    echo "📋 使用说明:"
    echo "   • MacBook: 在Safari/Chrome中打开上述链接"
    echo "   • Android: 在Chrome中打开网络链接"
    echo "   • 可添加到主屏幕作为PWA使用"
    echo ""
    echo "⚙️  管理命令:"
    echo "   停止服务: bash stop-pomodoro.sh"
    echo "   查看日志: tail -f *.log"
    echo ""
}

# 创建停止脚本
create_stop_script() {
    cat > stop-pomodoro.sh << 'EOF'
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
EOF
    chmod +x stop-pomodoro.sh
}

# 主函数
main() {
    # 检查当前目录是否正确
    if [[ ! -d "mobile" ]]; then
        log_error "请在项目根目录运行此脚本"
        exit 1
    fi

    # 启动服务
    start_api_server
    start_flutter_web

    # 创建停止脚本
    create_stop_script

    # 显示访问信息
    show_access_info
}

# 运行主函数
main "$@"