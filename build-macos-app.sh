#!/bin/bash

# 🍎 macOS应用打包脚本
# PomodoroGenie - Flutter macOS应用构建和打包

set -e

# 加载配置
source macos-build-config.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍎 macOS应用打包脚本${NC}"
echo -e "${BLUE}========================${NC}"
echo -e "应用名称: ${APP_NAME}"
echo -e "版本: ${APP_VERSION}"
echo -e "Bundle ID: ${BUNDLE_ID}"
echo ""

# 检查Flutter macOS支持
check_macos_support() {
    echo -e "${YELLOW}📋 检查macOS支持...${NC}"
    
    cd mobile
    
    # 检查Flutter macOS支持
    if ! flutter config --enable-macos-desktop; then
        echo -e "${RED}❌ 无法启用macOS桌面支持${NC}"
        exit 1
    fi
    
    # 检查macOS设备
    if ! flutter devices | grep -q "macOS"; then
        echo -e "${RED}❌ 未找到macOS设备${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ macOS支持检查通过${NC}"
    cd ..
}

# 配置macOS权限
configure_macos_permissions() {
    echo -e "${YELLOW}⚙️ 配置macOS权限...${NC}"
    
    cd mobile
    
    # 创建macOS权限配置文件
    cat > macos/Runner/DebugProfile.entitlements << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
EOF

    cat > macos/Runner/Release.entitlements << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-executable-page-protection</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
EOF

    echo -e "${GREEN}✅ macOS权限配置完成${NC}"
    cd ..
}

# 构建macOS应用
build_macos_app() {
    echo -e "${YELLOW}🔨 构建macOS应用...${NC}"
    
    cd mobile
    
    # 清理之前的构建
    flutter clean
    
    # 获取依赖
    flutter pub get
    
    # 构建macOS应用
    flutter build macos --release --dart-define=FLUTTER_WEB_USE_SKIA=false
    
    # 检查构建结果
    if [ ! -d "build/macos/Build/Products/Release/${APP_NAME}.app" ]; then
        echo -e "${RED}❌ macOS应用构建失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ macOS应用构建完成${NC}"
    cd ..
}

# 代码签名
sign_app() {
    echo -e "${YELLOW}🔐 代码签名...${NC}"
    
    cd mobile
    
    APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
    
    # 检查证书
    if ! security find-identity -v -p codesigning | grep -q "${CERTIFICATE_NAME}"; then
        echo -e "${YELLOW}⚠️ 未找到代码签名证书，跳过签名${NC}"
        echo -e "${YELLOW}💡 请在Keychain Access中安装开发者证书${NC}"
        return
    fi
    
    # 签名应用
    codesign --force --deep --sign "${CERTIFICATE_NAME}" "${APP_PATH}"
    
    # 验证签名
    codesign --verify --verbose "${APP_PATH}"
    
    echo -e "${GREEN}✅ 代码签名完成${NC}"
    cd ..
}

# 创建DMG安装包
create_dmg() {
    echo -e "${YELLOW}📦 创建DMG安装包...${NC}"
    
    cd mobile
    
    APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
    DMG_PATH="build/macos/Build/Products/Release/${DMG_NAME}"
    
    # 创建临时DMG目录
    TEMP_DMG_DIR="build/macos/Build/Products/Release/temp_dmg"
    mkdir -p "${TEMP_DMG_DIR}"
    
    # 复制应用到临时目录
    cp -r "${APP_PATH}" "${TEMP_DMG_DIR}/"
    
    # 创建Applications链接
    ln -s /Applications "${TEMP_DMG_DIR}/Applications"
    
    # 创建DMG
    hdiutil create -volname "${APP_NAME}" -srcfolder "${TEMP_DMG_DIR}" -ov -format UDZO "${DMG_PATH}"
    
    # 清理临时目录
    rm -rf "${TEMP_DMG_DIR}"
    
    echo -e "${GREEN}✅ DMG安装包创建完成${NC}"
    cd ..
}

# 创建PKG安装包
create_pkg() {
    echo -e "${YELLOW}📦 创建PKG安装包...${NC}"
    
    cd mobile
    
    APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
    PKG_PATH="build/macos/Build/Products/Release/${INSTALLER_NAME}"
    
    # 创建组件包
    pkgbuild --root "${APP_PATH}" --identifier "${BUNDLE_ID}" --version "${APP_VERSION}" --install-location "/Applications" "${PKG_PATH}"
    
    echo -e "${GREEN}✅ PKG安装包创建完成${NC}"
    cd ..
}

# 公证应用
notarize_app() {
    echo -e "${YELLOW}🔒 公证应用...${NC}"
    
    if [ "$NOTARIZATION_ENABLED" = false ]; then
        echo -e "${YELLOW}⚠️ 公证功能已禁用${NC}"
        return
    fi
    
    cd mobile
    
    APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
    
    # 检查公证凭据
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_PASSWORD" ]; then
        echo -e "${YELLOW}⚠️ 未配置Apple ID，跳过公证${NC}"
        echo -e "${YELLOW}💡 请设置环境变量: APPLE_ID 和 APPLE_PASSWORD${NC}"
        return
    fi
    
    # 创建zip文件用于公证
    ZIP_PATH="build/macos/Build/Products/Release/${APP_NAME}.zip"
    ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"
    
    # 提交公证
    xcrun notarytool submit "${ZIP_PATH}" --apple-id "${APPLE_ID}" --password "${APPLE_PASSWORD}" --team-id "${TEAM_ID}" --wait
    
    # 装订公证票据
    xcrun stapler staple "${APP_PATH}"
    
    echo -e "${GREEN}✅ 应用公证完成${NC}"
    cd ..
}

# 显示构建结果
show_build_results() {
    echo ""
    echo -e "${GREEN}🎉 构建完成！${NC}"
    echo -e "${BLUE}========================${NC}"
    
    cd mobile
    
    BUILD_DIR="build/macos/Build/Products/Release"
    
    echo -e "${YELLOW}📦 构建产物:${NC}"
    if [ -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
        echo -e "✅ macOS应用: ${BUILD_DIR}/${APP_NAME}.app"
    fi
    
    if [ -f "${BUILD_DIR}/${DMG_NAME}" ]; then
        echo -e "✅ DMG安装包: ${BUILD_DIR}/${DMG_NAME}"
    fi
    
    if [ -f "${BUILD_DIR}/${INSTALLER_NAME}" ]; then
        echo -e "✅ PKG安装包: ${BUILD_DIR}/${INSTALLER_NAME}"
    fi
    
    echo ""
    echo -e "${YELLOW}📋 安装说明:${NC}"
    echo -e "1. 直接运行: 双击 ${APP_NAME}.app"
    echo -e "2. DMG安装: 双击 ${DMG_NAME}，拖拽到Applications文件夹"
    echo -e "3. PKG安装: 双击 ${INSTALLER_NAME}，按提示安装"
    
    echo ""
    echo -e "${YELLOW}📋 分发说明:${NC}"
    echo -e "• 开发测试: 直接使用 .app 文件"
    echo -e "• 内部分发: 使用 DMG 文件"
    echo -e "• 企业分发: 使用 PKG 文件"
    echo -e "• App Store: 需要额外的App Store Connect配置"
    
    cd ..
}

# 主函数
main() {
    check_macos_support
    configure_macos_permissions
    build_macos_app
    sign_app
    create_dmg
    create_pkg
    notarize_app
    show_build_results
}

# 执行主函数
main "$@"
