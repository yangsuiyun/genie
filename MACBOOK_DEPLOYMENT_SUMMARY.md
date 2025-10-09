# 🍎 MacBook生产环境部署文件清单
# PomodoroGenie - macOS生产环境完整部署包

## 📦 部署文件概览

已为master分支创建了完整的MacBook生产环境部署文件，包含以下组件：

### 🚀 核心部署脚本

#### 1. `deploy-macbook-production.sh`
- **功能**: 一键部署Flutter Web应用到MacBook生产环境
- **特性**: 
  - 自动检查系统要求
  - 构建Flutter Web应用
  - 创建系统服务
  - 配置桌面快捷方式
  - 自动启动服务

#### 2. `build-macos-app.sh`
- **功能**: 构建macOS原生应用
- **特性**:
  - 启用macOS桌面支持
  - 配置应用权限
  - 代码签名
  - 创建DMG/PKG安装包
  - 应用公证

#### 3. `macos-service-manager.sh`
- **功能**: 服务管理和监控
- **特性**:
  - 启动/停止/重启服务
  - 状态监控
  - 日志查看
  - 健康检查
  - 实时日志跟踪

### ⚙️ 配置文件

#### 4. `macos-build-config.sh`
- **功能**: macOS应用构建配置
- **包含**:
  - 应用信息配置
  - 代码签名设置
  - 权限配置
  - 构建参数

#### 5. `macos-production.config`
- **功能**: 生产环境配置
- **包含**:
  - 服务器配置
  - 数据库配置
  - 安全设置
  - 日志配置
  - 性能参数

### 📚 文档

#### 6. `MACBOOK_DEPLOYMENT_GUIDE.md`
- **功能**: 完整部署指南
- **包含**:
  - 系统要求
  - 详细部署步骤
  - 服务管理
  - 故障排除
  - 性能优化
  - 维护指南

## 🎯 部署选项

### 选项1: Flutter Web应用 (推荐)
```bash
# 一键部署
./deploy-macbook-production.sh

# 服务管理
./macos-service-manager.sh start
./macos-service-manager.sh status
```

### 选项2: macOS原生应用
```bash
# 构建原生应用
./build-macos-app.sh

# 安装应用
open build/macos/Build/Products/Release/PomodoroGenie.dmg
```

## 📋 使用说明

### 快速开始

1. **克隆项目**
   ```bash
   git clone https://github.com/your-username/pomodoro-genie.git
   cd pomodoro-genie
   ```

2. **执行部署**
   ```bash
   chmod +x *.sh
   ./deploy-macbook-production.sh
   ```

3. **访问应用**
   - 本地访问: http://localhost:3001
   - 网络访问: http://[your-ip]:3001

### 服务管理

```bash
# 启动服务
./macos-service-manager.sh start

# 查看状态
./macos-service-manager.sh status

# 查看日志
./macos-service-manager.sh logs

# 健康检查
./macos-service-manager.sh health

# 停止服务
./macos-service-manager.sh stop
```

## 🔧 配置说明

### 生产环境配置

编辑 `macos-production.config` 文件：

```bash
# 服务器配置
SERVER_HOST="0.0.0.0"
SERVER_PORT=3001

# 安全配置
JWT_SECRET="your-super-secret-jwt-key"
CORS_ORIGINS="http://localhost:3001"

# 日志配置
LOG_LEVEL="info"
LOG_FILE="/Applications/PomodoroGenie/logs/app.log"
```

### 构建配置

编辑 `macos-build-config.sh` 文件：

```bash
# 应用信息
APP_NAME="PomodoroGenie"
APP_VERSION="1.0.0"
BUNDLE_ID="com.pomodorogenie.app"

# 代码签名
CERTIFICATE_NAME="Developer ID Application: Your Name"
```

## 🚨 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   lsof -i :3001
   kill -9 <PID>
   ```

2. **权限问题**
   ```bash
   sudo chown -R $(whoami):staff /Applications/PomodoroGenie
   ```

3. **服务无法启动**
   ```bash
   ./macos-service-manager.sh logs
   tail -f /Applications/PomodoroGenie/logs/error.log
   ```

## 📊 监控和维护

### 日志管理
- 应用日志: `/Applications/PomodoroGenie/logs/app.log`
- 错误日志: `/Applications/PomodoroGenie/logs/error.log`
- 服务日志: `/Applications/PomodoroGenie/logs/service.log`

### 性能监控
```bash
# 查看进程状态
ps aux | grep "python3 -m http.server"

# 监控端口
lsof -i :3001

# 查看系统资源
top -pid $(pgrep -f "python3 -m http.server")
```

## 🔄 更新流程

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
```

### 手动更新
```bash
# 停止服务
./macos-service-manager.sh stop

# 更新代码
git pull origin master

# 重新构建
cd mobile
flutter build web --release

# 部署更新
cp -r build/web/* /Applications/PomodoroGenie/

# 启动服务
./macos-service-manager.sh start
```

## 📞 技术支持

- **GitHub Issues**: 创建Issue获取技术支持
- **文档**: 查看 `MACBOOK_DEPLOYMENT_GUIDE.md`
- **社区**: 参与GitHub Discussions

---

## ✅ 部署检查清单

- [x] 创建部署脚本
- [x] 创建构建配置
- [x] 创建服务管理工具
- [x] 创建生产环境配置
- [x] 创建完整文档
- [x] 设置执行权限
- [x] 测试脚本功能

## 🎉 部署完成

MacBook生产环境部署文件已全部创建完成！现在可以：

1. **立即部署**: 运行 `./deploy-macbook-production.sh`
2. **构建应用**: 运行 `./build-macos-app.sh`
3. **管理服务**: 使用 `./macos-service-manager.sh`
4. **查看文档**: 阅读 `MACBOOK_DEPLOYMENT_GUIDE.md`

**🍎 PomodoroGenie for macOS - 专注力管理工具**
