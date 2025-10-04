# 🐳 Docker 环境设置指南

由于原始Supabase镜像可能无法正常拉取，我们提供了多种配置选项。

## 🚀 快速启动

### 方法1: 交互式启动 (推荐)

```bash
# 运行交互式启动脚本
./quick-start.sh
```

这会让你选择以下配置之一：
1. **简化配置** (推荐) - 使用常见镜像，功能完整
2. **原始配置** - Supabase完整栈
3. **仅数据库** - 最小化配置

### 方法2: 直接启动

```bash
# 1. 简化配置 (推荐)
docker-compose -f docker-compose.simple.yml up -d

# 2. 原始配置
docker-compose up -d

# 3. 仅数据库
docker-compose -f docker-compose.db-only.yml up -d
```

## 📋 配置对比

| 特性 | 简化配置 | 原始配置 | 仅数据库 |
|------|----------|----------|----------|
| PostgreSQL | ✅ | ✅ | ✅ |
| REST API | ✅ | ✅ | ❌ |
| 管理界面 | pgAdmin | Supabase Studio | ❌ |
| 缓存 | Redis | ❌ | ❌ |
| 反向代理 | Nginx | ❌ | ❌ |
| 实时功能 | ❌ | ✅ | ❌ |
| 镜像兼容性 | 🟢 高 | 🟡 中等 | 🟢 高 |

## 🌐 服务端口

### 简化配置
- **主页/API网关**: http://localhost:8080
- **数据库管理**: http://localhost:8080/admin
- **REST API**: http://localhost:54321
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 原始配置
- **Supabase Studio**: http://localhost:3000
- **REST API**: http://localhost:54321
- **PostgreSQL**: localhost:5432
- **Realtime**: http://localhost:4000
- **Meta API**: http://localhost:8080

### 仅数据库
- **PostgreSQL**: localhost:5432

## 🔧 管理命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 完全重置 (删除所有数据)
docker-compose down -v
```

## 🧪 测试连接

### 数据库连接测试
```bash
# 使用psql (需要安装PostgreSQL客户端)
psql -h localhost -p 5432 -U postgres -d postgres

# 或使用Docker
docker-compose exec db psql -U postgres -d postgres
```

### API测试
```bash
# 健康检查 (简化配置)
curl http://localhost:8080/health

# REST API测试
curl http://localhost:54321/

# 获取数据库schema
curl http://localhost:54321/
```

## 🔨 故障排除

### 镜像拉取失败
```bash
# 测试镜像拉取
./test-setup.sh

# 手动拉取常用镜像
docker pull postgres:15-alpine
docker pull postgrest/postgrest:v12.0.2
docker pull dpage/pgadmin4:latest
docker pull redis:7-alpine
docker pull nginx:alpine
```

### 端口冲突
```bash
# 检查端口占用
lsof -i :3000 -i :5432 -i :54321 -i :6379 -i :8080

# 停止占用端口的服务
sudo kill -9 $(lsof -t -i:端口号)
```

### 权限问题
```bash
# 添加用户到docker组
sudo usermod -aG docker $USER
newgrp docker

# 验证权限
docker ps
```

### 数据库连接问题
```bash
# 检查数据库健康状态
docker-compose exec db pg_isready -U postgres

# 查看数据库日志
docker-compose logs db

# 重置数据库
docker-compose down -v
docker-compose up -d
```

## 🔄 数据迁移

### 导入数据
```bash
# 从SQL文件导入
cat backup.sql | docker-compose exec -T db psql -U postgres -d postgres

# 从本地数据库导入
pg_dump -h localhost -U postgres mydb | docker-compose exec -T db psql -U postgres -d postgres
```

### 备份数据
```bash
# 创建备份
docker-compose exec db pg_dump -U postgres postgres > backup_$(date +%Y%m%d).sql

# 压缩备份
docker-compose exec db pg_dump -U postgres postgres | gzip > backup_$(date +%Y%m%d).sql.gz
```

## 🚀 与手动测试集成

启动服务后，更新测试配置：

```bash
# 编辑测试环境配置
nano backend/tests/manual/.env

# 设置以下值
BACKEND_URL=http://localhost:54321
DATABASE_URL=postgresql://postgres:你的密码@localhost:5432/postgres
```

然后运行测试：
```bash
cd backend/tests/manual
make validate-setup
make test-all
```

## 📝 环境变量

主要环境变量在 `.env` 文件中：

- `POSTGRES_PASSWORD` - 数据库密码
- `JWT_SECRET` - JWT签名密钥
- `REDIS_PASSWORD` - Redis密码 (简化配置)

## 🎯 推荐配置

**开发环境**: 使用简化配置
- 镜像稳定，功能完整
- 包含管理界面和缓存
- 统一的API网关

**生产环境**: 使用托管服务
- 使用云数据库 (如AWS RDS, 阿里云RDS)
- 使用Redis云服务
- 使用容器编排 (Kubernetes, Docker Swarm)

**快速测试**: 使用仅数据库配置
- 最小资源占用
- 快速启动
- 专注于数据库测试

---

选择适合你需求的配置，开始使用 Pomodoro Genie 开发环境！