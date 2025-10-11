# 🍅 Pomodoro Genie Kubernetes部署指南

## 📋 概述

本指南详细说明如何将Pomodoro Genie应用部署到Kubernetes集群中，包括Docker镜像构建、K8s配置和部署流程。

## 🏗️ 架构概览

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   PostgreSQL    │
│   (Flutter Web) │────│   (Go API)      │────│   Database      │
│   Port: 80      │    │   Port: 8081    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Ingress       │
                    │   Controller    │
                    └─────────────────┘
```

## 🐳 Docker镜像构建

### 1. 构建脚本

使用提供的构建脚本：

```bash
# 构建所有镜像
./build-docker.sh

# 构建并清理旧镜像
./build-docker.sh --cleanup
```

### 2. 手动构建

#### 后端镜像
```bash
cd backend
docker build -t pomodoro-genie/backend:latest .
```

#### 前端镜像
```bash
cd mobile
docker build -t pomodoro-genie/frontend:latest .
```

### 3. 镜像验证

```bash
# 查看构建的镜像
docker images | grep pomodoro-genie

# 测试镜像运行
docker run -d -p 8081:8081 pomodoro-genie/backend:latest
docker run -d -p 3001:80 pomodoro-genie/frontend:latest
```

## ☸️ Kubernetes部署

### 1. 环境要求

- Kubernetes集群 (v1.20+)
- kubectl命令行工具
- Docker镜像仓库访问权限
- Ingress Controller (推荐nginx-ingress)

### 2. 配置文件说明

#### 命名空间和密钥 (`k8s/secrets.yaml`)
- 创建`pomodoro-genie`命名空间
- PostgreSQL数据库凭据
- JWT密钥配置

#### PostgreSQL部署 (`k8s/postgres-deployment.yaml`)
- 数据库服务部署
- 持久化存储配置
- 健康检查配置

#### 后端部署 (`k8s/backend-deployment.yaml`)
- Go API服务部署
- 环境变量配置
- 资源限制和健康检查

#### 前端部署 (`k8s/frontend-deployment.yaml`)
- Flutter Web应用部署
- Nginx静态文件服务
- 资源限制配置

#### Ingress配置 (`k8s/ingress.yaml`)
- 外部访问路由
- CORS配置
- SSL重定向设置

### 3. 部署步骤

#### 使用部署脚本（推荐）
```bash
# 完整部署
./deploy-k8s.sh

# 查看部署状态
./deploy-k8s.sh --status

# 清理部署
./deploy-k8s.sh --cleanup
```

#### 手动部署
```bash
# 1. 创建命名空间和密钥
kubectl apply -f k8s/secrets.yaml

# 2. 部署PostgreSQL
kubectl apply -f k8s/postgres-deployment.yaml

# 3. 等待数据库启动
kubectl wait --for=condition=ready pod -l app=postgres -n pomodoro-genie --timeout=300s

# 4. 部署后端服务
kubectl apply -f k8s/backend-deployment.yaml

# 5. 部署前端服务
kubectl apply -f k8s/frontend-deployment.yaml

# 6. 配置Ingress
kubectl apply -f k8s/ingress.yaml
```

## 🔧 本地开发验证

### 使用Docker Compose

```bash
# 启动完整环境
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f backend
docker-compose logs -f frontend

# 停止服务
docker-compose down
```

### 访问地址

- **前端**: http://localhost:3001
- **后端API**: http://localhost:8081
- **数据库**: localhost:5432

## 🌐 生产环境配置

### 1. 镜像仓库

将镜像推送到镜像仓库：

```bash
# 标记镜像
docker tag pomodoro-genie/backend:latest your-registry/pomodoro-genie/backend:latest
docker tag pomodoro-genie/frontend:latest your-registry/pomodoro-genie/frontend:latest

# 推送镜像
docker push your-registry/pomodoro-genie/backend:latest
docker push your-registry/pomodoro-genie/frontend:latest
```

### 2. 更新K8s配置

修改部署文件中的镜像地址：

```yaml
# backend-deployment.yaml
image: your-registry/pomodoro-genie/backend:latest

# frontend-deployment.yaml  
image: your-registry/pomodoro-genie/frontend:latest
```

### 3. 环境变量配置

更新`k8s/secrets.yaml`中的生产环境配置：

```yaml
data:
  username: <base64-encoded-username>
  password: <base64-encoded-password>
  jwt-secret: <base64-encoded-jwt-secret>
```

### 4. Ingress域名配置

更新`k8s/ingress.yaml`中的域名：

```yaml
spec:
  rules:
  - host: your-domain.com  # 修改为实际域名
```

## 📊 监控和维护

### 1. 查看部署状态

```bash
# Pods状态
kubectl get pods -n pomodoro-genie

# Services状态
kubectl get services -n pomodoro-genie

# Ingress状态
kubectl get ingress -n pomodoro-genie

# PVC状态
kubectl get pvc -n pomodoro-genie
```

### 2. 查看日志

```bash
# 后端日志
kubectl logs -n pomodoro-genie -l app=pomodoro-backend

# 前端日志
kubectl logs -n pomodoro-genie -l app=pomodoro-frontend

# 数据库日志
kubectl logs -n pomodoro-genie -l app=postgres
```

### 3. 端口转发访问

```bash
# 前端访问
kubectl port-forward -n pomodoro-genie service/pomodoro-frontend-service 3001:80

# 后端API访问
kubectl port-forward -n pomodoro-genie service/pomodoro-backend-service 8081:8081
```

## 🔍 故障排除

### 1. 常见问题

#### Pod启动失败
```bash
# 查看Pod详情
kubectl describe pod <pod-name> -n pomodoro-genie

# 查看Pod日志
kubectl logs <pod-name> -n pomodoro-genie
```

#### 数据库连接问题
```bash
# 检查数据库服务
kubectl get svc postgres-service -n pomodoro-genie

# 测试数据库连接
kubectl exec -it <postgres-pod> -n pomodoro-genie -- psql -U postgres -d pomodoro_genie
```

#### Ingress访问问题
```bash
# 检查Ingress Controller
kubectl get pods -n ingress-nginx

# 检查Ingress配置
kubectl describe ingress pomodoro-genie-ingress -n pomodoro-genie
```

### 2. 网络问题解决

如果遇到Docker镜像拉取超时，可以：

1. **使用国内镜像源**：
```bash
# 配置Docker镜像加速器
# 在Docker Desktop设置中添加镜像源
```

2. **使用代理**：
```bash
# 设置Docker代理
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=http://proxy:port
```

3. **离线构建**：
```bash
# 在有网络的环境构建镜像，然后导出
docker save pomodoro-genie/backend:latest | gzip > backend.tar.gz
docker save pomodoro-genie/frontend:latest | gzip > frontend.tar.gz

# 在目标环境导入
docker load < backend.tar.gz
docker load < frontend.tar.gz
```

## 📚 相关文件

- `build-docker.sh` - Docker镜像构建脚本
- `deploy-k8s.sh` - Kubernetes部署脚本
- `docker-compose.yml` - 本地开发环境
- `k8s/` - Kubernetes配置文件目录
- `mobile/Dockerfile` - 前端Dockerfile
- `backend/Dockerfile` - 后端Dockerfile
- `docker/nginx.conf` - Nginx配置文件

## 🎯 下一步

1. **CI/CD集成**: 配置GitHub Actions或GitLab CI自动构建和部署
2. **监控告警**: 集成Prometheus和Grafana监控
3. **日志聚合**: 使用ELK或Fluentd收集日志
4. **备份策略**: 配置数据库定期备份
5. **安全加固**: 启用RBAC、网络策略等安全功能
