# 🍅 Pomodoro Genie - 完整文档

一个功能完整的番茄工作法应用，支持项目管理和任务跟踪。

## 📋 目录

- [项目概述](#项目概述)
- [功能特点](#功能特点)
- [快速开始](#快速开始)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [核心设计](#核心设计)
- [使用说明](#使用说明)
- [开发指南](#开发指南)
- [升级记录](#升级记录)
- [项目特点](#项目特点)

---

## 📋 项目概述

Pomodoro Genie 是一个现代化的番茄工作法应用，采用 Focus Todo 风格的任务管理界面，专注于提升工作效率和任务管理体验。

### 🎯 核心理念

- **简化优先**: 专注核心功能，避免过度设计
- **用户友好**: 直观的交互和操作流程
- **现代界面**: 参考优秀应用的设计模式
- **高效工作**: 智能的任务管理和时间追踪

---

## ✨ 功能特点

### 🎯 核心功能

#### 📅 任务管理
- ✅ **项目管理**: 创建、编辑、删除项目，组织任务
- ✅ **任务管理**: 添加、编辑、删除、拖拽排序任务
- ✅ **截止日期管理**: 任务截止日期显示和智能提醒
- ✅ **Today视图**: 今日任务聚焦，智能筛选相关任务
- ✅ **已完成任务管理**: 折叠/展开已完成任务，分页加载历史任务
- ✅ **拖拽排序**: 项目和任务都支持拖拽重新排序

#### 🍅 番茄钟功能
- ✅ **番茄钟计时**: 自定义工作时间、短休息、长休息
- ✅ **自动切换**: 智能的工作-休息循环
- ✅ **状态指示**: 清晰的工作/短休息/长休息状态标识
- ✅ **Mini-Player**: 紧凑的计时器界面
- ✅ **全屏模式**: 专注的全屏番茄钟体验

#### 📊 数据管理
- ✅ **数据持久化**: 所有数据本地保存
- ✅ **实时统计**: 项目进度和效率分析
- ✅ **设置页面**: 完整的番茄钟配置选项
- ✅ **任务完成提醒**: 智能的通知系统

### 🎨 用户体验

#### 界面设计
- 📱 **响应式设计**: 支持桌面和移动端
- 🎨 **现代化界面**: Focus Todo 风格的任务管理界面
- 📊 **实时数据统计**: 动态计算和显示统计数据
- 🔔 **智能提醒**: 任务完成和截止日期提醒
- 🎯 **直观交互**: 简化的操作流程，减少点击次数

#### 视觉优化
- 📈 **美观的统计页面**: 卡片式布局展示关键指标
- ⚙️ **设置页面**: 分组设置，直观的+/-按钮调整
- 🔧 **状态指示器**: 工作/短休息/长休息状态标识
- 🎛️ **智能切换**: Mini-Player和全屏番茄钟智能切换
- 📅 **智能标签**: 截止日期颜色编码紧急程度
- 👁️ **折叠功能**: 已完成任务折叠，保持界面整洁
- 📄 **分页加载**: 历史任务分页加载，提升性能

---

## 🚀 快速开始

### 方法一: 一键启动（推荐）
```bash
./start.sh
```

### 方法二: 分别启动

#### 启动前端
```bash
cd mobile
flutter pub get
flutter run -d web-server --web-port 3001
```

#### 启动后端
```bash
cd backend
go mod tidy
go run cmd/main.go
```

### 🌐 访问应用

- **前端应用**: http://localhost:3001
- **后端API**: http://localhost:8081
- **健康检查**: http://localhost:8081/health
- **API文档**: http://localhost:8081/docs

---

## 🏗️ 技术栈

### 前端
- **Flutter Web** - 跨平台UI框架
- **Riverpod** - 状态管理
- **SharedPreferences** - 本地数据存储

### 后端（简化版）
- **Go 1.21+** - 高性能后端语言
- **Gin** - Web框架
- **GORM** - ORM框架
- **PostgreSQL** - 单一数据库
- **JWT** - 身份认证

---

## 📁 项目结构

```
pomodoro-genie/
├── mobile/                  # Flutter前端应用
│   ├── lib/
│   │   └── main.dart       # 主应用文件（所有功能集成）
│   └── pubspec.yaml        # Flutter依赖配置
│
├── backend/                 # Go后端服务（简化版）
│   ├── cmd/
│   │   └── main.go        # 统一入口文件
│   ├── internal/          # 内部包
│   │   ├── config/        # 配置管理
│   │   ├── models/        # 数据模型（简化版）
│   │   ├── handlers/      # HTTP处理器
│   │   ├── services/      # 业务逻辑
│   │   ├── repositories/  # 数据访问层
│   │   └── middleware/    # 中间件
│   ├── migrations/        # 数据库迁移（单一脚本）
│   ├── go.mod             # Go模块文件
│   └── README.md          # 后端文档
│
├── start.sh                # 统一启动脚本
└── README.md               # 项目主文档
```

---

## 🔗 核心设计

### 界面设计

#### Focus Todo 风格的任务管理
应用采用现代化的任务管理界面设计，参考了 Focus Todo 的交互模式：

**主要特点**：
- 🎯 **任务优先**: 任务管理作为主界面，番茄钟作为辅助工具
- 📱 **侧边栏导航**: 项目列表和导航功能集成在侧边栏
- 🔄 **拖拽排序**: 项目和任务都支持拖拽重新排序
- ⚡ **快速操作**: 简化的操作流程，减少点击次数

**界面布局**：
```
┌─────────────────────────────────────────────────┐
│ 🍅 Pomodoro Genie                    [+] [📁] │
├─────────────────────────────────────────────────┤
│ 📅 Today                    │  📋 工作项目      │
│ ─────────────────────────── │  ☐ 完成项目文档  │
│ 📁 项目    [+]              │  ☐ 代码审查      │
│ 📥 收件箱 (2/5)             │  ☐ 团队会议      │
│ 📋 工作项目(1/3)            │                  │
│ 📚 学习项目(0/2)            │                  │
│ 📊 统计                     │                  │
│ ⚙️ 设置                     │                  │
└─────────────────────────────────────────────────┘
```

**Today视图布局**：
```
┌─────────────────────────────────────────────────┐
│ 🍅 Pomodoro Genie                    [+] [📁] │
├─────────────────────────────────────────────────┤
│ 📅 Today                    │  📅 今日任务      │
│ ─────────────────────────── │  ☐ 完成项目文档  │
│ 📁 项目    [+]              │  ☐ 代码审查      │
│ 📥 收件箱 (2/5)             │  ☐ 团队会议      │
│ 📋 工作项目(1/3)            │                  │
│ 📚 学习项目(0/2)            │                  │
│ 📊 统计                     │                  │
│ ⚙️ 设置                     │                  │
└─────────────────────────────────────────────────┘
```

#### 统计页面设计
- 📊 **卡片式布局**: 6个统计卡片展示关键指标
- 🎨 **渐变背景**: 优雅的视觉设计
- 📈 **实时数据**: 动态计算和显示统计数据
- 🔢 **紧凑布局**: 优化的卡片尺寸和间距

#### 设置页面设计
- ⚙️ **分组设置**: 番茄钟时间配置和应用信息分组
- ➕➖ **直观调整**: 使用+/-按钮调整时间设置
- 🔄 **实时生效**: 设置更改立即应用到计时器
- 📱 **响应式**: 适配不同屏幕尺寸

### 数据模型关系

项目采用简化的三层架构设计，核心数据模型之间的关系如下：

```
User (用户)
    ↓ 1:N (一对多)
Project (项目)
    ↓ 1:N (一对多)
Task (任务)
    ↓ 1:N (一对多)
PomodoroSession (番茄钟会话)
```

#### 核心关系
- **User → Project**: 每个用户可以有多个项目
- **Project → Task**: 每个任务必须属于一个项目
- **Task → PomodoroSession**: 工作番茄钟关联任务，休息番茄钟不关联
- **默认项目**: 每个用户自动创建"Inbox"项目，不可删除

#### 进度追踪
- 任务进度：`completedPomodoros / plannedPomodoros * 100%`
- 项目统计：实时计算完成率、总时间等
- 用户隔离：每个用户只能访问自己的数据

### 架构设计

#### 前端架构 (Flutter + Riverpod)
```
用户交互 → UI 组件 → Riverpod Provider → DataService → SharedPreferences
```

**核心状态管理**：
- `ProjectNotifier` - 项目管理
- `TaskNotifier` - 任务管理  
- `TimerNotifier` - 计时器管理
- `SessionNotifier` - 会话历史

#### 后端架构 (简化版)
```
Flutter App → REST API → Handlers → Services → Repositories → PostgreSQL
              ↑
          JWT 认证 + 中间件
```

**分层设计**：
- **Handlers** - HTTP 处理层
- **Services** - 业务逻辑层
- **Repositories** - 数据访问层
- **Models** - 数据模型层

#### 简化优势
- **单一数据库**: 只使用PostgreSQL，无需外部服务
- **统一配置**: 简化的环境变量配置
- **快速启动**: 优化的启动流程
- **易于维护**: 清晰的代码结构

### 数据模型定义

#### User (用户)
```go
type User struct {
    ID           uuid.UUID `gorm:"type:uuid;primary_key"`
    Email        string    `gorm:"uniqueIndex;not null"`
    PasswordHash string    `gorm:"not null"`
    Name         string    `gorm:"not null"`
    CreatedAt    time.Time
    UpdatedAt    time.Time
}
```

#### Project (项目)
```go
type Project struct {
    ID        uuid.UUID `gorm:"type:uuid;primary_key"`
    UserID    uuid.UUID `gorm:"type:uuid;not null;index"`
    Name      string    `gorm:"not null"`
    Icon      string    `gorm:"default:'📁'"`
    Color     string    `gorm:"default:'#2563eb'"`
    CreatedAt time.Time
    UpdatedAt time.Time
}
```

#### Task (任务)
```go
type Task struct {
    ID                 uuid.UUID  `gorm:"type:uuid;primary_key"`
    ProjectID          uuid.UUID  `gorm:"type:uuid;not null;index"`
    Title              string     `gorm:"not null"`
    Description        string
    Priority           string     `gorm:"default:'medium'"`
    IsCompleted        bool       `gorm:"default:false;index"`
    PlannedPomodoros   int        `gorm:"default:1"`
    CompletedPomodoros int        `gorm:"default:0"`
    DueDate            *time.Time `gorm:"index"`
    CreatedAt          time.Time
    UpdatedAt          time.Time
}
```

#### PomodoroSession (番茄钟会话)
```go
type PomodoroSession struct {
    ID        uuid.UUID  `gorm:"type:uuid;primary_key"`
    UserID    uuid.UUID  `gorm:"type:uuid;not null;index"`
    TaskID    *uuid.UUID `gorm:"type:uuid;index"`
    Type      string     `gorm:"not null"` // work, short_break, long_break
    Duration  int        `gorm:"not null"` // in seconds
    StartTime time.Time  `gorm:"default:now();index"`
    EndTime   *time.Time
    Status    string     `gorm:"default:'completed'"`
}
```

### 关系约束规则

**强制约束**：
- ✅ 每个 Task 必须属于一个 Project
- ✅ 工作类型的 PomodoroSession 必须关联 Task
- ✅ Project "Inbox" 不能被删除

**级联规则**：
- 🔄 删除 Project → 任务移动到 Inbox (软级联)
- 🔄 删除 Task → PomodoroSession 的 `task_id` 设为 NULL (保留历史)

---

## 💡 使用说明

### 基础操作

#### 📅 Today视图
1. 点击侧边栏顶部的 📅 Today 按钮查看今日任务
2. 查看所有今日相关的未完成任务
3. 任务卡片显示所属项目信息
4. 无法在Today视图中添加新任务（需要在具体项目中添加）

#### 📁 项目管理
1. **创建项目**: 点击侧边栏项目标题右侧的 ➕ 按钮
2. **选择项目**: 点击侧边栏中的项目名称，自动显示该项目的任务
3. **编辑项目**: 点击项目卡片右上角的 ⋮ 菜单按钮
4. **拖拽排序**: 长按项目卡片拖拽到新位置

#### 📋 任务管理
1. **添加任务**: 点击右上角的 ➕ 按钮（仅在任务页面显示）
2. **设置截止日期**: 创建/编辑任务时选择截止日期，任务卡片会显示智能标签
3. **编辑任务**: 点击任务卡片右上角的 ⋮ 菜单按钮
4. **拖拽排序**: 长按任务卡片拖拽到新位置
5. **开始番茄钟**: 点击任务卡片上的 ▶️ 播放按钮

#### 👁️ 已完成任务管理
1. **切换显示**: 点击眼睛图标切换已完成任务显示/隐藏
2. **查看历史**: 使用"加载更多"按钮查看更多历史任务
3. **视觉识别**: 已完成任务使用删除线样式，便于识别

#### 🍅 番茄钟使用
1. **开始计时**: 点击任务卡片上的 ▶️ 播放按钮
2. **暂停/继续**: 在计时器界面使用暂停/继续按钮
3. **跳过**: 可以跳过当前阶段
4. **全屏模式**: 点击最大化按钮进入全屏专注模式

### 界面导航

- **Today视图**: 点击侧边栏顶部的Today按钮，显示今日相关任务
- **任务页面**: 点击项目名称自动切换到任务页面
- **统计页面**: 显示项目进度和效率分析
- **设置页面**: 配置番茄钟时间和应用信息
- **番茄钟**: 以模态对话框形式显示，不占用主界面

### 拖拽排序

- **项目排序**: 长按侧边栏中的项目卡片拖拽重新排序
- **任务排序**: 长按任务列表中的任务卡片拖拽重新排序
- **隐藏收件箱**: 收件箱项目不在侧边栏显示，保持界面简洁

### 番茄钟设置

- **工作时长**: 1-60分钟可调，默认25分钟
- **短休息**: 1-60分钟可调，默认5分钟
- **长休息**: 1-60分钟可调，默认15分钟
- **长休息间隔**: 2-10个周期可调，默认4个周期
- **实时生效**: 设置更改后立即应用到计时器

### 番茄钟状态指示

- **🔴 红色 + 💼**: 工作时间状态
- **🟢 绿色 + ☕**: 短休息状态  
- **🔵 蓝色 + 🏨**: 长休息状态
- **状态显示**: 主页面状态指示器和Mini-Player都有状态标识
- **智能切换**: Mini-Player在全屏番茄钟显示时自动隐藏

---

## 🔧 开发指南

### 环境要求

- Flutter 3.0+
- Dart 3.0+
- Go 1.21+ (后端服务)
- PostgreSQL 12+ (数据库)

### 开发命令

#### 前端开发
```bash
# Flutter开发
cd mobile
flutter pub get              # 安装依赖
flutter run -d chrome        # 在Chrome中运行
flutter build web --release  # 构建生产版本

# macOS应用构建
cd mobile
flutter config --enable-macos-desktop  # 启用macOS支持（首次）
flutter create --platforms=macos .     # 创建macOS平台文件（首次）
flutter build macos --release          # 构建macOS应用
```

#### 后端开发
```bash
# 使用统一启动脚本（推荐）
./start.sh

# 或手动启动
cd backend
go mod tidy                 # 下载依赖
go run cmd/main.go         # 运行开发服务器
go build -o app cmd/main.go # 构建可执行文件
```

#### 数据库设置
```bash
# 创建数据库
createdb pomodoro_genie

# 运行初始化脚本
psql -d pomodoro_genie -f backend/migrations/001_init_simplified.sql
```

### macOS DMG 安装包构建

#### 1. 安装依赖工具
```bash
# 安装 CocoaPods（macOS构建必需）
brew install cocoapods

# 安装 create-dmg（创建DMG安装包）
brew install create-dmg
```

#### 2. 构建应用
```bash
cd mobile

# 清理之前的构建
flutter clean

# 构建 macOS Release 版本
flutter build macos --release
```

#### 3. 创建 DMG 安装包
```bash
# 创建输出目录
mkdir -p build/macos/dmg

# 生成 DMG 文件
create-dmg \
  --volname "Pomodoro Genie" \
  --volicon "build/macos/Build/Products/Release/pomodoro_genie.app/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "pomodoro_genie.app" 175 120 \
  --hide-extension "pomodoro_genie.app" \
  --app-drop-link 425 120 \
  "build/macos/dmg/PomodoroGenie-1.0.0.dmg" \
  "build/macos/Build/Products/Release/pomodoro_genie.app"
```

#### 4. 构建结果
- **应用程序**: `build/macos/Build/Products/Release/pomodoro_genie.app`
- **DMG安装包**: `build/macos/dmg/PomodoroGenie-1.0.0.dmg`

#### 5. 使用说明
```bash
# 直接运行应用
open build/macos/Build/Products/Release/pomodoro_genie.app

# 打开DMG安装包
open build/macos/dmg/PomodoroGenie-1.0.0.dmg

# 在Finder中查看
open build/macos/dmg/
```

#### 6. 代码签名（可选，用于正式分发）
```bash
# 签名应用（需要 Apple Developer 账号）
codesign --force --deep --sign "Developer ID Application: Your Name" \
  build/macos/Build/Products/Release/pomodoro_genie.app

# 验证签名
codesign --verify --verbose build/macos/Build/Products/Release/pomodoro_genie.app

# 公证应用（需要 Apple Developer 账号）
xcrun notarytool submit build/macos/dmg/PomodoroGenie-1.0.0.dmg \
  --apple-id your-email@example.com \
  --team-id YOUR_TEAM_ID \
  --wait
```

### 代码格式化
```bash
# Flutter
cd mobile && flutter format lib/

# Go
cd backend && go fmt ./...
```

---

## 📊 升级记录

### v2.2.0 - 任务管理增强版本 (2024年12月)

#### ✨ 新增功能

##### 1. 📅 任务截止日期显示
**功能描述**: 任务卡片现在会显示截止日期信息
**实现细节**:
- 在任务卡片中添加了截止日期标签
- 根据截止日期的紧急程度使用不同颜色：
  - 🔴 红色：已过期
  - 🟠 橙色：今天到期
  - 🟡 黄色：3天内到期
  - 🟢 绿色：还有时间
- 智能日期格式化：
  - 已过期：显示"已过期"
  - 今天：显示"今天"
  - 明天：显示"明天"
  - 7天内：显示"X天后"
  - 更远：显示"月/日"格式

##### 2. 👁️ 已完成任务折叠功能
**功能描述**: 每个项目都有一个按钮来折叠/展开已完成的任务
**实现细节**:
- 在顶部工具栏添加了眼睛图标按钮
- 点击可以切换已完成任务的显示/隐藏
- 已完成任务使用不同的视觉样式：
  - 半透明背景
  - 删除线文本
  - 绿色番茄钟标签
- 添加了"已完成任务"标题区域

##### 3. 📄 分页加载历史任务
**功能描述**: 点击"加载更多"按钮时递增展示10条历史任务
**实现细节**:
- 默认只显示前10个已完成任务
- 添加"加载更多"按钮，显示剩余任务数量
- 每次点击加载10个任务
- 按钮样式与主题保持一致

##### 4. 📅 Today 视图
**功能描述**: 在项目按钮上方添加Today按钮，显示到今天还需要执行的任务
**实现细节**:
- 在侧边栏顶部添加Today按钮
- 智能筛选逻辑：
  - 只显示未完成的任务
  - 只显示有截止日期的任务
  - 显示今天及前后一天的任务
- Today视图特殊处理：
  - 隐藏已完成任务切换按钮
  - 隐藏快速添加按钮
  - 在任务卡片中显示所属项目信息
  - 特殊的空状态提示

#### 🎨 界面优化

##### 视觉设计改进
- **截止日期标签**: 使用图标+文字的组合设计，直观易懂
- **Today按钮**: 采用与项目按钮一致的设计风格，保持界面统一
- **已完成任务**: 使用删除线和半透明效果，清晰区分状态
- **加载更多按钮**: 使用主题色彩，保持视觉一致性

##### 交互体验提升
- **智能筛选**: Today视图自动筛选相关任务，减少用户操作
- **状态保持**: 折叠/展开状态在切换项目时保持
- **分页加载**: 避免一次性加载大量任务，提升性能
- **上下文信息**: Today视图中显示项目信息，便于任务管理

#### 🔧 技术实现

##### 状态管理
- 使用 `ConsumerStatefulWidget` 管理局部状态
- 添加 `_showCompletedTasks` 控制已完成任务显示
- 添加 `_completedTasksPage` 管理分页状态
- 使用 `_pageSize` 常量控制每页任务数量

##### 数据处理
- 智能任务筛选逻辑
- 分页数据切片处理
- 项目名称查找和显示
- 截止日期计算和格式化

##### 组件复用
- 创建了 `_getDueDateColor()` 和 `_formatDueDate()` 辅助方法
- 添加了 `_getProjectName()` 方法获取项目信息
- 保持了现有组件的兼容性

#### 📱 用户体验

##### 工作流程优化
1. **日常查看**: 使用Today视图快速查看今日任务
2. **任务管理**: 通过截止日期标签了解任务紧急程度
3. **历史回顾**: 使用折叠功能管理已完成任务
4. **批量查看**: 使用分页加载查看大量历史任务

##### 界面简洁性
- Today视图专注于今日任务，界面更简洁
- 已完成任务默认隐藏，减少视觉干扰
- 分页加载避免长列表，提升浏览体验

#### 🚀 使用指南

##### Today视图使用
1. 点击侧边栏顶部的"Today"按钮
2. 查看所有今日相关的未完成任务
3. 任务卡片会显示所属项目信息
4. 无法在Today视图中添加新任务（需要在具体项目中添加）

##### 截止日期管理
1. 创建任务时选择截止日期
2. 任务卡片会自动显示截止日期标签
3. 根据颜色判断任务紧急程度
4. 编辑任务时可以修改截止日期

##### 已完成任务管理
1. 点击眼睛图标切换已完成任务显示
2. 使用"加载更多"按钮查看更多历史任务
3. 已完成任务使用删除线样式，便于识别

#### 🔮 未来扩展

##### 可能的改进方向
- **智能提醒**: 基于截止日期发送通知
- **任务排序**: 按截止日期自动排序
- **批量操作**: 支持批量标记完成
- **数据导出**: 导出任务和统计数据

##### 性能优化
- **虚拟滚动**: 处理大量任务时的性能优化
- **缓存机制**: 减少重复计算
- **懒加载**: 按需加载任务详情

#### 📊 升级效果

##### 功能完整性
- ✅ 任务截止日期管理
- ✅ 已完成任务组织
- ✅ 历史任务浏览
- ✅ 今日任务聚焦
- ✅ 侧边栏布局优化

##### 用户体验
- ✅ 界面更加直观
- ✅ 操作更加便捷
- ✅ 信息更加丰富
- ✅ 性能更加优化
- ✅ 布局更加合理

##### 界面设计改进
- ✅ Today按钮位置优化（项目标题上方）
- ✅ 分割线清晰分隔功能区域
- ✅ 侧边栏宽度扩展（200px → 250px）
- ✅ 项目名称显示更完整，避免换行

#### 🔧 技术修复
- ✅ 修复了 `ConsumerState` 的 `build` 方法签名问题
- ✅ 修复了 `onStartPomodoro` 方法调用问题
- ✅ 所有编译错误已解决
- ✅ 代码通过 linter 检查

#### 🚀 部署状态
- ✅ 应用已成功启动在 `http://localhost:3001`
- ✅ 所有新功能已集成并测试
- ✅ 保持向后兼容性

### v2.1.0 - 界面优化和功能完善版本

- 🎨 **界面重设计**: 采用 Focus Todo 风格的任务管理界面
- 📱 **侧边栏导航**: 项目列表和导航功能集成在侧边栏
- 🔄 **拖拽排序**: 项目和任务都支持拖拽重新排序
- 📊 **统计页面**: 美观的卡片式统计展示
- ⚙️ **设置页面**: 完整的番茄钟时间配置功能
- 🎯 **任务优先**: 任务管理作为主界面，番茄钟作为辅助工具
- 📈 **实时设置**: 番茄钟时间配置实时生效
- 🎨 **视觉优化**: 渐变背景、卡片阴影等现代化设计元素
- 🔧 **状态指示**: 番茄钟主页面和Mini-Player都有清晰的状态标识
- 🎛️ **Mini-Player优化**: 最大化按钮正常工作，全屏时自动隐藏
- 🛠️ **代码重构**: 创建TimerUtils工具类，修复编译错误
- 🚀 **启动优化**: 修改启动脚本，专注前端服务

### v2.0.0 - 界面优化版本

- 🎨 **界面重设计**: 采用 Focus Todo 风格的任务管理界面
- 📱 **侧边栏导航**: 项目列表和导航功能集成在侧边栏
- 🔄 **拖拽排序**: 项目和任务都支持拖拽重新排序
- 📊 **统计页面**: 美观的卡片式统计展示
- ⚙️ **设置页面**: 完整的番茄钟时间配置功能
- 🎯 **任务优先**: 任务管理作为主界面，番茄钟作为辅助工具
- 📈 **实时设置**: 番茄钟时间配置实时生效
- 🎨 **视觉优化**: 渐变背景、卡片阴影等现代化设计元素

### v1.0.0 - 基础功能版本

- ✅ 项目管理和任务管理
- ✅ 番茄钟计时功能
- ✅ 数据持久化存储
- ✅ 基础UI界面

---

## 📊 项目特点

### ✅ 简洁架构
- 核心代码集中在单个文件中
- 清晰的模块划分
- 易于理解和维护

### ✅ 完整功能
- 所有核心功能都已实现
- 生产环境可用
- 稳定可靠

### ✅ 现代化界面
- Focus Todo 风格的任务管理界面
- 美观的统计页面和设置页面
- 支持拖拽排序的直观交互
- 响应式设计，适配各种设备

### ✅ 开发友好
- 一键启动脚本
- 热重载支持
- 清晰的代码注释

---

## 🔌 后端API

### API 端点

#### 认证相关
```
POST /v1/auth/register          # 用户注册
POST /v1/auth/login             # 用户登录
POST /v1/auth/logout            # 用户登出
```

#### 项目管理
```
GET    /v1/projects             # 获取项目列表
POST   /v1/projects             # 创建项目
GET    /v1/projects/:id         # 获取项目详情
PUT    /v1/projects/:id         # 更新项目
DELETE /v1/projects/:id         # 删除项目
```

#### 任务管理
```
GET    /v1/tasks                # 获取任务列表
POST   /v1/tasks                # 创建任务
GET    /v1/tasks/:id            # 获取任务详情
PUT    /v1/tasks/:id            # 更新任务
DELETE /v1/tasks/:id            # 删除任务
```

#### 番茄钟控制
```
POST /v1/pomodoro/start         # 开始番茄钟
POST /v1/pomodoro/pause         # 暂停番茄钟
POST /v1/pomodoro/resume        # 恢复番茄钟
POST /v1/pomodoro/stop          # 停止番茄钟
GET  /v1/pomodoro/sessions      # 获取会话历史
```

#### 系统信息
```
GET /health                     # 健康检查
GET /                           # API 信息
GET /docs                       # API 文档
```

### 环境配置

```bash
# 服务器配置
PORT=8081
GIN_MODE=debug

# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=pomodoro_genie
DB_SSLMODE=disable

# 数据库连接池配置
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_MAX_LIFETIME_MINUTES=5
DB_MAX_IDLE_TIME_MINUTES=1

# 日志配置
DB_LOG_LEVEL=info
```

## 📖 相关文档

- **[后端文档](backend/README.md)** - 后端服务详细文档
- **[数据库简化方案](DATABASE_SIMPLIFICATION_PLAN.md)** - 数据库架构简化说明

---

## 🤝 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 📝 开发理念

这是一个**简化优先**的项目：
- 🎯 **专注核心**: 只保留必要功能
- 📦 **精简架构**: 避免过度设计
- 🚀 **快速启动**: 最小化配置
- 📖 **易于理解**: 代码即文档
- 🎨 **现代界面**: 参考优秀应用的设计模式
- 🔄 **用户友好**: 直观的交互和操作流程

---

## 📄 许可证

MIT License

---

**开始你的高效工作之旅！** 🚀

> 💡 提示: 这是一个精简版项目，所有核心功能都集中在 `mobile/lib/main.dart` 文件中，便于理解和维护。

---

**升级完成时间**: 2024年12月  
**版本**: v2.2.0  
**状态**: ✅ 已完成并运行  
**访问地址**: http://localhost:3001

所有功能都已成功实现，应用正在正常运行！
