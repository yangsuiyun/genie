# API 文档

Genie 项目的 RESTful API 接口文档。

## 🌐 API 概览

- **基础 URL**: `http://localhost:5000/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON
- **响应编码**: UTF-8

## 🔐 认证

所有受保护的 API 端点都需要在请求头中包含有效的 JWT token：

```
Authorization: Bearer <your_jwt_token>
```

### 获取 Token

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "your_password"
}
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user_id",
      "email": "user@example.com",
      "name": "User Name"
    }
  }
}
```

## 👤 用户相关 API

### 用户注册
```http
POST /auth/register
Content-Type: application/json

{
  "name": "User Name",
  "email": "user@example.com",
  "password": "strong_password",
  "confirmPassword": "strong_password"
}
```

### 获取用户信息
```http
GET /users/profile
Authorization: Bearer <token>
```

### 更新用户信息
```http
PUT /users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "New Name",
  "email": "new@example.com"
}
```

## 📊 数据相关 API

### 获取列表数据
```http
GET /data
Authorization: Bearer <token>
Query Parameters:
- page: 页码 (默认: 1)
- limit: 每页数量 (默认: 10)
- sort: 排序字段 (默认: createdAt)
- order: 排序方向 (asc/desc, 默认: desc)
- search: 搜索关键词
```

### 创建数据
```http
POST /data
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Data Title",
  "description": "Data Description",
  "category": "category_name"
}
```

### 获取单条数据
```http
GET /data/:id
Authorization: Bearer <token>
```

### 更新数据
```http
PUT /data/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Updated Title",
  "description": "Updated Description"
}
```

### 删除数据
```http
DELETE /data/:id
Authorization: Bearer <token>
```

## 📁 文件上传 API

### 上传文件
```http
POST /upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- file: 文件对象
- type: 文件类型 (image/document/etc)
```

### 获取文件信息
```http
GET /files/:fileId
Authorization: Bearer <token>
```

## 📈 统计数据 API

### 获取统计信息
```http
GET /stats/dashboard
Authorization: Bearer <token>
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 1250,
    "totalData": 5430,
    "recentActivity": [...],
    "popularCategories": [...]
  }
}
```

## 🔄 实时通信

### WebSocket 连接
```
ws://localhost:5000/socket.io
```

### 事件列表
- `connect` - 连接建立
- `disconnect` - 连接断开
- `message` - 接收消息
- `notification` - 接收通知
- `data_update` - 数据更新通知

## 📋 响应格式

### 成功响应
```json
{
  "success": true,
  "data": {
    // 响应数据
  },
  "message": "操作成功",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 错误响应
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {
      // 错误详情
    }
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## 🚨 错误码说明

| 错误码 | HTTP状态码 | 说明 |
|--------|------------|------|
| AUTH_REQUIRED | 401 | 需要身份验证 |
| AUTH_INVALID | 401 | 无效的认证信息 |
| FORBIDDEN | 403 | 权限不足 |
| NOT_FOUND | 404 | 资源不存在 |
| VALIDATION_ERROR | 400 | 数据验证失败 |
| SERVER_ERROR | 500 | 服务器内部错误 |
| RATE_LIMIT | 429 | 请求频率超限 |

## 🔒 安全说明

1. **HTTPS**: 生产环境必须使用 HTTPS
2. **Token 安全**: JWT token 有效期为 24 小时
3. **请求限制**: API 请求有频率限制
4. **数据验证**: 所有输入数据都会进行验证
5. **权限控制**: 基于角色的访问控制

## 📝 SDK 和工具

### JavaScript/TypeScript SDK
```bash
npm install @genie/api-client
```

### Postman Collection
导入 `postman_collection.json` 文件到 Postman 进行 API 测试。

### OpenAPI 规范
查看 `openapi.yaml` 文件获取完整的 API 规范。

## 📞 支持和反馈

如有问题或建议，请通过以下方式联系：
- 创建 GitHub Issue
- 发送邮件到 api-support@example.com
- 查看常见问题解答
