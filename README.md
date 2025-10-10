# 🍅 Pomodoro Genie

一个功能完整的番茄工作法应用，支持项目管理和任务跟踪。

## ✨ 功能特点

### 🎯 核心功能
- ✅ **项目管理**: 创建、编辑、删除项目，组织任务
- ✅ **任务管理**: 添加、编辑、删除、拖拽排序任务
- ✅ **番茄钟计时**: 自定义工作时间、短休息、长休息
- ✅ **自动切换**: 智能的工作-休息循环
- ✅ **设置页面**: 完整的番茄钟配置选项
- ✅ **数据持久化**: 所有数据本地保存

### 🎨 用户体验
- 📱 响应式设计，支持桌面和移动端
- 🎨 清晰的视觉层次和直观的交互
- 📊 实时数据统计和进度追踪
- 🔔 任务完成提醒
- 🎯 Focus Todo 风格的任务管理界面
- 📈 美观的统计页面和设置页面
- 🔧 番茄钟状态指示器（工作/短休息/长休息）
- 🎛️ 智能的Mini-Player和全屏番茄钟切换

## 🚀 快速开始

### 方法一: 一键启动（推荐）
```bash
./start-all.sh
```

### 方法二: 分别启动

#### 启动前端
```bash
cd mobile
flutter pub get
flutter run -d web-server --web-port 3001
```

#### 启动后端（可选）
```bash
cd backend
go run cmd/main.go
```

## 🌐 访问应用

- **前端应用**: http://localhost:3001
- **后端API**: http://localhost:8081 (可选)

## 🏗️ 技术栈

### 前端
- **Flutter Web** - 跨平台UI框架
- **Riverpod** - 状态管理
- **SharedPreferences** - 本地数据存储

### 后端（可选）
- **Go 1.21+** - 高性能后端语言
- **Gin** - Web框架
- **PostgreSQL** - 关系型数据库

## 📁 项目结构

```
pomodoro-genie/
├── mobile/                  # Flutter前端应用
│   ├── lib/
│   │   └── main.dart       # 主应用文件（所有功能集成）
│   └── pubspec.yaml        # Flutter依赖配置
│
├── backend/                 # Go后端服务（可选）
│   ├── cmd/
│   │   └── main.go        # 后端入口
│   ├── internal/          # 内部包
│   │   ├── models/        # 数据模型
│   │   ├── handlers/      # HTTP处理器
│   │   ├── services/      # 业务逻辑
│   │   ├── repositories/  # 数据访问层
│   │   ├── middleware/    # 中间件
│   │   └── validators/    # 数据验证
│   ├── migrations/        # 数据库迁移
│   └── docs/             # API文档 (Swagger)
│
├── start-all.sh            # 一键启动脚本
└── README.md               # 项目文档
```

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
│ 📁 项目    [+]  │  📋 工作项目                  │
│ 📥 收件箱 (2/5) │  ☐ 完成项目文档 (2/5) 🍅      │
│ 📋 工作项目(1/3)│  ☐ 代码审查 (1/3) 🍅         │
│ 📚 学习项目(0/2)│  ☐ 团队会议 (0/2) 🍅         │
│ 📊 统计          │                             │
│ ⚙️ 设置          │                             │
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

项目采用三层架构设计，核心数据模型之间的关系如下：

```
Project (项目)
    ↓ 1:N (一对多)
Task (任务)
    ↓ 1:N (一对多)
PomodoroSession (番茄钟会话)
```

#### 1. Project → Task (一对多)
- 每个任务必须属于一个项目 (`Task.projectId`)
- 一个项目可以包含多个任务
- 删除项目时，任务自动移动到 "Inbox" 项目
- 默认项目 "Inbox" 不可删除

```dart
class Task {
  final String projectId;  // 外键：关联到 Project
  // ...
}
```

#### 2. Task → PomodoroSession (一对多)
- **工作番茄钟**：必须关联到具体任务 (`taskId` 必填)
- **休息番茄钟**：不关联任务 (`taskId` 可为 null)
- 完成工作番茄钟后自动增加任务的 `completedPomodoros` 计数

```dart
class PomodoroSession {
  final String? taskId;     // 外键：关联到 Task (可选)
  final TimerType type;     // work, shortBreak, longBreak
  // ...
}

class Task {
  final int plannedPomodoros;    // 计划的番茄钟数量
  final int completedPomodoros;  // 已完成的番茄钟数量
  // ...
}
```

#### 3. 进度追踪
任务进度通过番茄钟计数实时追踪：
- 显示格式：`🍅 2/5` (已完成/计划数量)
- 进度条：`completedPomodoros / plannedPomodoros * 100%`

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

#### 后端架构 (可选)
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

### 数据模型定义

#### Project (项目)
```dart
class Project {
  final String id;           // 唯一标识符
  final String name;         // 项目名称
  final String icon;         // 项目图标 (emoji)
  final String color;        // 项目颜色
  final DateTime createdAt;  // 创建时间
}
```

#### Task (任务)
```dart
class Task {
  final String id;                // 唯一标识符
  final String title;             // 任务标题
  final String description;       // 任务描述
  final bool isCompleted;         // 完成状态
  final TaskPriority priority;    // 优先级
  final String projectId;         // 所属项目ID (外键)
  final int plannedPomodoros;     // 计划番茄钟数量
  final int completedPomodoros;   // 已完成番茄钟数量
  final DateTime? dueDate;        // 截止日期
}
```

#### PomodoroSession (番茄钟会话)
```dart
class PomodoroSession {
  final String id;              // 唯一标识符
  final String? taskId;         // 关联任务ID (外键，可选)
  final TimerType type;         // 计时类型 (work/shortBreak/longBreak)
  final int duration;           // 计时时长 (秒)
  final DateTime startTime;     // 开始时间
  final DateTime? endTime;      // 结束时间
  final SessionStatus status;   // 会话状态
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

## 💡 使用说明

### 基础操作
1. **创建项目**: 点击侧边栏项目标题右侧的 ➕ 按钮
2. **选择项目**: 点击侧边栏中的项目名称，自动显示该项目的任务
3. **添加任务**: 点击右上角的 ➕ 按钮（仅在任务页面显示）
4. **编辑任务**: 点击任务卡片右上角的 ⋮ 菜单按钮
5. **拖拽排序**: 长按项目或任务卡片拖拽到新位置
6. **开始番茄钟**: 点击任务卡片上的 ▶️ 播放按钮
7. **查看统计**: 点击侧边栏的 📊 统计按钮
8. **配置设置**: 点击侧边栏的 ⚙️ 设置按钮

### 界面导航
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

## 🔧 开发指南

### 环境要求
- Flutter 3.0+
- Dart 3.0+
- Go 1.21+ (如果使用后端)

### 开发命令
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

# Go后端开发
cd backend
go mod download              # 下载依赖
go run cmd/main.go          # 运行开发服务器
go build -o app cmd/main.go # 构建可执行文件
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

## 📖 相关文档

- **[项目整理总结](PROJECT_CLEANUP_SUMMARY.md)** - 项目简化过程说明
- **[后端集成指南](backend/INTEGRATION_GUIDE.md)** - 后端服务集成文档

## 🤝 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📝 开发理念

这是一个**简化优先**的项目：
- 🎯 **专注核心**: 只保留必要功能
- 📦 **精简架构**: 避免过度设计
- 🚀 **快速启动**: 最小化配置
- 📖 **易于理解**: 代码即文档
- 🎨 **现代界面**: 参考优秀应用的设计模式
- 🔄 **用户友好**: 直观的交互和操作流程

## 📄 许可证

MIT License

## 📋 更新日志

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

**开始你的高效工作之旅！** 🚀

> 💡 提示: 这是一个精简版项目，所有核心功能都集中在 `mobile/lib/main.dart` 文件中，便于理解和维护。
