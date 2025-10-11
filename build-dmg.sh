#!/bin/bash

# Pomodoro Genie DMG 构建脚本
# 自动构建 macOS 应用和 DMG 安装包

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 获取版本号
get_version() {
    if [ -f "mobile/pubspec.yaml" ]; then
        VERSION=$(grep "^version:" mobile/pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
        echo "$VERSION"
    else
        echo "1.0.0"
    fi
}

# 检查依赖
check_dependencies() {
    log_step "检查构建依赖..."

    # 检查 Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter 未安装或未在 PATH 中"
        exit 1
    fi

    # 检查 create-dmg
    if ! command -v create-dmg &> /dev/null; then
        log_warn "create-dmg 未安装，正在安装..."
        brew install create-dmg
    fi

    log_info "✓ 所有依赖已就绪"
}

# 清理旧构建
clean_build() {
    log_step "清理旧的构建文件..."
    cd mobile
    flutter clean
    rm -rf build/macos/dmg
    cd ..
    log_info "✓ 清理完成"
}

# 构建 macOS 应用
build_app() {
    log_step "构建 macOS 应用..."
    cd mobile
    flutter build macos --release
    cd ..
    log_info "✓ 应用构建完成"
}

# 创建 DMG 安装包
create_dmg_package() {
    local VERSION=$(get_version)
    log_step "创建 DMG 安装包 (版本: $VERSION)..."

    cd mobile

    # 创建 DMG 输出目录
    mkdir -p build/macos/dmg

    # 创建 DMG
    create-dmg \
        --volname "Pomodoro Genie" \
        --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "pomodoro_genie.app" 200 190 \
        --hide-extension "pomodoro_genie.app" \
        --app-drop-link 600 185 \
        "build/macos/dmg/PomodoroGenie-${VERSION}.dmg" \
        "build/macos/Build/Products/Release/pomodoro_genie.app"

    cd ..

    log_info "✓ DMG 创建完成"
}

# 显示构建结果
show_results() {
    local VERSION=$(get_version)
    local APP_PATH="mobile/build/macos/Build/Products/Release/pomodoro_genie.app"
    local DMG_PATH="mobile/build/macos/dmg/PomodoroGenie-${VERSION}.dmg"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}         构建完成！${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}应用版本:${NC} $VERSION"
    echo ""
    echo -e "${BLUE}应用包位置:${NC}"
    echo "  $APP_PATH"
    echo "  大小: $(du -h "$APP_PATH" | awk '{print $1}')"
    echo ""
    echo -e "${BLUE}DMG 安装包:${NC}"
    echo "  $DMG_PATH"
    echo "  大小: $(du -h "$DMG_PATH" | awk '{print $1}')"
    echo ""
    echo -e "${YELLOW}使用说明:${NC}"
    echo "  1. 双击 DMG 文件打开安装器"
    echo "  2. 将 Pomodoro Genie 拖拽到 Applications 文件夹"
    echo "  3. 从启动台或 Finder 中打开应用"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║   Pomodoro Genie DMG 构建工具         ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"

    check_dependencies
    clean_build
    build_app
    create_dmg_package
    show_results

    log_info "🎉 全部完成！"
}

# 运行主函数
main
