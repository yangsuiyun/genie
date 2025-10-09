# 🍎 macOS应用打包配置
# PomodoroGenie - Flutter macOS应用配置

# 应用信息
APP_NAME="PomodoroGenie"
APP_VERSION="1.0.0"
BUNDLE_ID="com.pomodorogenie.app"
TEAM_ID="YOUR_TEAM_ID"  # 替换为你的Apple Developer Team ID

# 构建配置
BUILD_MODE="release"
TARGET_PLATFORM="macos"
ARCHITECTURE="x64"

# 代码签名配置
CERTIFICATE_NAME="Developer ID Application: Your Name"
PROVISIONING_PROFILE=""

# 分发配置
DISTRIBUTION_METHOD="app-store"  # 或 "ad-hoc", "enterprise", "development"
NOTARIZATION_ENABLED=true

# 图标和资源
ICON_SIZES="16,32,64,128,256,512,1024"
ICON_FORMAT="icns"

# 权限配置
MACOS_PERMISSIONS=(
    "NSAppleEventsUsageDescription"
    "NSCalendarsUsageDescription"
    "NSContactsUsageDescription"
    "NSDesktopFolderUsageDescription"
    "NSDocumentsFolderUsageDescription"
    "NSDownloadsFolderUsageDescription"
    "NSLocationUsageDescription"
    "NSMicrophoneUsageDescription"
    "NSMusicLibraryUsageDescription"
    "NSNetworkVolumesUsageDescription"
    "NSPhotoLibraryUsageDescription"
    "NSRemindersUsageDescription"
    "NSSystemAdministrationUsageDescription"
)

# 网络配置
ALLOWED_HOSTS=(
    "localhost"
    "127.0.0.1"
    "0.0.0.0"
)

# 安全配置
SANDBOX_ENABLED=true
HARDENED_RUNTIME=true
GATEKEEPER_ENABLED=true

# 构建输出
BUILD_OUTPUT_DIR="build/macos"
APP_BUNDLE_NAME="${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${APP_VERSION}.dmg"
INSTALLER_NAME="${APP_NAME}-${APP_VERSION}.pkg"

# 测试配置
TEST_MODE=false
AUTOMATED_TESTING=false
TEST_FLIGHT_ENABLED=false
