# 🍅 Pomodoro Genie Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-05

## 🔧 Active Technologies (Current Implementation)
- **Frontend**: Flutter 3.24.3 (Dart 3.5+) + Standalone HTML/CSS/JS Web App
- **Backend**: Go 1.21+ with Gin framework
- **Database**: PostgreSQL 15 (via Docker) - **configured, not integrated**
- **Cache**: Redis 7 (via Docker) - **configured, not integrated**
- **State Management**:
  - Flutter: Singleton pattern (PomodoroState, AppSettings)
  - Web: localStorage + JavaScript state management
- **Data Persistence**:
  - Flutter: Local services (TaskService, SessionService, NotificationService)
  - Web: Browser localStorage (fully functional)
- **Deployment**: Docker Compose + Nginx

## 📁 Project Structure
```
pomodoro-genie/
├── backend/                      # Go API服务
│   ├── main.go                   # 基础API入口 (mock endpoints)
│   ├── internal/
│   │   ├── models/              # 完整数据模型 (10+ files)
│   │   ├── services/            # 业务逻辑服务 (9 files)
│   │   ├── handlers/            # HTTP处理器 (4 files)
│   │   └── middleware/          # 中间件 (4 files)
│   └── go.mod                    # Go依赖
├── mobile/                       # Flutter应用
│   ├── lib/
│   │   ├── main.dart            # 完整Flutter应用 (1927行)
│   │   ├── settings.dart        # 设置系统
│   │   ├── models/              # Task, PomodoroSession模型
│   │   ├── services/            # TaskService, SessionService, NotificationService等
│   │   ├── screens/             # 4个主要界面 + 认证界面
│   │   └── providers/           # 状态管理providers
│   ├── build/web/               # Web构建文件
│   │   └── index.html           # 独立Web应用 (2072行, 完整功能)
│   ├── web/                     # Web部署文件
│   ├── test/                    # 测试文件 (widget + timer)
│   └── pubspec.yaml             # Flutter依赖
├── docker-compose.yml           # 开发环境配置
├── start-pomodoro.sh            # 一键启动脚本
└── stop-pomodoro.sh             # 停止服务脚本
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

## 📊 Implementation Status (85% Complete)

### ✅ Completed Features (Flutter + Web) - 85% Complete

#### 核心功能 (Core Features) - 100% Complete
- **完整Flutter应用** (mobile/lib/main.dart - 1927行):
  - ✅ 四个主要界面（番茄钟、任务、报告、设置）
  - ✅ 完整状态管理 (PomodoroState singleton)
  - ✅ 会话管理 (SessionService) - 工作/短休息/长休息
  - ✅ 任务服务 (TaskService) - 完整CRUD + 状态追踪
  - ✅ 通知服务 (NotificationService) - 浏览器通知权限
  - ✅ 同步服务 (SyncService) - 在线/离线状态

- **独立Web应用** (mobile/build/web/index.html - 2072行):
  - ✅ 完全独立运行（无需Flutter构建）
  - ✅ 完整番茄钟计时器 (25分钟工作 + 5/15分钟休息)
  - ✅ localStorage数据持久化 (任务 + 设置)
  - ✅ 任务管理系统 (创建/编辑/删除/完成)
  - ✅ 任务-番茄钟关联 (当前任务卡片 + 进度追踪)
  - ✅ 5种主题色 + 自动换色
  - ✅ 声音提醒 (Web Audio API)
  - ✅ 桌面通知 (Notification API)
  - ✅ 统计报告 (真实数据分析)
  - ✅ 响应式设计 (移动端/桌面端适配)
  - ✅ 自动休息管理 (工作完成后自动开始休息)
  - ✅ 计划番茄钟功能 (任务可设置预计番茄钟数量)

#### 任务管理 (Task Management)
- ✅ 任务CRUD操作 (创建/读取/更新/删除)
- ✅ 任务状态管理 (待开始/进行中/已完成)
- ✅ 任务优先级 (低/中/高/紧急)
- ✅ 子任务系统 (Flutter)
- ✅ 到期日期追踪 (Flutter)
- ✅ 番茄钟完成计数 (Flutter + Web)
- ✅ 任务备注功能 (Flutter)
- ✅ 任务进度条显示

#### 数据持久化 (Data Persistence)
- ✅ Web localStorage实现 (完全功能)
- ✅ Flutter本地服务 (TaskService, SessionService)
- ✅ 任务数据自动保存
- ✅ 设置数据持久化
- ✅ 会话历史记录 (Flutter SessionService)

#### 统计报告 (Analytics & Reports)
- ✅ 今日统计 (完成番茄钟数/专注时间)
- ✅ 总体统计 (总会话数/总时间/平均时长)
- ✅ 本周趋势图 (7天数据可视化)
- ✅ 时间分布热力图 (24小时分布)
- ✅ 任务完成率统计
- ✅ 生产力洞察 (连续专注天数/最佳工作时间)

#### Backend架构
- ✅ RESTful API结构 (backend/main.go)
- ✅ 完整数据模型 (User, Task, Session, Note等)
- ✅ 认证服务架构 (JWT准备完成)
- ✅ 任务服务实现 (backend/internal/services/)
- ✅ 中间件系统 (CORS, Auth, Rate Limit, Error)
- ✅ Mock API端点 (用于测试)

### 🟡 Partially Implemented (10% Remaining)

#### Backend集成
- 🚧 **数据库集成**: PostgreSQL配置完成，未连接
- 🚧 **Redis缓存**: Docker配置完成，未集成
- 🚧 **用户认证**: JWT服务代码完成，未激活
- 🚧 **API集成**: Flutter ApiClient实现，未连接后端

#### 高级功能
- 🚧 **重复任务**: 模型完成 (RecurrenceRule)，UI未实现
- 🚧 **任务标签**: 准备中
- 🚧 **多设备同步**: SyncService框架完成，服务端未实现

### ❌ Missing Features (5% Remaining)
- ❌ **用户认证UI**: 登录/注册界面存在但未激活
- ❌ **真实数据同步**: 跨设备数据同步服务端
- ❌ **移动应用构建**: Flutter支持但未构建APK/iOS
- ❌ **高级过滤**: 任务按标签/日期/优先级复杂过滤
- ❌ **数据导出**: JSON/CSV导出功能

## 🚧 Development Roadmap

### ✅ Phase 1: Core Foundation (COMPLETED)
1. ✅ **Frontend Framework**: Flutter应用 + 独立Web应用
2. ✅ **State Management**: Singleton模式 + localStorage
3. ✅ **Task Management**: 完整CRUD + 状态管理
4. ✅ **Pomodoro Timer**: 工作/休息循环 + 自动切换
5. ✅ **Data Persistence**: localStorage (Web) + Local Services (Flutter)
6. ✅ **Notification System**: 声音 + 桌面通知
7. ✅ **Analytics & Reports**: 真实数据统计和可视化

### 🚧 Phase 2: Backend Integration (IN PROGRESS)
**Priority 1: Database Connection**
1. 🚧 连接PostgreSQL数据库
2. 🚧 实现GORM数据模型映射
3. 🚧 迁移localStorage数据到PostgreSQL
4. 🚧 实现Redis会话缓存

**Priority 2: API Integration**
1. 🚧 激活Flutter ApiClient
2. 🚧 实现前后端API通信
3. 🚧 数据同步机制 (本地 ↔ 服务器)
4. 🚧 离线模式支持

**Priority 3: User Authentication**
1. 🚧 激活JWT认证系统
2. 🚧 实现登录/注册UI流程
3. 🚧 用户数据隔离
4. 🚧 Token刷新机制

### ⏳ Phase 3: Advanced Features (PLANNED)
**Priority 1: Task Enhancements**
1. ❌ 重复任务UI实现 (模型已完成)
2. ❌ 任务标签系统
3. ❌ 高级过滤和搜索
4. ❌ 任务模板功能

**Priority 2: Multi-device Sync**
1. ❌ 冲突解决策略
2. ❌ 增量同步优化
3. ❌ 实时数据推送
4. ❌ 离线队列管理

**Priority 3: Platform Expansion**
1. ❌ 构建Android APK
2. ❌ 构建iOS IPA
3. ❌ Desktop应用 (Windows/Mac/Linux)
4. ❌ PWA优化

## 🎯 Next Priority Actions (按优先级排序)

### 立即可做 (Immediate - Week 1)
1. **数据库连接**: 激活PostgreSQL + GORM集成
2. **API激活**: 连接Flutter前端到Go后端
3. **用户认证**: 启用JWT登录系统
4. **数据迁移**: localStorage → PostgreSQL迁移工具

### 短期目标 (Short-term - Week 2-4)
1. **重复任务**: 实现UI + 后端逻辑
2. **标签系统**: 添加任务标签功能
3. **数据导出**: JSON/CSV导出功能
4. **移动构建**: 构建并测试Android/iOS应用

### 中期目标 (Mid-term - Month 2-3)
1. **多设备同步**: 完整同步系统
2. **高级分析**: 更深入的数据洞察
3. **性能优化**: 大数据集优化
4. **Desktop应用**: Electron或Flutter Desktop

## 📋 Recent Changes & Project History

### 2025-10-07: 📊 项目进度更新 - 完成度提升至85%
- 📊 **项目完成度评估**: 从65%提升至**85%完成**
- 📝 基于最新代码分析的实际实现状态:
  - ✅ Flutter应用完整实现 (1927行代码)
  - ✅ 独立Web应用完全功能 (2072行, localStorage持久化)
  - ✅ 完整统计报告系统 (7天趋势 + 24小时热力图)
  - ✅ 任务管理系统 (CRUD + 状态追踪 + 优先级)
  - ✅ 设置系统完全实现 (所有功能正常工作)
  - ✅ 数据持久化系统 (localStorage + 本地服务)
  - ✅ 通知系统 (声音 + 桌面通知)
  - ✅ 主题系统 (5种颜色 + 自动换色)
  - ✅ 自动休息管理 (工作-休息循环)
  - ✅ 计划番茄钟功能 (任务可设置预计数量)
  - 🚧 Backend架构完成但未集成 (PostgreSQL/Redis配置完成)
  - 🚧 JWT认证服务代码完成但未激活

### 2025-10-05: 🎨 设置系统重构
- 完整设置系统实现 (mobile/build/web/index.html)
  - 番茄钟时长设置 (工作/短休息/长休息/间隔)
  - 通知设置 (声音提醒/桌面通知/音量控制)
  - 主题系统 (5种颜色 + 自动换色)

### 2025-10-05: 🔗 任务-番茄钟集成增强
- 当前任务卡片显示和实时进度追踪
- 任务选择/切换界面
- 番茄钟完成指示器和统计
- 自由番茄钟模式 (无任务关联)

### 2025-10-05: 🔧 Backend服务层开发
- 创建JWT认证服务 (backend/internal/services/auth.go)
- 实现任务管理服务 (backend/internal/services/task.go)
- 添加中间件系统 (CORS, Auth, Rate Limit, Error)
- 完成数据模型定义 (10+ model files)

### 2025-10-04: ⚙️ 核心功能实现
- 全功能设置系统 (settings.dart)
- 计时器实时更新和状态持久化
- 5种主题颜色支持

### 2025-10-03: 🏗️ 项目初始化
- 完成项目初始架构设置
- Docker Compose配置 (PostgreSQL + Redis)
- Flutter + Go项目结构搭建

## 🔑 Key Implementation Files

### Frontend (Flutter)
- `mobile/lib/main.dart` (1927行) - 完整Flutter应用
- `mobile/lib/settings.dart` - 设置系统
- `mobile/lib/services/task_service.dart` - 任务管理服务
- `mobile/lib/services/session_service.dart` - 会话管理服务
- `mobile/lib/services/notification_service.dart` - 通知服务
- `mobile/lib/services/sync_service.dart` - 同步服务

### Frontend (Web)
- `mobile/build/web/index.html` (2072行) - 独立Web应用

### Backend (Go)
- `backend/main.go` - API入口 (mock endpoints)
- `backend/internal/models/` - 数据模型 (10+ files)
- `backend/internal/services/` - 业务逻辑 (9 files)
- `backend/internal/handlers/` - HTTP处理器 (4 files)
- `backend/internal/middleware/` - 中间件 (4 files)

### Configuration
- `docker-compose.yml` - Docker服务配置
- `.env` - 环境变量配置

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
