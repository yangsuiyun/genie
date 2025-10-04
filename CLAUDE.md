# 🍅 Pomodoro Genie Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-04

## 🔧 Active Technologies (Current Implementation)
- **Frontend**: Flutter 3.24.3 (Dart 3.5+)
- **Backend**: Go 1.21+ with Gin framework
- **Database**: PostgreSQL 15 (via Docker)
- **Cache**: Redis 7 (via Docker)
- **State Management**: Singleton pattern (PomodoroState, AppSettings)
- **Web**: Modern flutter_bootstrap.js
- **Deployment**: Docker Compose + Nginx

## 📁 Project Structure
```
pomodoro-genie/
├── backend/                 # Go API服务
│   ├── main.go             # API入口
│   └── go.mod              # Go依赖
├── mobile/                 # Flutter应用
│   ├── lib/
│   │   ├── main.dart       # 应用入口和状态管理
│   │   └── settings.dart   # 全功能设置系统
│   ├── web/                # Web部署文件
│   └── pubspec.yaml        # Flutter依赖
├── docker-compose.yml      # 开发环境配置
├── start-pomodoro.sh       # 一键启动脚本
└── stop-pomodoro.sh        # 停止服务脚本
```

## 🚀 Essential Commands

### 快速启动（推荐）
```bash
# 一键启动所有服务
bash start-pomodoro.sh

# 停止所有服务
bash stop-pomodoro.sh
```

### 开发环境
```bash
# 启动数据库服务
docker-compose up -d

# 启动Go后端API (端口8081)
cd backend && go run main.go

# 启动Flutter Web (端口3001)
cd mobile && flutter run -d web-server --web-port 3001 --web-hostname 0.0.0.0

# 构建Flutter Web发布版
cd mobile && flutter build web --release
```

### 测试命令
```bash
# Flutter测试
cd mobile && flutter test

# Go测试
cd backend && go test ./...

# 检查代码格式
cd mobile && flutter analyze
cd backend && go fmt ./...
```

### 构建命令
```bash
# 构建所有平台
cd mobile && flutter build web --release
cd mobile && flutter build apk --release
cd backend && go build -o pomodoro-api main.go
```

## 🎨 Code Style
- **Flutter**: 遵循官方Dart风格指南
- **Go**: 使用gofmt和golint
- **状态管理**: 使用Singleton模式，避免全局变量
- **UI组件**: Material Design 3
- **命名**: 使用英文命名变量和函数，中文用于UI文本

## 📋 Recent Changes
- 2025-10-04: 实现全功能设置系统 (settings.dart)
- 2025-10-04: 修复计时器实时更新和状态持久化
- 2025-10-04: 添加5种主题颜色支持
- 2025-10-04: 优化Flutter Web启动流程
- 2025-10-04: 创建一键启动脚本
- 2025-10-03: 完成项目初始架构设置

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
