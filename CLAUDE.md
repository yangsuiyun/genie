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

## 📊 Implementation Status (25% Complete)

### ✅ Completed Features
- **基础UI框架**: 四个主要界面（番茄钟、任务、报告、设置）
- **计时器核心**: 可自定义工作时长的倒计时器 (mobile/lib/main.dart:32-119)
- **设置系统**: 完整的用户偏好设置 (mobile/lib/settings.dart)
- **主题支持**: 5种颜色主题 (番茄红、天空蓝、森林绿、薰衣草紫、活力橙)
- **API架构**: RESTful API结构和端点 (backend/main.go)
- **状态管理**: Singleton模式的PomodoroState和AppSettings

### ❌ Missing Critical Features (75% Remaining)
- **数据持久化**: 无PostgreSQL集成，数据无法保存
- **用户认证**: 无真实登录/注册，仅有mock API
- **任务管理**: 无CRUD操作、子任务、到期日期、重复任务
- **通知系统**: 无推送通知、声音提醒、到期提醒
- **数据同步**: 无多设备同步、离线存储、冲突解决
- **备注功能**: 任务备注功能完全缺失
- **真实报告**: 无历史数据统计，仅有静态示例
- **跨平台**: 仅Web版本，缺少iOS/Android/Desktop

## 🚧 Development Roadmap

### Phase 1: Data Foundation (Priority 1)
1. **Database Setup**: 集成PostgreSQL + Redis
2. **User Authentication**: JWT认证系统
3. **Data Models**: User, Task, PomodoroSession, Note等模型

### Phase 2: Core Features (Priority 2)
1. **Task Management**: 完整CRUD + 子任务 + 重复任务
2. **Notification System**: 推送通知 + 声音提醒
3. **Notes System**: 任务备注功能

### Phase 3: Advanced Features (Priority 3)
1. **Multi-device Sync**: 数据同步 + 冲突解决
2. **Analytics**: 真实数据统计和报告
3. **Cross-platform**: iOS/Android/Desktop构建

## 🚧 Next Priority Features (认证服务暂缓)

### Phase 1: Core Task Management (优先级最高)
1. **真实任务管理**: 替换示例UI为可操作的任务CRUD
2. **计时器集成**: 连接番茄计时器与具体任务
3. **本地存储**: 任务数据持久化到本地存储
4. **基础通知**: 计时器完成时的浏览器通知

### Phase 2: 用户体验优化
1. **数据导入导出**: JSON格式的数据备份和恢复
2. **离线功能**: 无网络时的正常使用
3. **更多统计**: 真实的历史数据和生产力分析
4. **主题和设置**: 扩展当前设置系统

### Phase 3: 高级功能 (最后实现)
1. **用户认证**: JWT登录系统 (已准备好代码)
2. **数据同步**: 多设备间的数据同步
3. **推送通知**: 真实的推送通知服务
4. **跨平台**: iOS/Android/Desktop应用

## 📋 Recent Changes
- 2025-10-05: 🔧 创建JWT认证和任务管理服务 (backend/internal/services/)
- 2025-10-05: 📊 分析specs实现状态，识别75%缺失功能
- 2025-10-05: 📝 重新规划开发优先级，认证服务暂缓
- 2025-10-04: 实现全功能设置系统 (settings.dart)
- 2025-10-04: 修复计时器实时更新和状态持久化
- 2025-10-04: 添加5种主题颜色支持
- 2025-10-03: 完成项目初始架构设置

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
