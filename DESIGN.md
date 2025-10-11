# 🍅 Pomodoro Genie - 系统设计文档

> 现代化的番茄钟时间管理应用系统设计

## 📋 目录

- [系统架构](#系统架构)
- [技术栈](#技术栈)
- [数据模型](#数据模型)
- [核心功能](#核心功能)
- [API设计](#api设计)
- [状态管理](#状态管理)

---

## 🏗️ 系统架构

```
┌─────────────┐
│   Flutter   │ ← 前端 (macOS/Web)
│   Frontend  │
└──────┬──────┘
       │ HTTP/REST
       ▼
┌─────────────┐
│  Gin/Go API │ ← 后端服务
│   Backend   │
└──────┬──────┘
       │ GORM
       ▼
┌─────────────┐
│ PostgreSQL  │ ← 数据库
│   Database  │
└─────────────┘
```

### 分层架构

**前端 (Flutter)**
```
UI Layer (Widgets)
    ↓
State Layer (Riverpod Providers)
    ↓
Service Layer (API Service)
    ↓
Cache Layer (SharedPreferences)
```

**后端 (Go)**
```
Handler Layer (HTTP Handlers)
    ↓
Service Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
Model Layer (Database Models)
```

---

## 🛠️ 技术栈

### 前端技术

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.22+ | UI框架 |
| Riverpod | 2.6+ | 状态管理 |
| SharedPreferences | 2.2+ | 本地缓存 |
| http | 1.1+ | 网络请求 |

### 后端技术

| 技术 | 版本 | 用途 |
|------|------|------|
| Go | 1.21+ | 后端语言 |
| Gin | 1.9+ | Web框架 |
| GORM | 1.25+ | ORM框架 |
| PostgreSQL | 15+ | 数据库 |
| JWT | - | 身份认证 |

### 基础设施

| 技术 | 用途 |
|------|------|
| Docker | 容器化 |
| Docker Compose | 本地开发 |
| Kubernetes | 生产部署 |
| Nginx | 反向代理 |

---

## 📊 数据模型

### 核心实体关系

```
User (用户)
  ├── Project (项目) [1:N]
  │     └── Task (任务) [1:N]
  │           └── PomodoroSession (番茄钟会话) [1:N]
  └── PomodoroSession [1:N]
```

### 数据模型定义

#### User (用户)
```go
type User struct {
    ID        string    `gorm:"primaryKey"`
    Email     string    `gorm:"unique;not null"`
    Name      string
    CreatedAt time.Time
    UpdatedAt time.Time
}
```

#### Project (项目)
```go
type Project struct {
    ID        string    `gorm:"primaryKey"`
    UserID    string    `gorm:"index;not null"`
    Name      string    `gorm:"not null"`
    Icon      string
    Color     string
    Order     int
    CreatedAt time.Time
    UpdatedAt time.Time
    
    Tasks []Task `gorm:"foreignKey:ProjectID"`
}
```

#### Task (任务)
```go
type Task struct {
    ID                  string    `gorm:"primaryKey"`
    UserID              string    `gorm:"index;not null"`
    ProjectID           string    `gorm:"index"`
    Title               string    `gorm:"not null"`
    Description         string
    IsCompleted         bool      `gorm:"default:false"`
    Priority            string    `gorm:"default:'medium'"`
    PlannedPomodoros    int       `gorm:"default:4"`
    CompletedPomodoros  int       `gorm:"default:0"`
    DueDate             *time.Time
    Order               int
    CreatedAt           time.Time
    UpdatedAt           time.Time
    
    PomodoroSessions []PomodoroSession `gorm:"foreignKey:TaskID"`
}
```

#### PomodoroSession (番茄钟会话)
```go
type PomodoroSession struct {
    ID        string    `gorm:"primaryKey"`
    UserID    string    `gorm:"index;not null"`
    TaskID    string    `gorm:"index"`
    Type      string    `gorm:"not null"` // work/short_break/long_break
    Duration  int       `gorm:"not null"` // 秒数
    StartTime time.Time
    EndTime   time.Time
    CreatedAt time.Time
}
```

---

## ⚙️ 核心功能

### 1. 任务管理

**功能点：**
- 创建/编辑/删除任务
- 任务优先级设置 (低/中/高)
- 截止日期管理
- 任务完成状态切换
- 按项目分组显示

**实现方式：**
```dart
// 前端 - 创建任务
await ref.read(tasksProvider.notifier).addTask(
  title: '新任务',
  projectId: 'inbox',
  priority: TaskPriority.medium,
  dueDate: DateTime.now().add(Duration(days: 7)),
);

// 后端 - API端点
POST /api/tasks
PUT  /api/tasks/:id
DELETE /api/tasks/:id
```

### 2. 番茄钟计时

**功能点：**
- 25分钟工作时间
- 5分钟短休息
- 15分钟长休息
- 自动循环切换
- 暂停/恢复功能

**工作流程：**
```
工作(25min) → 短休息(5min) → 工作(25min) → 短休息(5min) 
  → 工作(25min) → 短休息(5min) → 工作(25min) → 长休息(15min)
  → 循环...
```

### 3. 数据同步

**同步策略：**
1. **启动时**：从服务器加载最新数据
2. **操作时**：乐观更新本地，后台同步
3. **失败时**：
   - 网络错误：保留本地，待同步
   - 业务错误：回滚，提示用户

**同步流程：**
```
用户操作 → 更新本地UI → 调用API
                ↓
        成功：更新本地数据
                ↓
        失败：回滚/保留（根据错误类型）
```

---

## 🌐 API设计

### RESTful接口规范

**基础URL**: `http://localhost:8081/api`

### 项目接口

```
GET    /projects           # 获取项目列表
POST   /projects           # 创建项目
GET    /projects/:id       # 获取项目详情
PUT    /projects/:id       # 更新项目
DELETE /projects/:id       # 删除项目
```

**请求示例：**
```bash
# 创建项目
curl -X POST /api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "工作项目",
    "icon": "💼",
    "color": "#007bff"
  }'

# 响应
{
  "id": "project_123",
  "name": "工作项目",
  "icon": "💼",
  "color": "#007bff",
  "created_at": "2025-10-11T10:00:00Z",
  "updated_at": "2025-10-11T10:00:00Z"
}
```

### 任务接口

```
GET    /tasks              # 获取任务列表
POST   /tasks              # 创建任务
GET    /tasks/:id          # 获取任务详情
PUT    /tasks/:id          # 更新任务
DELETE /tasks/:id          # 删除任务
```

**查询参数：**
- `project_id`: 按项目筛选
- `is_completed`: 按完成状态筛选
- `due_date_from/to`: 按截止日期筛选

### 番茄钟接口

```
POST   /pomodoro/start     # 开始会话
POST   /pomodoro/complete  # 完成会话
GET    /pomodoro/stats     # 获取统计数据
```

### 统一响应格式

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

**错误响应：**
```json
{
  "code": 400,
  "message": "错误描述",
  "errors": [ ... ]
}
```

---

## 🔄 状态管理

### Riverpod架构

```dart
// Provider定义
final projectsProvider = 
    StateNotifierProvider<ProjectNotifier, List<Project>>(
  (ref) => ProjectNotifier()
);

final tasksProvider = 
    StateNotifierProvider<TaskNotifier, List<Task>>(
  (ref) => TaskNotifier()
);

final timerProvider = 
    StateNotifierProvider<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(ref)
);
```

### 状态流转

**任务状态：**
```
创建 → 进行中 → 已完成
   ↓         ↓
 已删除   已删除
```

**番茄钟状态：**
```
准备 → 工作中 → 短休息 → 工作中 → 长休息 → 准备
         ↓         ↓         ↓
       暂停     暂停      暂停
```

### 数据缓存策略

```dart
// 启动时
1. 加载本地缓存 → 立即显示UI
2. 请求服务器 → 获取最新数据
3. 更新UI和缓存

// 操作时
1. 更新本地状态 → UI立即响应
2. 调用后端API → 后台同步
3. 成功：更新本地ID
4. 失败：回滚或标记待同步
```

---

## 🎨 UI/UX设计原则

### 设计理念

1. **简洁优先** - 避免过度设计，专注核心功能
2. **即时反馈** - 所有操作立即响应，乐观更新
3. **容错处理** - 网络错误友好提示，支持离线操作
4. **一致性** - 统一的交互模式和视觉风格

### 交互模式

- **快速创建** - 点击即可创建，减少步骤
- **上下文菜单** - 长按显示更多操作
- **拖拽排序** - 直观的顺序调整
- **滑动删除** - 快速删除操作

### 视觉设计

- **卡片式布局** - 清晰的信息分组
- **颜色编码** - 优先级和状态标识
- **图标语言** - 直观的视觉提示
- **动画过渡** - 流畅的状态切换

---

## 🔐 安全设计

### 认证授权

```
用户登录 → JWT Token → 后续请求携带Token
                ↓
        服务端验证Token → 允许/拒绝
```

### 数据安全

- 密码加密存储 (bcrypt)
- HTTPS传输加密
- SQL注入防护 (GORM)
- XSS防护 (输入验证)

---

## 📈 性能优化

### 前端优化

1. **乐观更新** - 减少等待时间
2. **列表虚拟化** - 大数据量优化
3. **图片懒加载** - 按需加载资源
4. **状态缓存** - 减少重复计算

### 后端优化

1. **数据库索引** - 加速查询
2. **连接池** - 复用数据库连接
3. **分页加载** - 限制单次数据量
4. **缓存策略** - Redis缓存热点数据(可选)

---

## 🚀 部署架构

### Docker Compose (开发/测试)

```yaml
services:
  postgres:   # 数据库
  backend:    # Go API服务
  frontend:   # Flutter Web (Nginx)
```

### Kubernetes (生产)

```
Ingress → Service → Deployment
    ↓         ↓         ↓
  路由    负载均衡   Pod实例
```

**资源配置：**
- Backend: 2 replicas, 512Mi memory
- Frontend: 2 replicas, 256Mi memory
- PostgreSQL: StatefulSet, PV 20Gi

---

## 📚 参考资源

- [Go最佳实践](https://go.dev/doc/effective_go)
- [Flutter架构指南](https://docs.flutter.dev/development/data-and-backend/state-mgmt)
- [RESTful API设计](https://restfulapi.net/)
- [PostgreSQL文档](https://www.postgresql.org/docs/)

---

最后更新：2025-10-11

