# 🍎 MacBook生产环境部署指南
# PomodoroGenie - macOS生产环境完整部署文档

## 📋 概述

本文档提供了在MacBook上部署PomodoroGenie生产环境的完整指南，包括Flutter Web应用部署、macOS原生应用打包、服务管理和监控。

## 🎯 部署选项

### 选项1: Flutter Web应用 (推荐)
- **适用场景**: 快速部署、跨平台访问
- **优势**: 无需安装、自动更新、易于维护
- **部署方式**: HTTP服务器 + 系统服务

### 选项2: macOS原生应用
- **适用场景**: 离线使用、系统集成
- **优势**: 原生性能、系统通知、本地存储
- **部署方式**: .app包 + DMG安装包

## 🚀 快速开始

### 1. 系统要求

**最低要求**:
- macOS 10.15 (Catalina) 或更高版本
- 4GB RAM
- 2GB 可用磁盘空间
- Python 3.7+
- Flutter 3.24.0+

**推荐配置**:
- macOS 12.0 (Monterey) 或更高版本
- 8GB RAM
- 10GB 可用磁盘空间
- Python 3.9+
- Flutter 3.24.0+

### 2. 环境准备

```bash
# 安装Homebrew (如果未安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装Flutter
brew install flutter

# 安装Python3
brew install python3

# 验证安装
flutter --version
python3 --version
```

### 3. 一键部署

```bash
# 克隆项目
git clone https://github.com/your-username/pomodoro-genie.git
cd pomodoro-genie

# 执行部署脚本
chmod +x deploy-macbook-production.sh
./deploy-macbook-production.sh
```

## 📦 详细部署步骤

### Flutter Web应用部署

#### 1. 构建应用

```bash
# 进入移动端目录
cd mobile

# 清理并获取依赖
flutter clean
flutter pub get

# 构建Web应用
flutter build web --release --web-renderer html
```

#### 2. 部署到系统

```bash
# 创建应用目录
sudo mkdir -p /Applications/PomodoroGenie
sudo chown -R $(whoami):staff /Applications/PomodoroGenie

# 复制构建文件
cp -r build/web/* /Applications/PomodoroGenie/

# 创建启动脚本
cat > /Applications/PomodoroGenie/start.sh << 'EOF'
#!/bin/bash
cd /Applications/PomodoroGenie
python3 -m http.server 3001 --bind 0.0.0.0
EOF

chmod +x /Applications/PomodoroGenie/start.sh
```

#### 3. 配置系统服务

```bash
# 创建LaunchDaemon配置
sudo cat > /Library/LaunchDaemons/com.pomodorogenie.app.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.pomodorogenie.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/PomodoroGenie/start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# 加载服务
sudo launchctl load /Library/LaunchDaemons/com.pomodorogenie.app.plist
```

### macOS原生应用打包

#### 1. 启用macOS支持

```bash
cd mobile
flutter config --enable-macos-desktop
```

#### 2. 配置权限

```bash
# 创建权限文件
cat > macos/Runner/DebugProfile.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
EOF
```

#### 3. 构建应用

```bash
# 构建macOS应用
flutter build macos --release

# 检查构建结果
ls -la build/macos/Build/Products/Release/
```

#### 4. 代码签名 (可选)

```bash
# 使用开发者证书签名
codesign --force --deep --sign "Developer ID Application: Your Name" \
  build/macos/Build/Products/Release/PomodoroGenie.app

# 验证签名
codesign --verify --verbose build/macos/Build/Products/Release/PomodoroGenie.app
```

#### 5. 创建安装包

```bash
# 创建DMG
hdiutil create -volname "PomodoroGenie" \
  -srcfolder build/macos/Build/Products/Release/PomodoroGenie.app \
  -ov -format UDZO PomodoroGenie-1.0.0.dmg
```

## ⚙️ 服务管理

### 使用服务管理脚本

```bash
# 启动服务
./macos-service-manager.sh start

# 停止服务
./macos-service-manager.sh stop

# 重启服务
./macos-service-manager.sh restart

# 查看状态
./macos-service-manager.sh status

# 查看日志
./macos-service-manager.sh logs

# 实时日志
./macos-service-manager.sh follow

# 健康检查
./macos-service-manager.sh health
```

### 手动管理

```bash
# 启动服务
cd /Applications/PomodoroGenie
python3 -m http.server 3001 --bind 0.0.0.0 &

# 停止服务
pkill -f "python3 -m http.server 3001"

# 查看进程
ps aux | grep "python3 -m http.server"

# 查看端口
lsof -i :3001
```

## 🔧 配置管理

### 生产环境配置

编辑 `/Applications/PomodoroGenie/config/macos-production.config`:

```bash
# 服务器配置
SERVER_HOST="0.0.0.0"
SERVER_PORT=3001

# 日志配置
LOG_LEVEL="info"
LOG_FILE="/Applications/PomodoroGenie/logs/app.log"

# 安全配置
JWT_SECRET="your-super-secret-jwt-key"
CORS_ORIGINS="http://localhost:3001"
```

### 环境变量

```bash
# 设置环境变量
export NODE_ENV="production"
export FLUTTER_WEB_USE_SKIA=false

# 持久化环境变量
echo 'export NODE_ENV="production"' >> ~/.zshrc
echo 'export FLUTTER_WEB_USE_SKIA=false' >> ~/.zshrc
```

## 📊 监控和维护

### 日志管理

```bash
# 查看应用日志
tail -f /Applications/PomodoroGenie/logs/app.log

# 查看错误日志
tail -f /Applications/PomodoroGenie/logs/error.log

# 清理旧日志
find /Applications/PomodoroGenie/logs -name "*.log" -mtime +7 -delete
```

### 性能监控

```bash
# 监控CPU使用率
top -pid $(pgrep -f "python3 -m http.server")

# 监控内存使用
ps -o pid,ppid,user,pmem,pcpu,comm -p $(pgrep -f "python3 -m http.server")

# 监控网络连接
netstat -an | grep :3001
```

### 健康检查

```bash
# HTTP健康检查
curl -f http://localhost:3001 || echo "服务异常"

# 端口检查
lsof -i :3001 || echo "端口未监听"

# 进程检查
pgrep -f "python3 -m http.server" || echo "进程未运行"
```

## 🔒 安全配置

### 防火墙设置

```bash
# 允许本地访问
sudo pfctl -f /etc/pf.conf

# 添加防火墙规则
echo "pass in proto tcp from any to any port 3001" >> /etc/pf.conf
```

### SSL/TLS配置 (可选)

```bash
# 生成自签名证书
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# 使用HTTPS服务器
python3 -m http.server 3001 --bind 0.0.0.0 --cert cert.pem --key key.pem
```

## 🚨 故障排除

### 常见问题

#### 1. 端口被占用

```bash
# 查找占用端口的进程
lsof -i :3001

# 杀死占用进程
kill -9 <PID>
```

#### 2. 权限问题

```bash
# 修复权限
sudo chown -R $(whoami):staff /Applications/PomodoroGenie
chmod +x /Applications/PomodoroGenie/start.sh
```

#### 3. 服务无法启动

```bash
# 检查日志
tail -f /Applications/PomodoroGenie/logs/error.log

# 手动启动测试
cd /Applications/PomodoroGenie
python3 -m http.server 3001 --bind 0.0.0.0
```

#### 4. Flutter构建失败

```bash
# 清理Flutter缓存
flutter clean
flutter pub get

# 检查Flutter版本
flutter --version

# 重新构建
flutter build web --release
```

### 日志分析

```bash
# 分析错误日志
grep -i error /Applications/PomodoroGenie/logs/app.log

# 分析访问日志
grep "GET\|POST" /Applications/PomodoroGenie/logs/app.log | tail -20

# 统计访问量
grep "GET" /Applications/PomodoroGenie/logs/app.log | wc -l
```

## 📈 性能优化

### 系统优化

```bash
# 增加文件描述符限制
echo "kern.maxfiles=65536" | sudo tee -a /etc/sysctl.conf
echo "kern.maxfilesperproc=32768" | sudo tee -a /etc/sysctl.conf

# 优化网络参数
echo "net.inet.tcp.keepidle=60000" | sudo tee -a /etc/sysctl.conf
echo "net.inet.tcp.keepintvl=10000" | sudo tee -a /etc/sysctl.conf
```

### 应用优化

```bash
# 启用Gzip压缩
python3 -c "
import http.server
import socketserver
from http.server import SimpleHTTPRequestHandler
import gzip
import io

class GzipHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Content-Encoding', 'gzip')
        super().end_headers()
    
    def send_response(self, code, message=None):
        super().send_response(code, message)
        self.send_header('Content-Encoding', 'gzip')

with socketserver.TCPServer(('', 3001), GzipHTTPRequestHandler) as httpd:
    httpd.serve_forever()
"
```

## 🔄 更新和维护

### 自动更新

```bash
# 创建更新脚本
cat > /Applications/PomodoroGenie/update.sh << 'EOF'
#!/bin/bash
cd /path/to/pomodoro-genie
git pull origin master
cd mobile
flutter build web --release
cp -r build/web/* /Applications/PomodoroGenie/
sudo launchctl restart com.pomodorogenie.app
EOF

chmod +x /Applications/PomodoroGenie/update.sh
```

### 定期维护

```bash
# 创建维护脚本
cat > /Applications/PomodoroGenie/maintenance.sh << 'EOF'
#!/bin/bash
# 清理日志
find /Applications/PomodoroGenie/logs -name "*.log" -mtime +30 -delete

# 清理临时文件
find /Applications/PomodoroGenie -name "*.tmp" -delete

# 重启服务
sudo launchctl restart com.pomodorogenie.app
EOF

# 添加到crontab
echo "0 2 * * 0 /Applications/PomodoroGenie/maintenance.sh" | crontab -
```

## 📞 支持和联系

### 技术支持

- **GitHub Issues**: https://github.com/your-username/pomodoro-genie/issues
- **文档**: https://github.com/your-username/pomodoro-genie/wiki
- **社区**: https://github.com/your-username/pomodoro-genie/discussions

### 紧急联系

- **紧急问题**: 创建GitHub Issue并标记为 `urgent`
- **安全漏洞**: 发送邮件到 security@pomodorogenie.com
- **功能请求**: 创建GitHub Issue并标记为 `enhancement`

---

## 📝 更新日志

### v1.0.0 (2025-01-07)
- ✅ 初始版本发布
- ✅ Flutter Web应用部署
- ✅ macOS原生应用打包
- ✅ 系统服务管理
- ✅ 监控和维护工具

---

**🍎 PomodoroGenie for macOS - 专注力管理工具**
