# 🚀 Pomodoro Genie 部署指南

## 📋 部署选项概览

Pomodoro Genie 支持多种部署方式，您可以根据需求选择最适合的方案：

| 部署方式 | 适用场景 | 复杂度 | 推荐度 |
|---------|---------|--------|--------|
| **Docker容器化** | 生产环境、多服务器 | 中等 | ⭐⭐⭐⭐⭐ |
| **macOS原生** | macOS开发/测试 | 简单 | ⭐⭐⭐⭐ |
| **一键启动** | 快速体验、开发 | 最简单 | ⭐⭐⭐⭐⭐ |
| **手动部署** | 自定义需求 | 复杂 | ⭐⭐ |

## 🚀 快速开始（推荐）

### 一键启动脚本
```bash
# 克隆项目
git clone https://github.com/your-username/pomodoro-genie.git
cd pomodoro-genie

# 一键启动所有服务
bash start-pomodoro.sh

# 访问应用
# Web应用: http://localhost:3001
# API接口: http://localhost:8081
```

这将自动启动：
- Go API服务器（端口8081）
- Flutter Web应用（端口3001）
- 自动检测本机IP，支持跨设备访问

## 🐳 Docker容器化部署

### 系统要求
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM
- 10GB 可用磁盘空间

### 生产环境架构
```
┌─────────────────────────────────────────────────────────────┐
│                    Docker 生产环境架构                        │
├─────────────────────────────────────────────────────────────┤
│  🌐 Nginx (80/443)                                          │
│  ├── 反向代理和负载均衡                                        │
│  ├── SSL终止                                                │
│  └── 静态文件服务                                            │
├─────────────────────────────────────────────────────────────┤
│  🖥️ Web Frontend (8080)                                    │
│  ├── Flutter Web应用                                        │
│  └── PWA支持                                                │
├─────────────────────────────────────────────────────────────┤
│  🔧 Backend API (8081)                                      │
│  ├── Go + Gin框架                                           │
│  ├── JWT认证                                                │
│  └── RESTful API                                            │
├─────────────────────────────────────────────────────────────┤
│  🗄️ PostgreSQL (5432)                                      │
│  └── 主数据库                                                │
├─────────────────────────────────────────────────────────────┤
│  🚀 Redis (6379)                                            │
│  ├── 缓存服务                                                │
│  └── 会话存储                                                │
└─────────────────────────────────────────────────────────────┘
```

### 部署步骤

#### 1. 环境配置
```bash
# 复制环境变量模板
cp env.production.template .env

# 编辑 .env 文件，设置关键变量
POSTGRES_DB=pomodoro_genie
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here
REDIS_PASSWORD=your_redis_password_here
JWT_SECRET=your_jwt_secret_key_here_must_be_very_long_and_secure
```

#### 2. SSL证书配置（可选）
```bash
# 创建SSL目录
mkdir -p ssl

# 使用Let's Encrypt (推荐)
certbot certonly --standalone -d yourdomain.com
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem

# 或使用自签名证书 (仅用于测试)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem -out ssl/cert.pem
```

#### 3. 一键部署
```bash
# 执行一键部署脚本
chmod +x deploy-docker-production.sh
./deploy-docker-production.sh
```

#### 4. 服务管理
```bash
# 启动所有服务
./manage-docker-services.sh start

# 停止所有服务
./manage-docker-services.sh stop

# 查看服务状态
./manage-docker-services.sh status

# 查看日志
./manage-docker-services.sh logs

# 健康检查
./manage-docker-services.sh health
```

### 访问地址
- **Web应用**: http://localhost:8080
- **API接口**: http://localhost:8081
- **Nginx代理**: http://localhost (HTTP) / https://localhost (HTTPS)

## 🍎 macOS原生部署

### 系统要求
- macOS 10.15 (Catalina) 或更高版本
- 4GB RAM
- 2GB 可用磁盘空间
- Python 3.7+
- Flutter 3.24.0+

### 环境准备
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

#### 2. 构建应用
```bash
# 构建macOS应用
flutter build macos --release

# 检查构建结果
ls -la build/macos/Build/Products/Release/
```

#### 3. 创建安装包
```bash
# 创建DMG
hdiutil create -volname "PomodoroGenie" \
  -srcfolder build/macos/Build/Products/Release/PomodoroGenie.app \
  -ov -format UDZO PomodoroGenie-1.0.0.dmg
```

## 🌐 跨平台访问

### 网络配置
```bash
# 确保防火墙允许3001端口
sudo ufw allow 3001

# 查找服务器IP
ip addr show | grep inet
# 或
ifconfig | grep inet
```

### 访问方式
- **本地访问**: http://localhost:3001
- **网络访问**: http://[你的IP]:3001
- **API接口**: http://[你的IP]:8081

## 🔧 服务管理

### 使用服务管理脚本
```bash
# macOS服务管理
./macos-service-manager.sh start|stop|restart|status|logs

# Docker服务管理
./manage-docker-services.sh start|stop|restart|status|logs|health
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

## 📊 监控和维护

### 健康检查
```bash
# HTTP健康检查
curl -f http://localhost:3001 || echo "服务异常"

# 端口检查
lsof -i :3001 || echo "端口未监听"

# 进程检查
pgrep -f "python3 -m http.server" || echo "进程未运行"
```

### 日志管理
```bash
# 查看应用日志
tail -f /Applications/PomodoroGenie/logs/app.log

# Docker日志
docker-compose -f docker-compose.production.yml logs -f

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

#### 4. Docker服务问题
```bash
# 检查Docker状态
docker info

# 检查端口占用
netstat -tulpn | grep :8080
netstat -tulpn | grep :8081

# 查看详细日志
docker-compose -f docker-compose.production.yml logs
```

## 🔒 安全配置

### 防火墙设置
```bash
# macOS防火墙
sudo pfctl -f /etc/pf.conf
echo "pass in proto tcp from any to any port 3001" >> /etc/pf.conf

# Linux防火墙
sudo ufw allow 3001
sudo ufw allow 8080
sudo ufw allow 8081
```

### SSL/TLS配置
```bash
# 生成自签名证书
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# 使用HTTPS服务器
python3 -m http.server 3001 --bind 0.0.0.0 --cert cert.pem --key key.pem
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

**最后更新**: 2025-01-07  
**版本**: 1.0.0  
**维护者**: Pomodoro Genie 开发团队
