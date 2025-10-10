# 🐳 Pomodoro Genie Docker 部署指南

## 📋 概述

本文档提供了使用Docker部署Pomodoro Genie完整生产环境的详细指南，包括后端API、Web前端、数据库和缓存服务的容器化部署。

## 🏗️ 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker 生产环境架构                        │
├─────────────────────────────────────────────────────────────┤
│  🌐 Nginx (80/443)                                          │
│  ├── 反向代理和负载均衡                                        │
│  ├── SSL终止                                                │
│  └── 静态文件服务                                            │
├─────────────────────────────────────────────────────────────┤
│  🖥️ Web Frontend (8080)                                    │
│  ├── Flutter Web应用                                        │
│  ├── Nginx静态文件服务                                       │
│  └── PWA支持                                                │
├─────────────────────────────────────────────────────────────┤
│  🔧 Backend API (8081)                                      │
│  ├── Go + Gin框架                                           │
│  ├── JWT认证                                                │
│  ├── RESTful API                                            │
│  └── 实时同步服务                                            │
├─────────────────────────────────────────────────────────────┤
│  🗄️ PostgreSQL (5432)                                      │
│  ├── 主数据库                                                │
│  ├── 用户数据                                                │
│  ├── 任务数据                                                │
│  └── 番茄钟会话数据                                          │
├─────────────────────────────────────────────────────────────┤
│  🚀 Redis (6379)                                            │
│  ├── 缓存服务                                                │
│  ├── 会话存储                                                │
│  ├── 频率限制                                                │
│  └── 实时同步状态                                            │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 快速开始

### 1. 系统要求

**最低要求**:
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM
- 10GB 可用磁盘空间
- 开放端口: 80, 443, 8080, 8081

**推荐配置**:
- Docker 24.0+
- Docker Compose 2.20+
- 8GB RAM
- 20GB 可用磁盘空间
- SSD存储

### 2. 一键部署

```bash
# 克隆项目
git clone https://github.com/your-username/pomodoro-genie.git
cd pomodoro-genie

# 配置环境变量
cp env.production.template .env
# 编辑 .env 文件，设置数据库密码、JWT密钥等

# 执行一键部署
chmod +x deploy-docker-production.sh
./deploy-docker-production.sh
```

### 3. 验证部署

```bash
# 检查服务状态
./manage-docker-services.sh status

# 健康检查
./manage-docker-services.sh health

# 查看日志
./manage-docker-services.sh logs
```

## 📁 文件结构

```
pomodoro-genie/
├── 🐳 Docker配置文件
│   ├── Dockerfile.backend              # 后端API镜像
│   ├── Dockerfile.web                  # Web前端镜像
│   ├── docker-compose.production.yml   # 生产环境编排
│   └── nginx-production.conf           # Nginx生产配置
├── 🚀 部署脚本
│   ├── deploy-docker-production.sh     # 一键部署脚本
│   ├── manage-docker-services.sh       # 服务管理脚本
│   └── env.production.template          # 环境变量模板
├── 📚 文档
│   ├── DOCKER_DEPLOYMENT_GUIDE.md      # 本文档
│   └── README.md                       # 项目说明
└── 🔧 应用代码
    ├── backend/                        # Go后端API
    ├── mobile/                         # Flutter应用
    └── nginx-web.conf                  # Web服务Nginx配置
```

## ⚙️ 详细配置

### 环境变量配置

复制 `env.production.template` 为 `.env` 并配置以下关键变量：

```bash
# 数据库配置
POSTGRES_DB=pomodoro_genie
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here

# Redis配置
REDIS_PASSWORD=your_redis_password_here

# JWT认证
JWT_SECRET=your_jwt_secret_key_here_must_be_very_long_and_secure
JWT_EXPIRY_LIMIT=24h

# CORS配置
CORS_ORIGINS=http://localhost:8080,https://yourdomain.com
```

### SSL证书配置

```bash
# 创建SSL目录
mkdir -p ssl

# 使用Let's Encrypt (推荐)
certbot certonly --standalone -d yourdomain.com
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem

# 或使用自签名证书 (仅用于测试)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem -out ssl/cert.pem
```

## 🔧 服务管理

### 基本操作

```bash
# 启动所有服务
./manage-docker-services.sh start

# 停止所有服务
./manage-docker-services.sh stop

# 重启所有服务
./manage-docker-services.sh restart

# 查看服务状态
./manage-docker-services.sh status

# 查看日志
./manage-docker-services.sh logs

# 实时查看日志
./manage-docker-services.sh logs-f

# 健康检查
./manage-docker-services.sh health
```

### 高级操作

```bash
# 清理未使用的资源
./manage-docker-services.sh clean

# 备份数据
./manage-docker-services.sh backup

# 恢复数据
./manage-docker-services.sh restore backups/20241201_120000

# 更新服务
./manage-docker-services.sh update
```

## 🌐 访问地址

部署完成后，您可以通过以下地址访问应用：

- **Web应用**: http://localhost:8080
- **API接口**: http://localhost:8081
- **Nginx代理**: http://localhost (HTTP) / https://localhost (HTTPS)

### API端点

- **健康检查**: `GET /health`
- **API文档**: `GET /docs`
- **认证**: `POST /v1/auth/login`
- **任务管理**: `GET /v1/tasks`
- **番茄钟**: `POST /v1/pomodoro/sessions`

## 🔍 故障排除

### 常见问题

#### 1. 服务启动失败

```bash
# 检查Docker状态
docker info

# 检查端口占用
netstat -tulpn | grep :8080
netstat -tulpn | grep :8081

# 查看详细日志
docker-compose -f docker-compose.production.yml logs
```

#### 2. 数据库连接失败

```bash
# 检查PostgreSQL状态
docker-compose -f docker-compose.production.yml exec postgres pg_isready

# 检查环境变量
docker-compose -f docker-compose.production.yml exec backend env | grep DB_

# 重启数据库服务
docker-compose -f docker-compose.production.yml restart postgres
```

#### 3. Web前端无法访问

```bash
# 检查Nginx配置
docker-compose -f docker-compose.production.yml exec nginx nginx -t

# 检查前端服务
docker-compose -f docker-compose.production.yml exec web curl localhost:8080/health

# 重新构建前端镜像
docker build -f Dockerfile.web -t pomodoro-web:latest .
```

#### 4. SSL证书问题

```bash
# 检查证书文件
ls -la ssl/

# 验证证书
openssl x509 -in ssl/cert.pem -text -noout

# 重新生成证书
certbot renew --dry-run
```

### 性能优化

#### 1. 数据库优化

```bash
# 调整PostgreSQL配置
docker-compose -f docker-compose.production.yml exec postgres \
  psql -U postgres -c "ALTER SYSTEM SET shared_buffers = '256MB';"
```

#### 2. Redis优化

```bash
# 检查Redis内存使用
docker-compose -f docker-compose.production.yml exec redis redis-cli info memory
```

#### 3. Nginx优化

```bash
# 启用gzip压缩
# 已在nginx-production.conf中配置

# 调整worker进程数
# 根据CPU核心数调整nginx配置
```

## 📊 监控和维护

### 日志管理

```bash
# 查看所有服务日志
docker-compose -f docker-compose.production.yml logs

# 查看特定服务日志
docker-compose -f docker-compose.production.yml logs backend
docker-compose -f docker-compose.production.yml logs web

# 实时监控日志
docker-compose -f docker-compose.production.yml logs -f
```

### 数据备份

```bash
# 自动备份脚本
#!/bin/bash
# 添加到crontab: 0 2 * * * /path/to/backup.sh

./manage-docker-services.sh backup
```

### 更新部署

```bash
# 拉取最新代码
git pull origin main

# 更新服务
./manage-docker-services.sh update

# 验证更新
./manage-docker-services.sh health
```

## 🔒 安全建议

1. **更改默认密码**: 修改所有默认密码
2. **配置防火墙**: 只开放必要端口
3. **使用HTTPS**: 配置SSL证书
4. **定期更新**: 保持Docker镜像更新
5. **监控日志**: 定期检查异常日志
6. **备份数据**: 定期备份重要数据

## 📞 技术支持

如果遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查GitHub Issues
3. 联系技术支持团队

---

**最后更新**: 2024-12-01  
**版本**: 1.0.0  
**维护者**: Pomodoro Genie 开发团队
