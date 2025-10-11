# 🍅 Pomodoro Genie

一个现代化的番茄钟时间管理应用，支持任务管理、项目分类和数据同步。

## ✨ 核心特性

- ⏱️ **番茄钟计时器** - 专注工作25分钟，短休息5分钟，长休息15分钟
- 📋 **任务管理** - 创建、编辑、完成任务，支持优先级和截止日期
- 📁 **项目分类** - 按项目组织任务，支持自定义图标和颜色
- 📊 **统计报表** - 查看番茄钟统计和任务完成情况
- 🔄 **数据同步** - 自动同步到后端，支持多设备访问
- 💾 **离线支持** - 离线操作自动保存，网络恢复后同步

## 🏗️ 技术架构

### 前端
- **框架**: Flutter (支持 macOS、Web)
- **状态管理**: Riverpod
- **本地存储**: SharedPreferences (缓存)
- **网络请求**: http package
- **策略**: 乐观更新，失败回滚

### 后端
- **语言**: Go 1.21
- **框架**: Gin
- **ORM**: GORM
- **数据库**: PostgreSQL 15
- **认证**: JWT

### 部署
- **容器化**: Docker + Docker Compose
- **编排**: Kubernetes (可选)
- **反向代理**: Nginx

## 🚀 快速开始

### 前置要求

- Go 1.21+
- Flutter 3.22+
- PostgreSQL 15+ (或使用Docker)
- Docker & Docker Compose (推荐)

### 方式一：使用 Docker (推荐)

```bash
# 1. 克隆项目
git clone https://github.com/yangsuiyun/genie.git
cd genie

# 2. 启动所有服务
docker-compose up -d

# 3. 验证服务
curl http://localhost:8081/health  # 后端健康检查
curl http://localhost:3001         # 前端访问
```

**访问地址：**
- 前端: http://localhost:3001
- 后端API: http://localhost:8081
- 健康检查: http://localhost:8081/health

### 方式二：本地开发

```bash
# 1. 启动PostgreSQL (使用Docker)
docker run -d \
  --name pomodoro-postgres \
  -e POSTGRES_DB=pomodoro_genie \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15-alpine

# 2. 启动后端
cd backend
cp env.example .env  # 编辑配置
go run cmd/main.go

# 3. 启动前端
cd mobile
flutter run -d macos  # macOS
flutter run -d chrome # Web
```

## 📁 项目结构

```
genie/
├── backend/              # Go后端服务
│   ├── cmd/
│   │   └── main.go      # 统一入口
│   ├── internal/
│   │   ├── handlers/    # API处理器
│   │   ├── models/      # 数据模型
│   │   ├── services/    # 业务逻辑
│   │   └── middleware/  # 中间件
│   ├── migrations/      # 数据库迁移
│   └── env.example      # 环境配置模板
│
├── mobile/              # Flutter前端
│   ├── lib/
│   │   ├── main.dart    # 应用入口
│   │   ├── services/    # API服务
│   │   └── providers/   # 状态管理
│   └── web/             # Web构建产物
│
├── docker-compose.yml   # Docker编排
├── k8s/                 # Kubernetes配置
└── docs/                # 文档
```

## 🔧 配置说明

### 环境变量

后端主要环境变量（`backend/.env`）：

```bash
# 服务器配置
PORT=8081
GIN_MODE=release

# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=pomodoro_genie

# JWT配置
JWT_SECRET=your-secret-key
JWT_EXPIRE_HOURS=24

# CORS配置
CORS_ALLOWED_ORIGINS=http://localhost:3001
```

完整配置说明见 [ENVIRONMENT_CONFIG_GUIDE.md](ENVIRONMENT_CONFIG_GUIDE.md)

## 📡 API文档

### 核心接口

**项目管理**
```bash
GET    /api/projects      # 获取项目列表
POST   /api/projects      # 创建项目
PUT    /api/projects/:id  # 更新项目
DELETE /api/projects/:id  # 删除项目
```

**任务管理**
```bash
GET    /api/tasks         # 获取任务列表
POST   /api/tasks         # 创建任务
PUT    /api/tasks/:id     # 更新任务
DELETE /api/tasks/:id     # 删除任务
```

**番茄钟**
```bash
POST   /api/pomodoro/start     # 开始会话
POST   /api/pomodoro/complete  # 完成会话
GET    /api/pomodoro/stats     # 获取统计
```

完整API文档见后端 `docs/` 目录。

## 🎯 数据持久化策略

### 工作原理

1. **乐观更新**: 操作立即更新本地UI，提供即时反馈
2. **后台同步**: 同时调用后端API持久化数据
3. **失败处理**: 
   - 网络错误：保留本地更改，标记待同步
   - 业务错误：回滚本地状态，提示用户
4. **启动加载**: 应用启动时从服务器获取最新数据

### 示例流程

```dart
// 创建任务
1. 用户点击"添加任务" → UI立即显示新任务
2. 同时调用 POST /api/tasks
3. 成功：用服务器返回的ID更新本地
4. 失败：回滚或保留（根据错误类型）
```

详细策略见 [DATA_PERSISTENCE_STRATEGY.md](DATA_PERSISTENCE_STRATEGY.md)

## 🐳 Docker部署

### 构建镜像

```bash
# 前端镜像
docker build -t pomodoro-frontend ./mobile

# 后端镜像
docker build -t pomodoro-backend ./backend
```

### 使用Docker Compose

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## ☸️ Kubernetes部署

```bash
# 部署到K8s
./deploy-k8s.sh

# 或手动部署
kubectl apply -f k8s/
```

详细部署指南见 [K8S_DEPLOYMENT_GUIDE.md](K8S_DEPLOYMENT_GUIDE.md)

## 🧪 测试

### API集成测试

```bash
# 测试后端API
./test-api-integration.sh
```

### 手动测试

```bash
# 健康检查
curl http://localhost:8081/health

# 创建项目
curl -X POST http://localhost:8081/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"测试项目","icon":"📁","color":"#6c757d"}'

# 获取项目列表
curl http://localhost:8081/api/projects

# 创建任务
curl -X POST http://localhost:8081/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"测试任务","project_id":"inbox","priority":"medium"}'
```

## 🛠️ 开发指南

### 添加新功能

1. **后端**：在 `backend/internal/` 添加处理器和服务
2. **前端**：在 `mobile/lib/` 添加UI和状态管理
3. **API**：更新 `api_service.dart` 添加API调用
4. **测试**：验证功能并更新测试脚本

### 代码规范

- Go: 遵循 [Effective Go](https://go.dev/doc/effective_go)
- Dart/Flutter: 使用 `flutter analyze` 检查
- 提交信息: 使用 [Conventional Commits](https://www.conventionalcommits.org/)

## 📚 文档索引

- [完整设计文档](POMODORO_GENIE_COMPLETE.md) - 详细的系统设计
- [API集成指南](API_INTEGRATION_GUIDE.md) - 如何集成后端API
- [数据持久化策略](DATA_PERSISTENCE_STRATEGY.md) - 数据同步机制
- [环境配置指南](ENVIRONMENT_CONFIG_GUIDE.md) - 环境变量配置
- [K8s部署指南](K8S_DEPLOYMENT_GUIDE.md) - Kubernetes部署

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🔗 相关链接

- [GitHub仓库](https://github.com/yangsuiyun/genie)
- [问题反馈](https://github.com/yangsuiyun/genie/issues)

---

Made with ❤️ by Pomodoro Genie Team
