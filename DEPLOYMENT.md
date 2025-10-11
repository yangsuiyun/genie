# 🚀 部署指南

> Docker和Kubernetes完整部署方案

## 📋 目录

- [Docker部署](#docker部署) - 本地开发和测试
- [Kubernetes部署](#kubernetes部署) - 生产环境
- [环境配置](#环境配置) - 配置说明
- [故障排查](#故障排查) - 常见问题

---

## 🐳 Docker部署

### 快速开始

```bash
# 1. 启动所有服务
docker-compose up -d

# 2. 验证服务
curl http://localhost:8081/health  # 后端
curl http://localhost:3001         # 前端

# 3. 查看日志
docker-compose logs -f

# 4. 停止服务
docker-compose down
```

### 服务说明

| 服务 | 端口 | 说明 |
|------|------|------|
| pomodoro-frontend | 3001 | Flutter Web (Nginx) |
| pomodoro-backend | 8081 | Go API服务 |
| pomodoro-postgres | 5432 | PostgreSQL数据库 |

### 构建自定义镜像

```bash
# 前端镜像
docker build -t pomodoro-frontend:latest ./mobile

# 后端镜像
docker build -t pomodoro-backend:latest ./backend

# 使用自定义镜像
docker-compose up -d
```

### 数据持久化

数据存储在Docker Volume中：

```bash
# 查看Volume
docker volume ls

# 备份数据
docker run --rm \
  -v genie_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz /data

# 恢复数据
docker run --rm \
  -v genie_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-backup.tar.gz -C /
```

---

## ☸️ Kubernetes部署

### 架构

```
Ingress (路由)
  ↓
Service (负载均衡)
  ↓
Deployment (应用实例)
  ├── Frontend Pods (2副本)
  ├── Backend Pods (2副本)
  └── PostgreSQL StatefulSet (1副本 + PVC)
```

### 快速部署

```bash
# 1. 修改Secret
vim k8s/secrets.yaml

# 2. 部署所有资源
kubectl apply -f k8s/

# 3. 查看状态
kubectl get pods
kubectl get services
kubectl get ingress

# 4. 查看日志
kubectl logs -f deployment/pomodoro-backend
```

### 配置文件

```
k8s/
├── secrets.yaml              # 密码和密钥
├── postgres-deployment.yaml  # 数据库
├── backend-deployment.yaml   # 后端服务
├── frontend-deployment.yaml  # 前端服务
└── ingress.yaml             # 路由规则
```

### Secrets配置

**⚠️ 生产环境必须修改:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pomodoro-secrets
type: Opaque
stringData:
  db-password: "your-strong-password"  # 修改这里
  jwt-secret: "your-jwt-secret"        # 修改这里
```

### 资源配置

**后端服务:**
```yaml
resources:
  limits:
    cpu: "1"
    memory: "512Mi"
  requests:
    cpu: "100m"
    memory: "256Mi"
```

**前端服务:**
```yaml
resources:
  limits:
    cpu: "500m"
    memory: "256Mi"
  requests:
    cpu: "50m"
    memory: "128Mi"
```

**PostgreSQL:**
```yaml
resources:
  requests:
    storage: 20Gi  # 存储大小
```

### 更新应用

```bash
# 更新镜像
kubectl set image deployment/pomodoro-backend \
  backend=your-registry/pomodoro-backend:v2

# 查看更新进度
kubectl rollout status deployment/pomodoro-backend

# 回滚到上一版本
kubectl rollout undo deployment/pomodoro-backend

# 查看历史版本
kubectl rollout history deployment/pomodoro-backend
```

### 扩缩容

```bash
# 手动扩容
kubectl scale deployment/pomodoro-backend --replicas=3

# 自动扩容 (HPA)
kubectl autoscale deployment/pomodoro-backend \
  --min=2 --max=10 --cpu-percent=70

# 查看HPA状态
kubectl get hpa
```

### Ingress配置

```yaml
spec:
  rules:
    - host: pomodoro.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: pomodoro-backend
                port:
                  number: 8081
          - path: /
            pathType: Prefix
            backend:
              service:
                name: pomodoro-frontend
                port:
                  number: 80
```

**DNS配置:**
```bash
# 获取Ingress IP
kubectl get ingress

# 配置DNS
pomodoro.example.com  A  <INGRESS-IP>
```

---

## ⚙️ 环境配置

### 后端环境变量

创建 `backend/.env` 文件：

```bash
# 服务器配置
PORT=8081
GIN_MODE=release

# 数据库配置
DB_HOST=localhost              # Docker: postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres           # 生产环境修改
DB_NAME=pomodoro_genie
DB_SSLMODE=disable            # 生产环境: require

# JWT配置
JWT_SECRET=change-in-production  # 生产环境修改
JWT_EXPIRE_HOURS=24

# CORS配置
CORS_ALLOWED_ORIGINS=http://localhost:3001

# 日志配置
DB_LOG_LEVEL=info
```

### Docker环境变量

在 `docker-compose.yml` 中：

```yaml
services:
  backend:
    environment:
      PORT: 8081
      DB_HOST: postgres        # Docker服务名
      DB_PASSWORD: ${DB_PASSWORD:-postgres}
      JWT_SECRET: ${JWT_SECRET:-default-secret}
```

### K8s环境变量

使用ConfigMap和Secret：

```yaml
# ConfigMap (非敏感信息)
apiVersion: v1
kind: ConfigMap
metadata:
  name: pomodoro-config
data:
  PORT: "8081"
  GIN_MODE: "release"
  DB_HOST: "pomodoro-postgres"

---
# Secret (敏感信息)
apiVersion: v1
kind: Secret
metadata:
  name: pomodoro-secrets
stringData:
  DB_PASSWORD: "your-password"
  JWT_SECRET: "your-secret"
```

### 安全建议

**JWT密钥生成:**
```bash
# 生成强密钥
openssl rand -base64 64
```

**数据库密码:**
```bash
# 生成随机密码
openssl rand -base64 32
```

**生产环境检查清单:**
- [ ] 修改JWT_SECRET
- [ ] 修改DB_PASSWORD
- [ ] 启用DB_SSLMODE=require
- [ ] 配置正确的CORS_ALLOWED_ORIGINS
- [ ] 使用HTTPS
- [ ] 定期备份数据库

---

## 🔍 故障排查

### Docker故障

**服务无法启动:**
```bash
# 检查容器状态
docker-compose ps

# 查看详细日志
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres

# 重启服务
docker-compose restart

# 完全重建
docker-compose down
docker-compose up -d --build
```

**端口被占用:**
```bash
# 查找占用进程
lsof -i :8081
lsof -i :3001

# 杀死进程
kill -9 <PID>

# 或修改docker-compose.yml中的端口
```

**数据库连接失败:**
```bash
# 测试数据库连接
docker exec -it pomodoro-postgres \
  psql -U postgres -d pomodoro_genie

# 检查密码
docker exec -it pomodoro-backend env | grep DB_
```

### Kubernetes故障

**Pod无法启动:**
```bash
# 查看Pod状态
kubectl get pods

# 查看详细信息
kubectl describe pod <pod-name>

# 查看日志
kubectl logs <pod-name>

# 查看前一个容器日志（如果重启过）
kubectl logs <pod-name> --previous

# 进入容器调试
kubectl exec -it <pod-name> -- sh
```

**常见问题:**

| 状态 | 原因 | 解决方案 |
|------|------|---------|
| ImagePullBackOff | 镜像拉取失败 | 检查镜像名称和权限 |
| CrashLoopBackOff | 容器启动失败 | 查看日志，检查配置 |
| Pending | 资源不足 | 增加节点或降低资源请求 |
| Error | 配置错误 | 检查环境变量和Secret |

**服务不可达:**
```bash
# 测试Service
kubectl run -it --rm debug \
  --image=alpine --restart=Never -- sh

# 在容器内测试
wget -O- http://pomodoro-backend:8081/health

# 检查Service
kubectl get svc
kubectl describe svc pomodoro-backend

# 检查Endpoints
kubectl get endpoints
```

**Ingress问题:**
```bash
# 检查Ingress
kubectl get ingress
kubectl describe ingress pomodoro-ingress

# 检查Ingress控制器
kubectl get pods -n ingress-nginx

# 测试从集群内访问
kubectl run -it --rm curl \
  --image=curlimages/curl --restart=Never -- \
  curl http://pomodoro.example.com
```

### 数据库问题

**备份数据:**
```bash
# Docker
docker exec pomodoro-postgres \
  pg_dump -U postgres pomodoro_genie > backup.sql

# K8s
kubectl exec statefulset/pomodoro-postgres -- \
  pg_dump -U postgres pomodoro_genie > backup.sql
```

**恢复数据:**
```bash
# Docker
docker exec -i pomodoro-postgres \
  psql -U postgres pomodoro_genie < backup.sql

# K8s
kubectl exec -i statefulset/pomodoro-postgres -- \
  psql -U postgres pomodoro_genie < backup.sql
```

**检查数据:**
```bash
# 连接数据库
kubectl exec -it statefulset/pomodoro-postgres -- \
  psql -U postgres -d pomodoro_genie

# 查看表
\dt

# 查询数据
SELECT COUNT(*) FROM tasks;
SELECT COUNT(*) FROM projects;
```

### 性能优化

**Docker资源限制:**
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

**K8s资源优化:**
```yaml
# 使用ResourceQuota限制命名空间资源
apiVersion: v1
kind: ResourceQuota
metadata:
  name: pomodoro-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

---

## 📊 监控和日志

### 日志收集

**Docker:**
```bash
# 实时查看日志
docker-compose logs -f

# 查看特定服务
docker-compose logs -f backend

# 保存日志到文件
docker-compose logs > logs.txt
```

**K8s:**
```bash
# 实时查看
kubectl logs -f deployment/pomodoro-backend

# 查看所有Pod日志
kubectl logs -f -l app=pomodoro-backend

# 过滤日志
kubectl logs deployment/pomodoro-backend | grep ERROR
```

### 健康检查

**Docker:**
```bash
# 检查健康状态
curl http://localhost:8081/health
curl http://localhost:3001/

# API测试
./test-api-integration.sh
```

**K8s:**
```bash
# 检查Pod健康
kubectl get pods

# 检查服务端点
kubectl get endpoints

# 从集群内测试
kubectl run -it --rm test \
  --image=curlimages/curl --restart=Never -- \
  curl http://pomodoro-backend:8081/health
```

---

## 🔄 CI/CD集成

### GitLab CI示例

```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy

build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA ./backend
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy:
  stage: deploy
  script:
    - kubectl set image deployment/pomodoro-backend \
        backend=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

### GitHub Actions示例

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and Deploy
        run: |
          docker build -t app:latest .
          kubectl apply -f k8s/
```

---

## 📚 相关资源

- [README.md](README.md) - 项目概览
- [DESIGN.md](DESIGN.md) - 系统设计
- [Docker文档](https://docs.docker.com/)
- [Kubernetes文档](https://kubernetes.io/docs/)

---

最后更新：2025-10-11

