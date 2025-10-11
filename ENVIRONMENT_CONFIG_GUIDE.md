# ⚙️ 环境配置指南

> 后端服务环境变量配置说明

## 📋 配置文件

**位置**: `backend/.env`  
**模板**: `backend/env.example`

```bash
# 复制模板创建配置文件
cd backend
cp env.example .env
```

## 🔧 配置项说明

### 服务器配置

```bash
# HTTP服务端口
PORT=8081

# 运行模式：debug/release
GIN_MODE=release
```

**说明:**
- `PORT`: 后端API监听端口，默认8081
- `GIN_MODE`: 
  - `debug`: 开发模式，详细日志
  - `release`: 生产模式，精简日志

### 数据库配置

```bash
# PostgreSQL连接信息
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=pomodoro_genie
DB_SSLMODE=disable
```

**说明:**
- `DB_HOST`: 数据库主机地址
  - 本地: `localhost`
  - Docker: `pomodoro-postgres` (服务名)
  - 远程: IP地址或域名
- `DB_PORT`: PostgreSQL端口，默认5432
- `DB_SSLMODE`: SSL模式
  - `disable`: 禁用SSL (开发环境)
  - `require`: 要求SSL (生产环境)

### JWT认证配置

```bash
# JWT密钥和有效期
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRE_HOURS=24
```

**说明:**
- `JWT_SECRET`: JWT签名密钥
  - ⚠️ 生产环境必须更换
  - 建议使用64位以上随机字符串
- `JWT_EXPIRE_HOURS`: Token有效期（小时）

### CORS配置

```bash
# 允许的前端域名
CORS_ALLOWED_ORIGINS=http://localhost:3001,http://localhost:3000
```

**说明:**
- 多个域名用逗号分隔
- 开发环境常用端口：3000, 3001
- 生产环境使用实际域名

### 日志配置

```bash
# 数据库日志级别
DB_LOG_LEVEL=info
```

**可选值:**
- `silent`: 静默，无日志
- `error`: 仅错误
- `warn`: 警告和错误
- `info`: 信息、警告和错误（推荐）

## 📝 配置示例

### 本地开发环境

```bash
PORT=8081
GIN_MODE=debug
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=pomodoro_genie
DB_SSLMODE=disable
DB_LOG_LEVEL=info
JWT_SECRET=dev-secret-key-123
JWT_EXPIRE_HOURS=24
CORS_ALLOWED_ORIGINS=http://localhost:3001
```

### Docker Compose环境

```bash
PORT=8081
GIN_MODE=release
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=pomodoro_genie
DB_SSLMODE=disable
DB_LOG_LEVEL=info
JWT_SECRET=docker-secret-key-456
JWT_EXPIRE_HOURS=24
CORS_ALLOWED_ORIGINS=http://localhost:3001
```

### 生产环境

```bash
PORT=8081
GIN_MODE=release
DB_HOST=your-db-host.com
DB_PORT=5432
DB_USER=prod_user
DB_PASSWORD=strong-password-here
DB_NAME=pomodoro_genie
DB_SSLMODE=require
DB_LOG_LEVEL=warn
JWT_SECRET=production-secret-key-change-this-123456789
JWT_EXPIRE_HOURS=168
CORS_ALLOWED_ORIGINS=https://yourdomain.com
```

## 🐳 Docker环境变量

在 `docker-compose.yml` 中配置：

```yaml
services:
  backend:
    environment:
      PORT: 8081
      GIN_MODE: release
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: pomodoro_genie
      DB_SSLMODE: disable
      JWT_SECRET: ${JWT_SECRET:-default-secret}
      JWT_EXPIRE_HOURS: 24
      CORS_ALLOWED_ORIGINS: http://localhost:3001
```

## ☸️ Kubernetes配置

使用Secret存储敏感信息：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pomodoro-backend-secret
type: Opaque
stringData:
  DB_PASSWORD: your-db-password
  JWT_SECRET: your-jwt-secret

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pomodoro-backend-config
data:
  PORT: "8081"
  GIN_MODE: "release"
  DB_HOST: "pomodoro-postgres"
  DB_PORT: "5432"
  DB_USER: "postgres"
  DB_NAME: "pomodoro_genie"
```

## 🔒 安全建议

### 1. JWT密钥

```bash
# ✅ 推荐：使用随机生成的强密钥
JWT_SECRET=$(openssl rand -base64 64)

# ❌ 避免：简单密码
JWT_SECRET=123456
```

### 2. 数据库密码

```bash
# ✅ 推荐：强密码
DB_PASSWORD=Xy9$mK2#pL4@wN8

# ❌ 避免：弱密码
DB_PASSWORD=password
```

### 3. 生产环境

- ✅ 启用SSL：`DB_SSLMODE=require`
- ✅ 限制CORS：只允许实际域名
- ✅ 使用环境变量而非硬编码
- ✅ 定期更换密钥

## 🧪 验证配置

### 检查配置文件

```bash
# 查看当前配置（隐藏密码）
cat backend/.env | grep -v PASSWORD | grep -v SECRET
```

### 测试数据库连接

```bash
# 使用psql测试
PGPASSWORD=$DB_PASSWORD psql \
  -h $DB_HOST \
  -p $DB_PORT \
  -U $DB_USER \
  -d $DB_NAME \
  -c "SELECT 1;"
```

### 验证后端启动

```bash
# 启动后端
cd backend
go run cmd/main.go

# 健康检查
curl http://localhost:8081/health
```

## 🐛 常见问题

### Q: 数据库连接失败？
**A:** 检查：
1. PostgreSQL是否运行
2. `DB_HOST`和`DB_PORT`是否正确
3. 用户名密码是否匹配
4. 数据库是否存在

### Q: CORS错误？
**A:** 确保：
1. `CORS_ALLOWED_ORIGINS`包含前端地址
2. 地址格式正确（包含协议和端口）
3. 多个地址用逗号分隔

### Q: JWT验证失败？
**A:** 检查：
1. `JWT_SECRET`是否一致
2. Token是否过期
3. `JWT_EXPIRE_HOURS`配置

## 📚 相关文档

- [系统设计文档](DESIGN.md)
- [API集成指南](API_INTEGRATION_GUIDE.md)
- [K8s部署指南](K8S_DEPLOYMENT_GUIDE.md)

---

最后更新：2025-10-11
