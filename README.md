# 🍅 Pomodoro Genie

一个现代化的番茄钟时间管理应用，支持任务管理、项目分类和数据同步。

## ✨ 特性

- ⏱️ **番茄钟计时** - 25分钟工作，5分钟休息，自动循环
- 📋 **任务管理** - 创建、编辑任务，支持优先级和截止日期
- 📁 **项目分类** - 按项目组织任务
- 🔄 **数据同步** - 自动同步到后端，支持多设备
- 💾 **离线支持** - 离线操作自动保存

## 🚀 快速开始

### 使用 Docker（推荐）

```bash
# 启动所有服务
docker-compose up -d

# 访问应用
# 前端: http://localhost:3001
# 后端: http://localhost:8081
```

### 本地开发

```bash
# 1. 启动数据库
docker run -d --name pomodoro-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=pomodoro_genie \
  -p 5432:5432 postgres:15-alpine

# 2. 启动后端
cd backend
cp env.example .env
go run cmd/main.go

# 3. 启动前端
cd mobile
flutter run -d macos  # 或 chrome
```

## 📁 项目结构

```
genie/
├── backend/           # Go后端
│   ├── cmd/main.go   # 入口
│   └── internal/     # 核心代码
├── mobile/           # Flutter前端
│   └── lib/          # 应用代码
└── docker-compose.yml
```

## 🏗️ 技术架构

```
Flutter前端 (UI + Riverpod状态管理)
    ↓ HTTP/REST
Go后端 (Gin + GORM)
    ↓
PostgreSQL数据库
```

### 技术栈

**前端**: Flutter 3.22+ | Riverpod | SharedPreferences | http  
**后端**: Go 1.21+ | Gin | GORM | PostgreSQL 15 | JWT  
**部署**: Docker | Kubernetes

## 🎯 核心设计

### 数据模型

```
User (用户)
  ├── Project (项目) [1:N]
  │     └── Task (任务) [1:N]
  │           └── PomodoroSession (番茄钟) [1:N]
  └── PomodoroSession [1:N]
```

### 数据同步策略

**乐观更新 + 后台同步:**

```
1. 用户操作 → 立即更新UI
2. 同时调用后端API
3. 成功：更新本地数据
4. 失败：回滚或保留（根据错误类型）
```

**代码示例:**
```dart
Future<void> createTask(...) async {
  // 1. 生成临时ID
  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final task = Task(id: tempId, ...);
  
  // 2. 乐观更新UI
  state = [...state, task];
  await cache.save(state);
  
  try {
    // 3. 调用API
    final saved = await api.createTask(task);
    
    // 4. 更新真实ID
    state = state.map((t) => t.id == tempId ? saved : t).toList();
    await cache.save(state);
    
  } on NetworkException {
    // 网络错误：保留本地更改
    print('离线模式');
  } catch (e) {
    // 业务错误：回滚
    state = state.where((t) => t.id != tempId).toList();
    rethrow;
  }
}
```

## 🌐 API接口

### 基础URL
`http://localhost:8081/api`

### 主要接口

**项目:**
```
GET    /projects      # 获取列表
POST   /projects      # 创建
PUT    /projects/:id  # 更新
DELETE /projects/:id  # 删除
```

**任务:**
```
GET    /tasks         # 获取列表
POST   /tasks         # 创建
PUT    /tasks/:id     # 更新
DELETE /tasks/:id     # 删除
```

**番茄钟:**
```
POST   /pomodoro/start     # 开始
POST   /pomodoro/complete  # 完成
GET    /pomodoro/stats     # 统计
```

### 请求示例

```bash
# 创建任务
curl -X POST http://localhost:8081/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "完成文档",
    "project_id": "inbox",
    "priority": "medium"
  }'
```

## ⚙️ 配置

### 环境变量 (`backend/.env`)

```bash
# 服务器
PORT=8081
GIN_MODE=release

# 数据库
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=pomodoro_genie

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRE_HOURS=24

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3001
```

### Docker部署

```yaml
# docker-compose.yml已配置好
# 直接使用:
docker-compose up -d
```

## ☸️ Kubernetes部署

```bash
# 1. 修改密钥
vim k8s/secrets.yaml

# 2. 部署
kubectl apply -f k8s/

# 3. 查看状态
kubectl get pods
```

**资源配置:**
- Backend: 2副本, 512Mi内存
- Frontend: 2副本, 256Mi内存  
- PostgreSQL: StatefulSet, 20Gi存储

## 🧪 测试

```bash
# 运行API测试
./test-api-integration.sh

# 手动测试
curl http://localhost:8081/health
```

## 🔍 故障排查

### Docker服务无法启动

```bash
# 检查状态
docker-compose ps

# 查看日志
docker-compose logs backend
docker-compose logs frontend
```

### API调用失败

```bash
# 1. 检查后端健康
curl http://localhost:8081/health

# 2. 查看后端日志
docker logs -f pomodoro-backend

# 3. 检查数据库连接
docker exec -it pomodoro-postgres psql -U postgres
```

### K8s Pod无法启动

```bash
# 查看Pod详情
kubectl describe pod <pod-name>

# 查看日志
kubectl logs -f <pod-name>

# 查看事件
kubectl get events --sort-by='.lastTimestamp'
```

## 📊 监控

### 查看日志

```bash
# Docker
docker-compose logs -f

# K8s
kubectl logs -f deployment/pomodoro-backend
```

### 性能指标

| 指标 | 目标 |
|------|------|
| API响应时间 | <100ms |
| 同步成功率 | >99% |
| 缓存命中率 | >80% |

## 🔄 更新部署

### Docker

```bash
# 重新构建
docker-compose build

# 重启服务
docker-compose restart
```

### Kubernetes

```bash
# 更新镜像
kubectl set image deployment/pomodoro-backend \
  backend=your-image:v2

# 查看更新状态
kubectl rollout status deployment/pomodoro-backend

# 回滚
kubectl rollout undo deployment/pomodoro-backend
```

## 📈 扩容

```bash
# Docker Compose (修改docker-compose.yml中的replicas)
docker-compose up -d --scale backend=3

# Kubernetes
kubectl scale deployment/pomodoro-backend --replicas=3

# 自动扩容 (HPA)
kubectl autoscale deployment/pomodoro-backend \
  --min=2 --max=10 --cpu-percent=70
```

## 🔒 安全建议

1. **生产环境必须修改:**
   - `JWT_SECRET`: 使用强随机密钥
   - `DB_PASSWORD`: 使用复杂密码
   - `DB_SSLMODE=require`: 启用SSL

2. **CORS配置:**
   - 只允许实际使用的域名
   - 避免使用通配符

3. **K8s安全:**
   - 使用Secret存储敏感信息
   - 配置NetworkPolicy
   - 启用RBAC

## 🛠️ 开发指南

### 添加新功能

1. **后端**: 在 `backend/internal/handlers/` 添加处理器
2. **前端**: 在 `mobile/lib/` 添加UI和Provider
3. **API**: 更新 `mobile/lib/services/api_service.dart`
4. **测试**: 更新 `test-api-integration.sh`

### 代码规范

```bash
# Go格式化
cd backend && go fmt ./...

# Flutter分析
cd mobile && flutter analyze
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

提交规范: [Conventional Commits](https://www.conventionalcommits.org/)

## 📄 许可证

MIT License

---

**更多文档:** 
- [系统设计详解](DESIGN.md)
- [完整部署指南](DEPLOYMENT.md)

**相关链接:**
- [GitHub仓库](https://github.com/yangsuiyun/genie)
- [问题反馈](https://github.com/yangsuiyun/genie/issues)

---

Made with ❤️ by Pomodoro Genie Team
