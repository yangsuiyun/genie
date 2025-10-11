# ☸️ Kubernetes部署指南

> Pomodoro Genie在Kubernetes上的部署方案

## 📋 概述

本指南介绍如何将Pomodoro Genie部署到Kubernetes集群。

## 🎯 架构设计

```
        Internet
            ↓
    ┌──────────────┐
    │   Ingress    │ ← 入口控制器
    └───────┬──────┘
            ↓
    ┌──────────────┐
    │   Service    │ ← 负载均衡
    └───────┬──────┘
            ↓
┌───────────┴───────────┐
│                       │
Deployment          Deployment
Frontend (Nginx)    Backend (Go)
│                       │
└───────────┬───────────┘
            ↓
    ┌──────────────┐
    │  StatefulSet │ ← PostgreSQL
    │   + PVC      │
    └──────────────┘
```

## 📦 资源清单

项目包含以下K8s配置文件：

```
k8s/
├── secrets.yaml              # 敏感信息（密码、密钥）
├── postgres-deployment.yaml  # PostgreSQL数据库
├── backend-deployment.yaml   # Go后端服务
├── frontend-deployment.yaml  # Nginx前端服务
└── ingress.yaml             # Ingress路由规则
```

## 🚀 快速部署

### 前置条件

- Kubernetes集群（v1.24+）
- kubectl已配置
- Ingress控制器已安装

### 一键部署

```bash
# 部署所有资源
./deploy-k8s.sh

# 或手动部署
kubectl apply -f k8s/
```

### 查看部署状态

```bash
# 查看所有Pod
kubectl get pods

# 查看服务
kubectl get services

# 查看Ingress
kubectl get ingress
```

## 🔧 配置说明

### 1. Secrets (敏感信息)

`k8s/secrets.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pomodoro-secrets
type: Opaque
stringData:
  db-password: "your-db-password"      # 数据库密码
  jwt-secret: "your-jwt-secret"        # JWT密钥
```

**⚠️ 重要：**
- 生产环境必须修改默认密码
- 使用base64编码或stringData
- 不要提交到Git

### 2. PostgreSQL

`k8s/postgres-deployment.yaml`:

```yaml
# StatefulSet确保数据持久化
kind: StatefulSet
spec:
  replicas: 1
  volumeClaimTemplates:
    - spec:
        resources:
          requests:
            storage: 20Gi  # 存储大小
```

**特点：**
- StatefulSet保证稳定的网络标识
- PVC自动创建和绑定
- 数据持久化存储

### 3. 后端服务

`k8s/backend-deployment.yaml`:

```yaml
kind: Deployment
spec:
  replicas: 2  # 副本数
  resources:
    limits:
      cpu: "1"
      memory: "512Mi"
    requests:
      cpu: "100m"
      memory: "256Mi"
```

**配置说明：**
- 2个副本提供高可用
- 资源限制防止过度使用
- 健康检查确保服务可用

### 4. 前端服务

`k8s/frontend-deployment.yaml`:

```yaml
kind: Deployment
spec:
  replicas: 2  # 副本数
  resources:
    limits:
      cpu: "500m"
      memory: "256Mi"
```

**特点：**
- Nginx服务静态文件
- 2个副本负载均衡
- 自动重启故障Pod

### 5. Ingress

`k8s/ingress.yaml`:

```yaml
spec:
  rules:
    - host: pomodoro.example.com
      http:
        paths:
          - path: /api
            backend:
              service:
                name: pomodoro-backend
          - path: /
            backend:
              service:
                name: pomodoro-frontend
```

**说明：**
- `/api/*` 路由到后端
- `/` 路由到前端
- 支持多域名配置

## 🔄 更新部署

### 更新镜像

```bash
# 更新后端
kubectl set image deployment/pomodoro-backend \
  backend=your-registry/pomodoro-backend:v2

# 更新前端
kubectl set image deployment/pomodoro-frontend \
  frontend=your-registry/pomodoro-frontend:v2
```

### 滚动更新

```bash
# 查看更新状态
kubectl rollout status deployment/pomodoro-backend

# 回滚到上一版本
kubectl rollout undo deployment/pomodoro-backend

# 查看历史
kubectl rollout history deployment/pomodoro-backend
```

## 📊 监控和日志

### 查看日志

```bash
# 查看后端日志
kubectl logs -f deployment/pomodoro-backend

# 查看前端日志
kubectl logs -f deployment/pomodoro-frontend

# 查看PostgreSQL日志
kubectl logs -f statefulset/pomodoro-postgres
```

### 进入容器

```bash
# 进入后端容器
kubectl exec -it deployment/pomodoro-backend -- sh

# 进入数据库
kubectl exec -it statefulset/pomodoro-postgres -- psql -U postgres
```

## 🔍 故障排查

### Pod无法启动

```bash
# 查看Pod详情
kubectl describe pod <pod-name>

# 查看事件
kubectl get events --sort-by='.lastTimestamp'
```

### 服务不可达

```bash
# 测试Service
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# 在容器内
wget -O- http://pomodoro-backend:8081/health
```

### 数据库连接问题

```bash
# 检查Secret
kubectl get secret pomodoro-secrets -o yaml

# 测试数据库连接
kubectl run -it --rm psql --image=postgres:15 --restart=Never -- \
  psql -h pomodoro-postgres -U postgres
```

## 📈 扩缩容

### 手动扩容

```bash
# 扩容后端到3个副本
kubectl scale deployment/pomodoro-backend --replicas=3

# 扩容前端到5个副本
kubectl scale deployment/pomodoro-frontend --replicas=5
```

### 自动扩容（HPA）

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pomodoro-backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pomodoro-backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## 🔒 安全加固

### 1. 网络策略

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: pomodoro-network-policy
spec:
  podSelector:
    matchLabels:
      app: pomodoro-backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: pomodoro-frontend
      ports:
        - protocol: TCP
          port: 8081
```

### 2. RBAC

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pomodoro-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pomodoro-role
rules:
  - apiGroups: [""]
    resources: ["secrets", "configmaps"]
    verbs: ["get", "list"]
```

### 3. Pod安全策略

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: true
```

## 📚 最佳实践

1. **使用命名空间隔离环境**
   ```bash
   kubectl create namespace pomodoro-prod
   kubectl apply -f k8s/ -n pomodoro-prod
   ```

2. **配置资源限制**
   - 防止单个Pod耗尽资源
   - 确保QoS为Guaranteed

3. **启用健康检查**
   - Liveness Probe：检测Pod是否健康
   - Readiness Probe：检测Pod是否就绪

4. **使用持久化存储**
   - StatefulSet + PVC
   - 定期备份数据

5. **配置监控告警**
   - Prometheus采集指标
   - Grafana可视化
   - AlertManager告警

## 🔗 相关资源

- [Kubernetes官方文档](https://kubernetes.io/docs/)
- [系统设计文档](DESIGN.md)
- [环境配置指南](ENVIRONMENT_CONFIG_GUIDE.md)

---

最后更新：2025-10-11
