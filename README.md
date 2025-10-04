# 🍅 Pomodoro Genie

一个基于番茄工作法的任务与时间管理应用，支持Web、移动端和桌面平台。

## ✨ 功能特性

- 🍅 **番茄计时器** - 25分钟专注工作计时
- 📋 **任务管理** - 创建、管理和跟踪任务
- 📊 **数据统计** - 工作效率分析和报告
- 🔔 **智能提醒** - 休息和工作提醒
- 🌐 **多平台支持** - Web、iOS、Android、macOS、Windows
- 🔄 **数据同步** - 跨设备数据同步

## 🏗️ 技术架构

### 前端
- **Flutter** - 跨平台移动应用开发
- **Dart** - 主要编程语言
- **Riverpod** - 状态管理
- **Hive** - 本地数据存储

### 后端
- **Go** - 高性能API服务
- **Gin** - Web框架
- **PostgreSQL** - 主数据库
- **Redis** - 缓存服务

### 部署
- **Docker** - 容器化部署
- **Nginx** - 反向代理和静态文件服务
- **Let's Encrypt** - SSL证书

## 🚀 快速开始

### 开发环境

1. **启动后端服务**
```bash
# 启动数据库和缓存
docker-compose up -d

# 启动Go API服务
cd backend
go run main.go
```

2. **启动Flutter应用**
```bash
cd mobile
flutter pub get
flutter run -d chrome  # Web版本
flutter run             # 移动端
```

### 生产部署

1. **配置环境变量**
```bash
cp .env.production .env
# 编辑.env文件，设置数据库密码、JWT密钥等
```

2. **设置SSL证书**
```bash
bash ssl-setup.sh your-domain.com
```

3. **一键部署**
```bash
bash deploy-production.sh
```

## 📁 项目结构

```
pomodoro-genie/
├── backend/                 # Go后端API
│   ├── main.go             # API入口文件
│   ├── go.mod              # Go依赖管理
│   └── docs/               # API文档
├── mobile/                 # Flutter应用
│   ├── lib/                # Dart源代码
│   ├── pubspec.yaml        # Flutter依赖
│   └── test/               # 测试文件
├── docker-compose.yml      # 开发环境容器配置
├── docker-compose.production.yml  # 生产环境配置
├── nginx.production.conf   # Nginx生产配置
├── Dockerfile.api          # API服务镜像
├── build-production.sh     # 生产构建脚本
├── deploy-production.sh    # 部署脚本
├── ssl-setup.sh           # SSL配置脚本
├── start-all-services.sh  # 服务启动脚本
├── stop-all-services.sh   # 服务停止脚本
└── README.md              # 项目说明
```

## 📱 应用界面

- **🍅 番茄计时器** - 圆形进度显示，开始/暂停/重置功能
- **📋 任务列表** - 任务管理，优先级设置，完成状态跟踪
- **📊 统计报告** - 今日完成情况，专注时间，效率评分
- **⚙️ 应用设置** - 时间配置，提醒设置，主题选择

## 🔧 开发工具

### 构建命令
```bash
# 构建Flutter Web版本
cd mobile && flutter build web --release

# 构建Go API
cd backend && go build -o pomodoro-api main.go

# 构建Docker镜像
docker-compose -f docker-compose.production.yml build
```

### 测试命令
```bash
# Flutter测试
cd mobile && flutter test

# Go测试
cd backend && go test ./...

# E2E测试
cd mobile/test/e2e && bash run_tests.sh
```

## 🌐 API接口

基础URL: `http://localhost:8081/v1`

### 主要端点
- `GET /health` - 健康检查
- `GET /v1/tasks/` - 获取任务列表
- `POST /v1/tasks/` - 创建任务
- `POST /v1/pomodoro/sessions/` - 开始番茄钟会话
- `GET /v1/reports/analytics` - 获取分析数据

完整API文档: [backend/docs/swagger.yaml](backend/docs/swagger.yaml)

## 🔐 安全特性

- JWT身份认证
- HTTPS强制加密
- CORS跨域保护
- XSS/CSRF防护
- API限流保护
- 数据库查询参数化

## 📊 监控指标

生产环境提供以下监控端点：
- `/health` - 应用健康状态
- `/metrics` - Prometheus指标
- Prometheus监控: `http://localhost:9090`

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支: `git checkout -b feature/AmazingFeature`
3. 提交更改: `git commit -m 'Add some AmazingFeature'`
4. 推送到分支: `git push origin feature/AmazingFeature`
5. 提交Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看[LICENSE](LICENSE)文件了解详情

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台UI框架
- [Go](https://golang.org/) - 高效的后端开发语言
- [PostgreSQL](https://www.postgresql.org/) - 强大的关系型数据库
- [Docker](https://www.docker.com/) - 容器化平台

---

**开始你的高效工作之旅！** 🚀