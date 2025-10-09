#!/bin/bash

# 🍎 MacBook生产环境部署脚本
# PomodoroGenie - Flutter Web应用部署
# 适用于macOS生产环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
APP_NAME="PomodoroGenie"
APP_VERSION="1.0.0"
DEPLOY_PORT=3001
DEPLOY_HOST="0.0.0.0"
BUILD_DIR="mobile/build/web"
DEPLOY_DIR="/Applications/${APP_NAME}"
LOG_FILE="/var/log/${APP_NAME}.log"

echo -e "${BLUE}🍎 MacBook生产环境部署脚本${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "应用名称: ${APP_NAME}"
echo -e "版本: ${APP_VERSION}"
echo -e "部署端口: ${DEPLOY_PORT}"
echo -e "部署目录: ${DEPLOY_DIR}"
echo ""

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}📋 检查系统要求...${NC}"
    
    # 检查macOS版本
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}❌ 此脚本仅适用于macOS系统${NC}"
        exit 1
    fi
    
    # 检查Flutter安装
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter未安装，请先安装Flutter${NC}"
        echo -e "${YELLOW}💡 安装命令: brew install flutter${NC}"
        exit 1
    fi
    
    # 检查Dart SDK
    if ! command -v dart &> /dev/null; then
        echo -e "${RED}❌ Dart SDK未安装${NC}"
        exit 1
    fi
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python3未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 系统要求检查通过${NC}"
}

# 创建部署目录
create_deploy_directory() {
    echo -e "${YELLOW}📁 创建部署目录...${NC}"
    
    # 创建应用目录
    sudo mkdir -p "${DEPLOY_DIR}"
    sudo mkdir -p "${DEPLOY_DIR}/bin"
    sudo mkdir -p "${DEPLOY_DIR}/logs"
    sudo mkdir -p "${DEPLOY_DIR}/config"
    
    # 设置权限
    sudo chown -R $(whoami):staff "${DEPLOY_DIR}"
    
    echo -e "${GREEN}✅ 部署目录创建完成${NC}"
}

# 构建Flutter Web应用
build_flutter_app() {
    echo -e "${YELLOW}🔨 构建Flutter Web应用...${NC}"
    
    cd mobile
    
    # 清理之前的构建
    flutter clean
    
    # 获取依赖
    flutter pub get
    
    # 构建Web应用
    flutter build web --release --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false
    
    # 检查构建结果
    if [ ! -d "build/web" ]; then
        echo -e "${RED}❌ Flutter Web构建失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Flutter Web应用构建完成${NC}"
    cd ..
}

# 部署应用文件
deploy_app_files() {
    echo -e "${YELLOW}📦 部署应用文件...${NC}"
    
    # 复制Web文件到部署目录
    cp -r "${BUILD_DIR}"/* "${DEPLOY_DIR}/"
    
    # 复制配置文件
    cp "nginx.production.conf" "${DEPLOY_DIR}/config/"
    cp "docker-compose.production.yml" "${DEPLOY_DIR}/config/"
    
    # 创建启动脚本
    cat > "${DEPLOY_DIR}/bin/start.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."
python3 -m http.server 3001 --bind 0.0.0.0 > logs/app.log 2>&1 &
echo $! > logs/app.pid
echo "PomodoroGenie started on port 3001"
EOF
    
    # 创建停止脚本
    cat > "${DEPLOY_DIR}/bin/stop.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."
if [ -f logs/app.pid ]; then
    PID=$(cat logs/app.pid)
    kill $PID 2>/dev/null
    rm logs/app.pid
    echo "PomodoroGenie stopped"
else
    echo "No running instance found"
fi
EOF
    
    # 创建状态检查脚本
    cat > "${DEPLOY_DIR}/bin/status.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."
if [ -f logs/app.pid ]; then
    PID=$(cat logs/app.pid)
    if ps -p $PID > /dev/null; then
        echo "PomodoroGenie is running (PID: $PID)"
        echo "Access URL: http://localhost:3001"
    else
        echo "PomodoroGenie is not running"
    fi
else
    echo "PomodoroGenie is not running"
fi
EOF
    
    # 设置脚本执行权限
    chmod +x "${DEPLOY_DIR}/bin"/*.sh
    
    echo -e "${GREEN}✅ 应用文件部署完成${NC}"
}

# 创建系统服务
create_system_service() {
    echo -e "${YELLOW}⚙️ 创建系统服务...${NC}"
    
    # 创建LaunchDaemon plist文件
    sudo cat > "/Library/LaunchDaemons/com.pomodorogenie.app.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.pomodorogenie.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>${DEPLOY_DIR}/bin/start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${DEPLOY_DIR}/logs/service.log</string>
    <key>StandardErrorPath</key>
    <string>${DEPLOY_DIR}/logs/service.error.log</string>
</dict>
</plist>
EOF
    
    # 加载服务
    sudo launchctl load "/Library/LaunchDaemons/com.pomodorogenie.app.plist"
    
    echo -e "${GREEN}✅ 系统服务创建完成${NC}"
}

# 创建桌面快捷方式
create_desktop_shortcut() {
    echo -e "${YELLOW}🖥️ 创建桌面快捷方式...${NC}"
    
    # 创建应用包
    mkdir -p "${DEPLOY_DIR}.app/Contents/MacOS"
    mkdir -p "${DEPLOY_DIR}.app/Contents/Resources"
    
    # 创建Info.plist
    cat > "${DEPLOY_DIR}.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PomodoroGenie</string>
    <key>CFBundleIdentifier</key>
    <string>com.pomodorogenie.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
</dict>
</plist>
EOF
    
    # 创建启动脚本
    cat > "${DEPLOY_DIR}.app/Contents/MacOS/PomodoroGenie" << EOF
#!/bin/bash
open -a Safari "http://localhost:3001"
EOF
    
    chmod +x "${DEPLOY_DIR}.app/Contents/MacOS/PomodoroGenie"
    
    echo -e "${GREEN}✅ 桌面快捷方式创建完成${NC}"
}

# 启动应用
start_application() {
    echo -e "${YELLOW}🚀 启动应用...${NC}"
    
    # 停止可能运行的服务
    "${DEPLOY_DIR}/bin/stop.sh" 2>/dev/null || true
    
    # 启动应用
    "${DEPLOY_DIR}/bin/start.sh"
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    if "${DEPLOY_DIR}/bin/status.sh" | grep -q "running"; then
        echo -e "${GREEN}✅ 应用启动成功${NC}"
        echo -e "${BLUE}🌐 访问地址: http://localhost:${DEPLOY_PORT}${NC}"
        echo -e "${BLUE}🌐 网络访问: http://$(hostname -I | awk '{print $1}'):${DEPLOY_PORT}${NC}"
    else
        echo -e "${RED}❌ 应用启动失败${NC}"
        exit 1
    fi
}

# 显示部署信息
show_deployment_info() {
    echo ""
    echo -e "${GREEN}🎉 部署完成！${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "应用名称: ${APP_NAME}"
    echo -e "版本: ${APP_VERSION}"
    echo -e "部署目录: ${DEPLOY_DIR}"
    echo -e "访问地址: http://localhost:${DEPLOY_PORT}"
    echo ""
    echo -e "${YELLOW}📋 管理命令:${NC}"
    echo -e "启动应用: ${DEPLOY_DIR}/bin/start.sh"
    echo -e "停止应用: ${DEPLOY_DIR}/bin/stop.sh"
    echo -e "查看状态: ${DEPLOY_DIR}/bin/status.sh"
    echo ""
    echo -e "${YELLOW}📋 系统服务:${NC}"
    echo -e "启动服务: sudo launchctl start com.pomodorogenie.app"
    echo -e "停止服务: sudo launchctl stop com.pomodorogenie.app"
    echo -e "卸载服务: sudo launchctl unload /Library/LaunchDaemons/com.pomodorogenie.app.plist"
    echo ""
    echo -e "${YELLOW}📋 日志文件:${NC}"
    echo -e "应用日志: ${DEPLOY_DIR}/logs/app.log"
    echo -e "服务日志: ${DEPLOY_DIR}/logs/service.log"
    echo -e "错误日志: ${DEPLOY_DIR}/logs/service.error.log"
}

# 主函数
main() {
    check_requirements
    create_deploy_directory
    build_flutter_app
    deploy_app_files
    create_system_service
    create_desktop_shortcut
    start_application
    show_deployment_info
}

# 执行主函数
main "$@"
