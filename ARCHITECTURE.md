# 🏗️ Pomodoro Genie 完整架构说明

## 🎯 架构概览

Pomodoro Genie 采用现代化的多层架构，支持跨平台开发和实时同步。

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer (客户端层)                   │
├─────────────────┬─────────────────┬─────────────────┬───────────┤
│  📱 Mobile App  │  🌐 Web App     │  🖥️ Desktop App │  📊 Admin │
│   (Flutter)     │   (Flutter)     │    (Tauri)      │ (pgAdmin) │
│                 │                 │                 │           │
│ • iOS/Android   │ • PWA Support   │ • Windows       │ • DB Mgmt │
│ • Offline Mode  │ • Service Worker│ • macOS/Linux   │ • Monitoring│
│ • Push Notify   │ • Web Push      │ • System Tray   │ • Reports │
└─────────────────┴─────────────────┴─────────────────┴───────────┘
                                 │
                          ┌──────┴──────┐
                          │  🌐 Network  │
                          │   Gateway    │
                          │   (Nginx)    │
                          └──────┬──────┘
                                 │
┌─────────────────────────────────────────────────────────────────┐
│                      Backend Layer (后端层)                     │
├─────────────────┬─────────────────┬─────────────────┬───────────┤
│  🔌 API Gateway │  🚀 REST API    │  ⚡ Real-time   │  🔄 Sync  │
│    (Nginx)      │     (Go/Gin)    │   (PostgREST)   │ (Go Svc)  │
│                 │                 │                 │           │
│ • Rate Limiting │ • JWT Auth      │ • WebSocket     │ • Conflict│
│ • CORS Config   │ • Validation    │ • Subscriptions │   Resolution│
│ • Load Balance  │ • Business Logic│ • Live Updates  │ • Queue   │
└─────────────────┴─────────────────┴─────────────────┴───────────┘
                                 │
┌─────────────────────────────────────────────────────────────────┐
│                     Storage Layer (存储层)                      │
├─────────────────┬─────────────────┬─────────────────┬───────────┤
│  🗄️ Database    │  🚀 Cache       │  📁 Files       │  🔔 Queue │
│  (PostgreSQL)   │   (Redis)       │   (Local)       │  (Redis)  │
│                 │                 │                 │           │
│ • User Data     │ • Session Store │ • Uploads       │ • Jobs    │
│ • Tasks/Sessions│ • Rate Limits   │ • Static Assets │ • Notifications│
│ • Analytics     │ • Temp Data     │ • Logs          │ • Sync    │
└─────────────────┴─────────────────┴─────────────────┴───────────┘
```

## 🎨 技术栈详解

### 前端应用 (Frontend Applications)

#### 📱 移动应用 (Flutter)
**框架**: Flutter 3.16+ with Dart 3.5+
**状态管理**: Riverpod
**本地存储**: Hive + SQLite
**特性**:
- 跨平台 (iOS/Android/Web)
- 离线优先架构
- 后台计时器执行
- 推送通知集成
- 自动同步队列

**关键文件**:
```
mobile/
├── lib/
│   ├── main.dart          # 应用入口和核心状态管理
│   ├── settings.dart      # 全面设置系统
│   ├── providers/         # Riverpod状态管理（规划中）
│   ├── screens/          # UI界面组件
│   ├── services/         # 业务逻辑服务
│   └── utils/            # 工具类和验证
├── web/
│   ├── index.html        # Web入口（已优化）
│   └── flutter_bootstrap.js  # 现代化启动脚本
├── test/
│   ├── widget/           # Widget测试
│   ├── e2e/             # 端到端测试
│   └── timer/           # 计时器精度测试
└── pubspec.yaml         # 依赖配置
```

**当前实现状态**:
- ✅ **实时计时器**: Timer.periodic精确倒计时
- ✅ **状态管理**: PomodoroState单例模式
- ✅ **设置系统**: AppSettings全功能配置
- ✅ **主题支持**: 5种颜色主题动态切换
- ✅ **状态持久化**: IndexedStack页面状态保持
- ✅ **Web优化**: flutter_bootstrap.js现代化启动

#### 🖥️ 桌面应用 (Tauri)
**框架**: Tauri 2.0 with Rust 1.75+
**前端**: Flutter Web (共享代码)
**特性**:
- 原生性能 (内存占用 <50MB)
- 系统托盘集成
- 原生通知
- 自动启动配置
- 跨平台 (Windows/macOS/Linux)

**关键文件**:
```
desktop/
└── src-tauri/
    ├── src/
    │   ├── main.rs           # 主应用入口
    │   ├── tray.rs           # 系统托盘
    │   ├── notifications.rs  # 原生通知
    │   └── storage.rs        # 本地存储
    └── Cargo.toml           # Rust依赖
```

### 后端服务 (Backend Services)

#### 🚀 主要API服务 (Go + Gin)
**框架**: Go 1.21+ with Gin
**架构**: 分层架构 (Handler -> Service -> Model)
**特性**:
- JWT身份验证
- 请求验证和中间件
- 实时同步服务
- 推送通知服务
- 报告生成

**目录结构**:
```
backend/
├── internal/
│   ├── handlers/          # HTTP处理器
│   ├── services/          # 业务逻辑
│   ├── models/           # 数据模型
│   ├── middleware/       # 中间件
│   └── validators/       # 验证器
├── migrations/           # 数据库迁移
└── tests/               # 测试套件
```

#### ⚡ 实时API (PostgREST)
**功能**: 自动生成REST API
**特性**:
- 基于PostgreSQL schema自动生成API
- 支持复杂查询和过滤
- JWT认证集成
- 实时订阅支持

#### 🔄 同步服务
**策略**: Last-Write-Wins (最后写入获胜)
**特性**:
- 冲突检测和解决
- 离线队列管理
- 增量同步
- 跨设备状态同步

### 数据存储 (Data Storage)

#### 🗄️ 主数据库 (PostgreSQL 15)
**配置**: 通过华为云镜像 (`swr.cn-north-4.myhuaweicloud.com`)
**特性**:
- 关系型数据存储
- ACID事务支持
- 行级安全 (RLS)
- 触发器和存储过程
- 全文搜索支持

**数据模型**:
```sql
-- 核心实体
users              # 用户表
tasks              # 任务表
subtasks           # 子任务表
pomodoro_sessions  # 番茄钟会话表
notes              # 笔记表
reminders          # 提醒表
recurrence_rules   # 重复规则表
reports            # 报告表
```

#### 🚀 缓存层 (Redis 7)
**用途**:
- 会话存储
- 频率限制
- 临时数据缓存
- 后台任务队列
- 实时同步状态

#### 📁 文件存储
**策略**: 本地文件系统 + Nginx静态服务
**用途**:
- 用户头像
- 任务附件
- 导出文件
- 日志文件

## 🔐 安全架构

### 身份验证流程
```
1. 用户登录 → JWT Token生成
2. Token存储 → 安全本地存储
3. API请求 → Bearer Token验证
4. Token刷新 → 自动续期机制
5. 登出 → Token失效处理
```

### 数据安全
- **传输加密**: HTTPS/WSS
- **存储加密**: 敏感数据AES加密
- **访问控制**: 行级安全策略
- **输入验证**: 多层验证机制
- **SQL注入防护**: 参数化查询

## ⚡ 性能优化

### 响应时间目标
- **API响应**: <150ms (95th percentile)
- **UI交互**: <100ms
- **计时器精度**: ±1秒
- **同步延迟**: <5秒

### 优化策略
1. **数据库**:
   - 索引优化
   - 连接池管理
   - 查询优化

2. **缓存**:
   - Redis缓存热点数据
   - 客户端缓存
   - CDN静态资源

3. **前端**:
   - 懒加载
   - 虚拟滚动
   - 状态管理优化

## 🔄 同步架构

### 同步策略
```
1. 增量同步 → 只同步变更数据
2. 冲突解决 → 时间戳比较
3. 离线队列 → 本地操作队列
4. 网络恢复 → 自动重试机制
5. 状态协调 → 跨设备状态一致性
```

### 同步流程
```
[设备A] 数据变更 → 本地存储 → 同步队列
                              ↓
[服务器] 接收变更 → 验证数据 → 数据库更新 → 推送通知
                              ↓
[设备B] 接收推送 → 获取变更 → 本地更新 → UI刷新
```

## 🧪 测试策略

### 测试金字塔
```
E2E Tests (端到端测试)
├── Maestro自动化测试
├── 跨平台兼容性测试
└── 用户场景测试

Integration Tests (集成测试)
├── API集成测试
├── 数据库集成测试
└── 同步功能测试

Unit Tests (单元测试)
├── Go服务单元测试 (testify)
├── Flutter Widget测试
└── Dart逻辑测试
```

### 性能测试
- **API性能测试**: 并发负载测试
- **计时器精度测试**: 长时间运行测试
- **内存使用测试**: 内存泄漏检测
- **同步性能测试**: 大数据量同步测试

## 📊 监控和分析

### 应用监控
- **性能指标**: 响应时间、吞吐量
- **错误跟踪**: 异常日志和错误率
- **用户行为**: 使用模式分析
- **系统健康**: 服务状态监控

### 业务分析
- **用户留存**: DAU/MAU分析
- **功能使用**: 特性使用统计
- **性能数据**: 番茄钟完成率
- **错误报告**: 崩溃和错误分析

## 🚀 部署架构

## ⚙️ 设置系统架构

### 设置数据模型
```dart
class AppSettings {
  // 时间配置
  int workDuration = 25;      // 工作时长（分钟）
  int shortBreak = 5;         // 短休息（分钟）
  int longBreak = 15;         // 长休息（分钟）
  int longBreakInterval = 4;  // 长休息间隔

  // 自动化设置
  bool autoStartBreaks = false;     // 自动开始休息
  bool autoStartPomodoros = false;  // 自动开始番茄钟

  // 通知设置
  bool soundEnabled = true;         // 提醒声音
  bool notificationsEnabled = true; // 推送通知

  // 外观设置
  String theme = 'red';            // 主题颜色
}
```

### 设置界面架构
```
SettingsScreen (设置主界面)
├── 番茄钟设置
│   ├── DurationPicker (时长选择器)
│   │   └── ListWheelScrollView (滚轮选择)
│   └── NumberPicker (数字选择器)
├── 自动化设置
│   └── SwitchListTile (开关组件)
├── 通知与声音
│   └── SwitchListTile (开关组件)
├── 外观设置
│   └── ThemePicker (主题选择器)
│       └── ColorTheme (颜色主题卡片)
└── 关于与帮助
    ├── AboutDialog (关于对话框)
    ├── UserGuide (用户指南)
    └── FeedbackDialog (反馈对话框)
```

### 状态同步机制
```dart
// 设置变更流程
AppSettings.saveSettings()
    → _notifyListeners()
    → PomodoroState.updateFromSettings()
    → UI重新渲染

// 监听器模式
SettingsScreen → AppSettings.addListener()
TimerScreen → AppSettings.addListener()
```

### 主题系统架构
```dart
// 主题枚举
enum ThemeColors {
  red: Colors.red,         // 番茄红（默认）
  blue: Colors.blue,       // 天空蓝
  green: Colors.green,     // 森林绿
  purple: Colors.purple,   // 薰衣草紫
  orange: Colors.orange    // 活力橙
}

// 主题应用
AppBar.backgroundColor → _settings.themeColor.shade400
Button.color → _settings.themeColor
Icon.color → _settings.themeColor
```

### 开发环境
```bash
# 本地开发栈
bash start-pomodoro.sh     # 一键启动（推荐）

# 手动启动
docker-compose up -d        # 数据库和服务
go run main.go             # 后端API
flutter run                # 移动应用
cargo tauri dev            # 桌面应用
```

### 生产环境 (推荐)
```
Load Balancer (Nginx)
├── Backend Cluster (Docker/K8s)
├── Database Cluster (PostgreSQL)
├── Cache Cluster (Redis)
└── Static Assets (CDN)
```

## 🔧 配置管理

### 环境配置
- **开发环境**: docker-compose.simple.yml
- **测试环境**: 内存数据库 + 模拟服务
- **生产环境**: 托管服务 + 容器化部署

### 配置文件
- `.env.example`: 环境变量模板
- `docker-compose.yml`: 华为云镜像配置
- `docker-compose.simple.yml`: 标准镜像配置

这个架构设计充分考虑了性能、可扩展性、安全性和开发效率，能够支持Pomodoro Genie的所有核心功能和未来扩展需求。