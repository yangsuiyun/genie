# 🍅 Pomodoro Genie

一个基于番茄工作法的任务与时间管理应用，支持Web、移动端和桌面平台。

## ✨ 功能特性

### 🍅 番茄计时器 ✅ 完全实现
- **实时倒计时** - 精确的番茄钟计时，实时更新显示
- **状态持久化** - 页面切换保持计时状态不丢失
- **自定义时长** - 灵活设置工作时间（1-60分钟）
- **完成动画** - 优美的圆形进度条动画效果
- **自动休息管理** - 工作完成后自动开始短/长休息
- **计划番茄钟** - 任务可设置预计番茄钟数量（1-50个）

### ⚙️ 全面设置系统 ✅ 完全实现
- **时间配置** - 工作时长、短休息、长休息时间可调
- **主题定制** - 5种精美主题色（番茄红、天空蓝、森林绿、薰衣草紫、活力橙）
- **自动化选项** - 自动开始休息/番茄钟功能
- **通知控制** - 推送通知和声音提醒开关
- **长休息间隔** - 可配置长休息触发间隔（2-8个番茄钟）
- **用户指南** - 内置番茄工作法教程和最佳实践
- **数据管理** - 导入/导出功能，数据备份恢复

### 📋 任务管理 ✅ 完全实现
- **任务列表** - 创建、管理和跟踪任务进度
- **优先级标记** - 高、中、低优先级可视化标识
- **完成状态** - 任务完成情况一目了然
- **任务描述** - 支持详细任务描述
- **进度追踪** - 实时显示完成番茄钟数/计划番茄钟数
- **任务删除** - 完整的任务管理功能

### 📊 数据统计 ✅ 完全实现
- **今日统计** - 完成番茄钟数、专注时间、任务数量
- **效率评分** - 基于工作表现的智能评分
- **可视化图表** - 直观的数据展示界面
- **7天趋势** - 一周内的专注时间趋势分析
- **24小时热力图** - 每日专注时间分布可视化
- **生产力洞察** - 连续专注天数、最佳工作时间分析

### 🌐 跨平台支持 ✅ 完全实现
- **Web应用** - 现代化PWA，支持添加到主屏幕
- **网络访问** - MacBook和Android设备无缝访问
- **响应式设计** - 适配各种屏幕尺寸
- **Flutter应用** - 完整的移动端应用（1927行代码）
- **独立Web版本** - 2072行自包含HTML/CSS/JS应用

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

## 📊 项目完成度

### ✅ 已完成功能 (85%)
- **前端应用**: Flutter完整实现 + 独立Web应用
- **核心功能**: 番茄钟计时器、任务管理、数据统计
- **设置系统**: 完整配置和主题系统
- **数据持久化**: localStorage + 本地服务
- **通知系统**: 声音提醒 + 桌面通知
- **响应式设计**: 移动端/桌面端适配

### 🚧 进行中功能 (10%)
- **后端集成**: PostgreSQL + Redis配置完成
- **API服务**: Go后端架构完成，待连接
- **用户认证**: JWT服务代码完成，待激活

### ⏳ 计划功能 (5%)
- **多设备同步**: 跨设备数据同步
- **移动应用构建**: Android/iOS应用构建
- **高级功能**: 重复任务、任务标签

## 🚀 快速开始

### 一键启动（推荐）

```bash
# 一键启动完整的Pomodoro Genie服务
bash start-pomodoro.sh
```

这将自动启动：
- Go API服务器（端口8081）
- Flutter Web应用（端口3001）
- 自动检测本机IP，支持跨设备访问

### 手动开发环境

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
flutter run -d web-server --web-port 3001 --web-hostname 0.0.0.0
```

### 访问应用

- **本地访问**: http://localhost:3001
- **网络访问**: http://[你的IP]:3001
- **API接口**: http://[你的IP]:8081

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
│   │   ├── main.dart       # 应用入口和核心逻辑
│   │   └── settings.dart   # 全面设置系统
│   ├── web/                # Web部署文件
│   ├── pubspec.yaml        # Flutter依赖
│   └── test/               # 测试文件
├── docker-compose.yml      # 开发环境容器配置
├── docker-compose.production.yml  # 生产环境配置
├── nginx.production.conf   # Nginx生产配置
├── Dockerfile.api          # API服务镜像
├── start-pomodoro.sh       # 一键启动脚本（推荐）
├── stop-pomodoro.sh        # 停止服务脚本
├── build-production.sh     # 生产构建脚本
├── deploy-production.sh    # 部署脚本
├── ssl-setup.sh           # SSL配置脚本
├── PLATFORM_GUIDE.md      # 跨平台使用指南
├── ARCHITECTURE.md        # 架构设计文档
└── README.md              # 项目说明
```

## 📱 应用界面

### 🍅 番茄计时器页面
- **动态圆形进度条** - 实时显示倒计时进度
- **时间显示** - 大字体MM:SS格式显示
- **智能按钮** - 开始/暂停/重置功能，动态状态提示
- **主题适配** - 按钮和界面颜色随设置主题变化
- **状态指示** - 专注中/准备工作的动态提示信息

### ⚙️ 全功能设置页面
- **时间设置** - 滚轮选择器，工作/休息时长1-60分钟可调
- **主题选择** - 5种精美颜色主题，实时预览效果
- **自动化控制** - 自动开始休息/番茄钟的智能切换
- **通知管理** - 推送通知和声音提醒的独立开关
- **高级设置** - 长休息间隔可配置（2-8个番茄钟）
- **用户指南** - 内置番茄工作法完整教程
- **应用信息** - 版本信息、意见反馈、重置功能

### 📋 任务管理页面
- **任务卡片** - 现代化Material Design卡片布局
- **优先级标签** - 彩色标签标识高/中/低优先级
- **完成状态** - 复选框交互，划线显示已完成任务
- **详细描述** - 任务标题和详细描述双层信息

### 📊 统计报告页面
- **数据卡片** - 美观的统计卡片，图标+数值展示
- **实时数据** - 今日完成番茄钟数、专注时间、任务完成数
- **效率评分** - 基于表现的智能评分系统
- **彩色图标** - 不同类型数据用不同颜色区分

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