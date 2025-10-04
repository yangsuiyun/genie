# 🍅 Pomodoro Genie 平台使用指南

## 📱 支持的平台

- **Web** ✅ (已就绪)
- **MacBook** ✅ (桌面版 + 浏览器)
- **Android** ✅ (APK + 浏览器)
- **iOS** ⚠️ (需要开发者账号)
- **Windows** ✅ (桌面版)
- **Linux** ✅ (桌面版)

## 🖥️ MacBook 使用方法

### 方法1: 浏览器访问（最简单）
```bash
# 在Safari、Chrome或任何现代浏览器中打开
http://localhost:3001
```

### 方法2: 原生macOS应用
```bash
# 在服务器上构建macOS版本
flutter build macos --release

# 将生成的应用传输到MacBook
# 路径: build/macos/Build/Products/Release/pomodoro_genie.app
```

### 方法3: 通过网络访问
```bash
# 在MacBook浏览器中访问服务器IP
http://[服务器IP]:3001
```

## 📱 Android 使用方法

### 方法1: 安装APK应用
```bash
# 构建Android APK
flutter build apk --release

# 生成的APK位置: build/app/outputs/flutter-apk/app-release.apk
# 传输到Android设备安装
```

### 方法2: 浏览器访问
```bash
# 在Android Chrome中打开
http://[服务器IP]:3001
```

### 方法3: PWA安装
1. 在Android Chrome中访问应用
2. 点击"添加到主屏幕"
3. 应用会作为PWA安装

## 🌐 网络配置

### 局域网访问设置
```bash
# 确保防火墙允许3001端口
sudo ufw allow 3001

# 或使用0.0.0.0绑定所有接口
python3 -m http.server 3001 --bind 0.0.0.0
```

### 查找服务器IP
```bash
# Linux/macOS
ip addr show | grep inet
# 或
ifconfig | grep inet
```

## 🚀 快速部署脚本

### 生成所有平台版本
```bash
#!/bin/bash
echo "🍅 构建Pomodoro Genie全平台版本"

# Web版本
flutter build web --release
echo "✅ Web版本构建完成"

# Android APK
flutter build apk --release
echo "✅ Android APK构建完成"

# macOS版本 (在macOS上运行)
# flutter build macos --release
# echo "✅ macOS版本构建完成"

echo "📦 构建产物:"
echo "   Web: build/web/"
echo "   Android: build/app/outputs/flutter-apk/app-release.apk"
echo "   macOS: build/macos/Build/Products/Release/"
```

## 📋 功能特性

### 核心功能
- 🍅 **番茄计时器** - 25分钟专注时间
- ⏰ **休息提醒** - 5分钟短休息，15分钟长休息
- 📊 **统计报告** - 每日完成情况
- 🎯 **任务管理** - 待办事项列表
- 🔔 **通知提醒** - 桌面和移动通知

### 跨平台同步
- 📱 **实时同步** - 所有设备数据同步
- 🌐 **云端存储** - PostgreSQL数据库
- 🔄 **离线支持** - 本地Hive存储

## 🛠️ 开发者信息

### API端点
- **后端API**: http://localhost:8081
- **健康检查**: http://localhost:8081/health
- **任务管理**: http://localhost:8081/v1/tasks/
- **番茄钟**: http://localhost:8081/v1/pomodoro/sessions/

### 技术栈
- **前端**: Flutter 3.24.3
- **后端**: Go 1.21+ (Gin框架)
- **数据库**: PostgreSQL 15
- **状态管理**: Riverpod
- **本地存储**: Hive + SQLite

## 🔧 故障排除

### 常见问题
1. **无法访问应用**
   - 检查服务是否运行: `netstat -tlnp | grep 3001`
   - 确认防火墙设置

2. **Android APK安装失败**
   - 启用"未知来源"安装
   - 检查设备存储空间

3. **网络连接问题**
   - 确保设备在同一局域网
   - 检查IP地址是否正确

### 性能优化
- 使用release版本获得最佳性能
- 启用浏览器硬件加速
- 关闭不必要的后台应用

---

**🎯 开始你的高效工作之旅！**

无论在哪个平台，Pomodoro Genie都能帮助你保持专注，提高工作效率！