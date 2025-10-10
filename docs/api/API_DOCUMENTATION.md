# 📡 Pomodoro Genie API 文档

## 📋 API概览

Pomodoro Genie API 是一个RESTful服务，提供任务管理、番茄钟会话、用户账户和生产力分析等端点。API设计支持跨平台客户端，包括移动应用、Web应用和桌面客户端。

## 🚀 快速开始

### API基础URL
- **生产环境**: `https://api.pomodoro-genie.com/v1`
- **测试环境**: `https://staging-api.pomodoro-genie.com/v1`
- **开发环境**: `http://localhost:8081/v1`

### 认证方式
大多数端点需要JWT Bearer token认证：

```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     https://api.pomodoro-genie.com/v1/tasks
```

## 🔐 认证和授权

### 获取认证Token

#### 用户注册
```bash
curl -X POST https://api.pomodoro-genie.com/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "StrongPassword123!"
  }'
```

#### 用户登录
```bash
curl -X POST https://api.pomodoro-genie.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "StrongPassword123!"
  }'
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user-123",
      "email": "john@example.com",
      "name": "John Doe",
      "avatar_url": null,
      "created_at": "2025-01-01T00:00:00Z"
    },
    "expires_at": "2025-01-02T00:00:00Z"
  }
}
```

### Token刷新
```bash
curl -X POST https://api.pomodoro-genie.com/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "your_refresh_token"
  }'
```

## 📋 任务管理

### 获取任务列表
```bash
curl "https://api.pomodoro-genie.com/v1/tasks?status=pending&priority=high" \
  -H "Authorization: Bearer $TOKEN"
```

**查询参数**:
- `status`: `pending`, `in_progress`, `completed`
- `priority`: `low`, `medium`, `high`, `urgent`
- `page`: 页码 (默认: 1)
- `limit`: 每页数量 (默认: 20, 最大: 100)
- `search`: 搜索关键词
- `tags`: 标签过滤

**响应示例**:
```json
{
  "success": true,
  "data": {
    "tasks": [
      {
        "id": "task-456",
        "title": "Complete project documentation",
        "description": "Write comprehensive API documentation",
        "status": "in_progress",
        "priority": "high",
        "due_date": "2025-01-15T00:00:00Z",
        "estimated_pomodoros": 5,
        "completed_pomodoros": 2,
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-06T10:30:00Z",
        "tags": ["documentation", "urgent"],
        "subtasks": [
          {
            "id": "subtask-789",
            "title": "Create component diagram",
            "completed": false
          }
        ]
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "has_next": true
    }
  }
}
```

### 创建任务
```bash
curl -X POST https://api.pomodoro-genie.com/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete project documentation",
    "description": "Write comprehensive API documentation",
    "priority": "high",
    "estimated_pomodoros": 5,
    "due_date": "2025-01-15T00:00:00Z",
    "tags": ["documentation", "urgent"]
  }'
```

### 更新任务
```bash
curl -X PUT https://api.pomodoro-genie.com/v1/tasks/TASK_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "completed_pomodoros": 5
  }'
```

### 删除任务
```bash
curl -X DELETE https://api.pomodoro-genie.com/v1/tasks/TASK_ID \
  -H "Authorization: Bearer $TOKEN"
```

## 🍅 番茄钟会话

### 开始工作会话
```bash
curl -X POST https://api.pomodoro-genie.com/v1/pomodoro/sessions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "TASK_ID",
    "session_type": "work",
    "planned_duration": 1500
  }'
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": "session-789",
    "task_id": "task-456",
    "type": "work",
    "duration": 1500,
    "status": "active",
    "started_at": "2025-01-06T10:00:00Z",
    "remaining_time": 1500,
    "sequence_position": 3,
    "break_after": true
  }
}
```

### 暂停/恢复会话
```bash
curl -X PUT https://api.pomodoro-genie.com/v1/pomodoro/sessions/SESSION_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "pause"
  }'
```

### 完成会话
```bash
curl -X PUT https://api.pomodoro-genie.com/v1/pomodoro/sessions/SESSION_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "complete",
    "actual_duration": 1495,
    "interrupted": false,
    "completion_notes": "Focused session, good progress"
  }'
```

### 获取会话历史
```bash
curl "https://api.pomodoro-genie.com/v1/pomodoro/sessions?date_from=2025-01-01&date_to=2025-01-06" \
  -H "Authorization: Bearer $TOKEN"
```

## 📊 统计和分析

### 用户统计
```bash
curl "https://api.pomodoro-genie.com/v1/users/USER_ID/stats?period=week" \
  -H "Authorization: Bearer $TOKEN"
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "period": "week",
    "summary": {
      "total_pomodoros": 28,
      "total_focus_time": 11200,
      "completed_tasks": 12,
      "average_session_length": 1450,
      "productivity_score": 85
    },
    "daily_breakdown": [
      {
        "date": "2025-01-06",
        "pomodoros": 6,
        "focus_time": 2250,
        "tasks_completed": 3,
        "most_productive_hour": 14
      }
    ],
    "time_distribution": {
      "0": 0, "1": 0, "2": 0, "3": 0,
      "9": 2, "10": 4, "11": 3, "14": 6, "15": 4
    }
  }
}
```

### 生成报告
```bash
curl "https://api.pomodoro-genie.com/v1/reports?type=weekly&start_date=2025-01-01T00:00:00Z&end_date=2025-01-07T23:59:59Z" \
  -H "Authorization: Bearer $TOKEN"
```

### 获取分析数据
```bash
curl "https://api.pomodoro-genie.com/v1/reports/analytics?period=week&metrics=productivity_score,focus_time" \
  -H "Authorization: Bearer $TOKEN"
```

## 🔄 数据同步

### 拉取变更
```bash
curl -X POST https://api.pomodoro-genie.com/v1/sync/pull \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "last_sync_timestamp": "2025-01-15T10:30:00Z",
    "device_id": "device_123"
  }'
```

### 推送变更
```bash
curl -X POST https://api.pomodoro-genie.com/v1/sync/push \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "device_123",
    "changes": [
      {
        "entity_type": "task",
        "entity_id": "TASK_ID",
        "operation": "update",
        "data": { "status": "completed" },
        "timestamp": "2025-01-15T10:35:00Z"
      }
    ]
  }'
```

## 📡 WebSocket实时更新

### 连接WebSocket
```javascript
const ws = new WebSocket('wss://api.pomodoro-genie.com/v1/ws');

ws.onopen = () => {
  // 认证
  ws.send(JSON.stringify({
    type: 'auth',
    token: 'your-jwt-token'
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  
  switch (data.type) {
    case 'task_updated':
      // 处理任务更新
      break;
    case 'session_completed':
      // 处理会话完成
      break;
    case 'project_stats_changed':
      // 处理项目统计变更
      break;
  }
};
```

## 📝 响应格式

### 成功响应
```json
{
  "success": true,
  "data": { /* 响应数据 */ },
  "pagination": { /* 分页信息（如果适用） */ }
}
```

### 错误响应
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": "Additional error details"
  }
}
```

## 🚦 错误代码

| 代码 | 描述 |
|------|------|
| `VALIDATION_ERROR` | 无效输入数据 |
| `AUTHENTICATION_REQUIRED` | 缺少或无效认证 |
| `AUTHORIZATION_FAILED` | 权限不足 |
| `RESOURCE_NOT_FOUND` | 请求的资源不存在 |
| `RATE_LIMIT_EXCEEDED` | 请求过于频繁 |
| `INTERNAL_SERVER_ERROR` | 服务器错误 |
| `SERVICE_UNAVAILABLE` | 服务暂时不可用 |

## ⚡ 频率限制

API实现频率限制：

- **认证用户**: 每分钟100个请求
- **未认证用户**: 每分钟20个请求

频率限制头信息包含在响应中：

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642694400
```

## 🔒 安全最佳实践

1. **始终使用HTTPS** 在生产环境中
2. **安全存储JWT tokens** (Web应用中不要存储在localStorage)
3. **实现token刷新** 以维持会话
4. **验证所有输入** 在客户端和服务端
5. **优雅处理频率限制** 在您的应用中
6. **记录安全事件** 用于监控

### Token管理示例
```javascript
// Token刷新实现示例
async function refreshToken() {
  try {
    const response = await fetch('/v1/auth/refresh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${refreshToken}`
      },
      body: JSON.stringify({
        refresh_token: refreshToken
      })
    });

    const data = await response.json();
    accessToken = data.access_token;

    // 安排下次刷新
    setTimeout(refreshToken, (data.expires_in - 300) * 1000);
  } catch (error) {
    // 处理刷新失败（重定向到登录）
    window.location.href = '/login';
  }
}
```

## 📚 SDK和客户端库

官方客户端库可用于：

- **JavaScript/TypeScript**: `npm install pomodoro-genie-api`
- **Python**: `pip install pomodoro-genie-api`
- **Go**: `go get github.com/pomodoro-genie/go-client`
- **Swift**: 通过Swift Package Manager提供
- **Dart/Flutter**: 在pub.dev上提供

### JavaScript SDK示例
```javascript
import { PomodoroGenieAPI } from 'pomodoro-genie-api';

const api = new PomodoroGenieAPI({
  baseURL: 'https://api.pomodoro-genie.com/v1',
  token: 'your-jwt-token'
});

// 创建任务
const task = await api.tasks.create({
  title: 'Complete API documentation',
  priority: 'high',
  estimated_pomodoros: 3
});

// 开始番茄钟会话
const session = await api.pomodoro.start({
  task_id: task.id,
  session_type: 'work',
  planned_duration: 1500
});
```

## 🧪 测试API

### 使用cURL
本文档中的所有示例都使用cURL，可以直接从命令行运行。

### 使用Postman
1. 将OpenAPI规范导入Postman
2. 设置环境变量用于基础URL和认证token
3. 使用预配置的请求和示例

### 使用HTTPie
```bash
# 安装HTTPie
pip install httpie

# 使用示例
http POST api.pomodoro-genie.com/v1/auth/login \
  email=john@example.com \
  password=StrongPassword123!

http GET api.pomodoro-genie.com/v1/tasks \
  Authorization:"Bearer $TOKEN"
```

## 📊 性能考虑

### 缓存
API在多个级别实现缓存：

- **HTTP缓存**: 静态内容的标准缓存头
- **应用缓存**: 基于Redis的频繁访问数据缓存
- **CDN缓存**: 静态资源的全球内容分发

### 分页
对大数据集使用分页：

```bash
# 获取第一页（20个项目）
curl "https://api.pomodoro-genie.com/v1/tasks?page=1&limit=20" \
  -H "Authorization: Bearer $TOKEN"

# 获取下一页
curl "https://api.pomodoro-genie.com/v1/tasks?page=2&limit=20" \
  -H "Authorization: Bearer $TOKEN"
```

### 过滤和搜索
使用过滤优化查询：

```bash
# 按多个条件过滤
curl "https://api.pomodoro-genie.com/v1/tasks?status=pending&priority=high&tags=urgent" \
  -H "Authorization: Bearer $TOKEN"

# 按文本搜索
curl "https://api.pomodoro-genie.com/v1/tasks?search=documentation" \
  -H "Authorization: Bearer $TOKEN"
```

## 📞 支持和资源

### 文档更新
本文档从OpenAPI规范自动生成。要请求更新：

1. 在项目仓库提交issue
2. 创建包含建议更改的pull request
3. 直接联系API团队

### API状态
检查当前API状态和正常运行时间：
- **状态页面**: https://status.pomodoro-genie.com
- **健康检查**: https://api.pomodoro-genie.com/v1/health

### 社区和支持
- **GitHub仓库**: https://github.com/pomodoro-genie/api
- **Discord社区**: https://discord.gg/pomodoro-genie
- **Stack Overflow**: 在您的问题上标记 `pomodoro-genie-api`
- **支持邮箱**: api-support@pomodoro-genie.com

### 变更日志
API更改和更新记录在：
- **API变更日志**: https://docs.pomodoro-genie.com/changelog
- **破坏性更改**: https://docs.pomodoro-genie.com/breaking-changes
- **迁移指南**: https://docs.pomodoro-genie.com/migrations

---

**最后更新**: 2025-01-07  
**API版本**: v1  
**维护者**: Pomodoro Genie API团队
