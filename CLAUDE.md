# 🍅 Pomodoro Genie Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-05

## 🔧 Active Technologies (Current Implementation)
- **Frontend**: Flutter 3.24.3 (Dart 3.5+)
- **Backend**: Go 1.21+ with Gin framework
- **Database**: PostgreSQL 15 (via Docker)
- **Cache**: Redis 7 (via Docker)
- **State Management**: Singleton pattern (PomodoroState, AppSettings)
- **Web**: Enhanced HTML/CSS/JavaScript实现 (完全集成的番茄钟应用)
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
│   ├── build/web/          # Web构建文件
│   │   └── index.html      # 完整的番茄钟Web应用 (34KB)
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

# 启动Flutter Web (端口3001) 或 静态Web服务器 (端口3002)
cd mobile && flutter run -d web-server --web-port 3001 --web-hostname 0.0.0.0
# 或者启动静态Web服务器
cd mobile/build/web && python3 -m http.server 3002

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

## 📊 Implementation Status (45% Complete)

### ✅ Completed Features
- **基础UI框架**: 四个主要界面（番茄钟、任务、报告、设置）
- **计时器核心**: 完整的番茄钟功能 (mobile/build/web/index.html)
  - 可自定义工作时长、短休息、长休息时间 (1-60分钟)
  - 长休息间隔管理 (1-10个番茄钟)
  - 实时倒计时显示和状态切换
  - 休息建议和手动控制
- **任务关联系统**: 任务与番茄钟的完整集成
  - 当前任务卡片显示 (任务名称、描述、统计)
  - 实时进度追踪和番茄钟完成指示器
  - 任务选择和切换界面
  - 自由番茄钟模式 (无任务关联)
- **设置系统**: 完整的用户偏好配置
  - 番茄钟时长设置 (工作/短休息/长休息/间隔)
  - 通知设置 (声音提醒/桌面通知开关)
  - 主题和界面自定义设置
- **主题支持**: 5种颜色主题 + 自动换色
  - 番茄红、天空蓝、森林绿、薰衣草紫、活力橙
  - 实时主题切换和预览
  - 自动换色功能
- **任务管理**: 基础任务CRUD操作
  - 任务创建（名称+描述）、编辑、删除
  - 任务列表显示和管理
  - 任务状态追踪（完成的番茄钟数量）
- **API架构**: RESTful API结构和端点 (backend/main.go)

### 🟡 Partially Implemented (35% Remaining)
- **数据持久化**: 内存存储实现，需要数据库集成
- **通知系统**: UI设置完成，需要实际通知逻辑
- **报告统计**: 静态示例展示，需要真实数据分析
- **任务功能**: 基础CRUD完成，缺少子任务、到期日期、重复任务

### ❌ Missing Features (20% Remaining)
- **用户认证**: 无真实登录/注册系统 (代码已准备)
- **数据同步**: 无多设备同步、离线存储
- **高级任务**: 子任务、标签、优先级系统
- **跨平台**: 仅Web版本，缺少移动端应用

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

## 🚧 Next Priority Features (数据持久化优先)

### Phase 1: 数据持久化 (优先级最高)
1. ✅ **真实任务管理**: 完整的任务CRUD操作
2. ✅ **计时器集成**: 任务与番茄钟完全关联
3. 🚧 **本地存储**: 实现localStorage数据持久化
4. 🚧 **基础通知**: 计时器完成时的浏览器通知

### Phase 2: 数据分析和优化
1. **真实报告**: 基于实际使用数据的统计分析
2. **数据导入导出**: JSON格式的数据备份和恢复
3. **离线功能**: 完全无网络时的使用体验
4. **性能优化**: 大量数据时的渲染优化

### Phase 3: 高级功能
1. **高级任务**: 子任务、重复任务、标签系统
2. **用户认证**: JWT登录系统 (代码已准备)
3. **数据同步**: 多设备间的数据同步
4. **跨平台**: iOS/Android/Desktop应用

## 📋 Recent Changes
- 2025-10-05: 🎨 完成完整设置系统重构 (mobile/build/web/index.html)
  - 添加所有番茄钟时长设置 (工作/短休息/长休息/间隔)
  - 实现通知设置开关 (声音/桌面通知)
  - 完善主题选择和自动换色功能
- 2025-10-05: 🔗 实现任务-番茄钟关联增强
  - 当前任务卡片显示和进度追踪
  - 任务选择界面和切换功能
  - 番茄钟完成指示器和统计
- 2025-10-05: 🐛 修复6个关键UI Bug
  - 任务自定义功能、主题颜色应用、计时器显示等
- 2025-10-05: 🔧 创建JWT认证和任务管理服务 (backend/internal/services/)
- 2025-10-05: 📊 将项目完成度从25%提升到45%
- 2025-10-04: 实现全功能设置系统 (settings.dart)
- 2025-10-04: 修复计时器实时更新和状态持久化
- 2025-10-04: 添加5种主题颜色支持
- 2025-10-03: 完成项目初始架构设置

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
