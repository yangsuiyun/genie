# 🍅 Pomodoro Genie Backend - 统一入口

## 📋 概述

这是 Pomodoro Genie 后端服务的统一入口，整合了所有功能，使用简化的架构和配置。

## 🚀 快速启动

### 方法一：使用启动脚本（推荐）
```bash
# 给脚本执行权限
chmod +x start-backend.sh

# 启动后端服务
./start-backend.sh
```

### 方法二：手动启动
```bash
# 进入后端目录
cd backend

# 设置环境变量
export PORT=8081
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=postgres
export DB_NAME=pomodoro_genie

# 下载依赖
go mod tidy

# 启动服务
go run cmd/main.go
```

## 🔧 环境配置

### 环境变量
```bash
# 服务器配置
PORT=8081                    # 服务端口
GIN_MODE=debug              # Gin模式 (debug/release)

# 数据库配置
DB_HOST=localhost           # 数据库主机
DB_PORT=5432               # 数据库端口
DB_USER=postgres           # 数据库用户
DB_PASSWORD=postgres       # 数据库密码
DB_NAME=pomodoro_genie     # 数据库名称
DB_SSLMODE=disable         # SSL模式

# 数据库连接池配置
DB_MAX_OPEN_CONNS=25       # 最大打开连接数
DB_MAX_IDLE_CONNS=5        # 最大空闲连接数
DB_MAX_LIFETIME_MINUTES=5  # 连接最大生存时间
DB_MAX_IDLE_TIME_MINUTES=1 # 连接最大空闲时间

# 日志配置
DB_LOG_LEVEL=info          # 数据库日志级别
```

### 配置文件
复制 `env.example` 为 `.env` 并根据需要修改：
```bash
cp env.example .env
```

## 📊 功能特性

### ✅ 核心功能
- **用户认证**: 注册、登录、登出
- **项目管理**: 创建、编辑、删除项目
- **任务管理**: 创建、编辑、删除任务
- **番茄钟**: 开始、暂停、恢复、停止番茄钟会话
- **数据持久化**: PostgreSQL 数据库存储

### 🎯 API 端点
```
GET  /health                    # 健康检查
GET  /                          # API 信息
GET  /docs                      # API 文档

POST /v1/auth/register          # 用户注册
POST /v1/auth/login             # 用户登录
POST /v1/auth/logout            # 用户登出

GET    /v1/projects             # 获取项目列表
POST   /v1/projects             # 创建项目
GET    /v1/projects/:id         # 获取项目详情
PUT    /v1/projects/:id         # 更新项目
DELETE /v1/projects/:id         # 删除项目

GET    /v1/tasks                # 获取任务列表
POST   /v1/tasks                # 创建任务
GET    /v1/tasks/:id            # 获取任务详情
PUT    /v1/tasks/:id            # 更新任务
DELETE /v1/tasks/:id            # 删除任务

POST /v1/pomodoro/start         # 开始番茄钟
POST /v1/pomodoro/pause         # 暂停番茄钟
POST /v1/pomodoro/resume        # 恢复番茄钟
POST /v1/pomodoro/stop          # 停止番茄钟
GET  /v1/pomodoro/sessions      # 获取会话历史
```

## 🗄️ 数据库

### 表结构
- **users**: 用户信息
- **projects**: 项目信息
- **tasks**: 任务信息
- **pomodoro_sessions**: 番茄钟会话

### 数据库初始化
```bash
# 创建数据库
createdb pomodoro_genie

# 运行初始化脚本（可选）
psql -d pomodoro_genie -f migrations/001_init_simplified.sql
```

## 🔍 健康检查

访问 `http://localhost:8081/health` 检查服务状态：
```json
{
  "status": "ok",
  "message": "🍅 Pomodoro Genie API is running",
  "version": "2.2.0-simplified",
  "timestamp": "2024-12-XX",
  "services": {
    "database": "connected",
    "api": "running"
  }
}
```

## 🛠️ 开发

### 项目结构
```
backend/
├── cmd/
│   └── main.go                 # 统一入口文件
├── internal/
│   ├── config/
│   │   └── database.go         # 数据库配置
│   ├── models/
│   │   └── simplified.go       # 数据模型
│   ├── handlers/               # HTTP处理器
│   ├── middleware/             # 中间件
│   └── services/               # 业务逻辑
├── migrations/
│   └── 001_init_simplified.sql # 数据库初始化
├── go.mod                      # Go模块文件
└── env.example                 # 环境配置示例
```

### 开发命令
```bash
# 格式化代码
go fmt ./...

# 运行测试
go test ./...

# 构建应用
go build -o pomodoro-backend cmd/main.go

# 运行应用
./pomodoro-backend
```

## 📝 日志

服务启动时会显示详细的日志信息：
```
🍅 Pomodoro Genie Backend - 启动中...
✅ Go 版本检查通过: 1.24.0
🔧 环境配置:
   - 端口: 8081
   - 数据库: localhost:5432/pomodoro_genie
   - 模式: debug
✅ 数据库连接正常
📦 下载依赖...
🔨 构建应用...
🚀 启动 Pomodoro Genie Backend...
   访问地址: http://localhost:8081
   健康检查: http://localhost:8081/health
   API文档: http://localhost:8081/docs
```

## 🎯 优势

### 简化架构
- **单一入口**: 只有一个主程序文件
- **统一配置**: 简化的环境变量配置
- **最小依赖**: 只保留核心功能所需依赖

### 快速启动
- **一键启动**: 使用启动脚本快速启动
- **自动检查**: 自动检查环境和依赖
- **清晰日志**: 详细的启动和运行日志

### 易于维护
- **清晰结构**: 模块化的代码组织
- **统一标准**: 一致的代码风格和规范
- **完整文档**: 详细的API文档和使用说明

## 🔧 故障排除

### 常见问题

1. **数据库连接失败**
   ```bash
   # 检查PostgreSQL是否运行
   pg_ctl status
   
   # 检查数据库是否存在
   psql -l | grep pomodoro_genie
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   lsof -i :8081
   
   # 修改端口
   export PORT=8082
   ```

3. **依赖问题**
   ```bash
   # 清理模块缓存
   go clean -modcache
   
   # 重新下载依赖
   go mod download
   ```

## 📄 许可证

MIT License

---

**开始你的高效工作之旅！** 🚀
