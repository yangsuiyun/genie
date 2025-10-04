# 🍅 Pomodoro Genie 平台使用指南

## 📱 支持的平台

- **Web** ✅ (已就绪)
- **MacBook** ✅ (桌面版 + 浏览器)
- **Android** ✅ (APK + 浏览器)
- **iOS** ⚠️ (需要开发者账号)
- **Windows** ✅ (桌面版)
- **Linux** ✅ (桌面版)

## 🖥️ MacBook 使用方法

### 方法1: 一键启动访问（推荐）
```bash
# 在项目目录运行一键启动脚本
bash start-pomodoro.sh

# 脚本会自动：
# - 启动Go API服务器（端口8081）
# - 启动Flutter Web应用（端口3001）
# - 检测并显示访问地址
```

### 方法2: 本地浏览器访问
```bash
# 在Safari、Chrome或任何现代浏览器中打开
http://localhost:3001
```

### 方法3: 网络访问（同一局域网）
```bash
# 在MacBook浏览器中访问服务器IP
http://[服务器IP]:3001

# IP地址会在start-pomodoro.sh启动时自动显示
```

### 方法4: 原生macOS应用（可选）
```bash
# 在服务器上构建macOS版本
flutter build macos --release

# 将生成的应用传输到MacBook
# 路径: build/macos/Build/Products/Release/pomodoro_genie.app
```

## 📱 Android 使用方法

### 方法1: 安装APK应用
```bash
# 构建Android APK
flutter build apk --release

# 生成的APK位置: build/app/outputs/flutter-apk/app-release.apk
# 传输到Android设备安装
```

### 方法2: 浏览器访问（推荐）
```bash
# 使用一键启动脚本启动服务
bash start-pomodoro.sh

# 在Android Chrome中打开显示的网络地址
http://[显示的IP]:3001
```

### 方法3: PWA安装
1. 在Android Chrome中访问应用网址
2. 点击菜单中的"添加到主屏幕"
3. 应用会作为PWA安装，体验接近原生应用
4. 支持离线使用和推送通知

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

### 🍅 核心番茄计时器
- **实时倒计时** - 精确的Timer.periodic计时，真实时间更新
- **状态持久化** - 页面切换保持计时状态不丢失
- **自定义时长** - 1-60分钟工作时间自由设置
- **动画效果** - 优美的圆形进度条实时动画
- **智能提示** - 专注中/准备工作的状态指示

### ⚙️ 全面设置系统
- **时间配置** - 滚轮选择器设置工作/短休息/长休息时长
- **主题定制** - 5种精美颜色主题（番茄红、天空蓝、森林绿、薰衣草紫、活力橙）
- **自动化控制** - 自动开始休息/番茄钟的智能切换
- **通知管理** - 推送通知和声音提醒独立开关
- **高级设置** - 长休息间隔配置（2-8个番茄钟）
- **用户指南** - 内置完整番茄工作法教程
- **重置功能** - 一键恢复默认设置

### 📋 任务管理
- **现代化界面** - Material Design卡片布局
- **优先级系统** - 高/中/低优先级彩色标签
- **完成跟踪** - 复选框交互和完成状态展示
- **详细描述** - 任务标题和详细说明

### 📊 数据统计
- **实时数据** - 今日完成番茄钟数、专注时间、任务完成数
- **效率评分** - 基于工作表现的智能评分系统
- **可视化展示** - 美观的统计卡片和彩色图标
- **多维度分析** - 多种数据维度统计

### 🌐 跨平台体验
- **PWA支持** - 现代化渐进式Web应用
- **网络访问** - MacBook和Android设备无缝跨网络使用
- **响应式设计** - 适配各种屏幕尺寸
- **一键启动** - start-pomodoro.sh自动化部署脚本

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