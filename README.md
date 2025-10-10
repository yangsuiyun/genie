# 🍅 Pomodoro Genie

一个基于番茄工作法的任务与时间管理应用，支持Web、移动端和桌面平台。

## 📚 文档导航

### 🎯 快速入口
- **[📖 文档索引](docs/INDEX.md)** - 完整的文档索引和快速查找
- **[📖 文档总览](docs/overview/DOCUMENTATION.md)** - 文档导航和分类

### 🏗️ 核心文档
- **[🏗️ 架构说明](ARCHITECTURE.md)** - 技术架构和设计模式
- **[🌐 平台指南](PLATFORM_GUIDE.md)** - 跨平台使用说明
- **[🤖 开发配置](CLAUDE.md)** - Claude开发指南和命令速查

### 📖 详细指南
- **[💻 开发指南](docs/development/DEVELOPMENT_GUIDE.md)** - 技术栈、项目结构、开发流程
- **[🚀 部署指南](docs/deployment/DEPLOYMENT_GUIDE.md)** - 通用部署指南
  - [Docker部署](docs/deployment/DOCKER_DEPLOYMENT_GUIDE.md) - 容器化部署详解
  - [macOS部署](docs/deployment/MACBOOK_DEPLOYMENT_GUIDE.md) - macOS生产环境部署
- **[📡 API文档](docs/api/API_DOCUMENTATION.md)** - 完整的API接口文档

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

### 访问应用
- **本地访问**: http://localhost:3001
- **网络访问**: http://[你的IP]:3001
- **API接口**: http://[你的IP]:8081

## 📊 项目状态

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

## 🏗️ 技术栈

### 前端
- **Flutter 3.24.3** - 跨平台移动应用开发
- **Dart 3.5+** - 主要编程语言
- **Riverpod** - 状态管理
- **Hive** - 本地数据存储

### 后端
- **Go 1.21+** - 高性能API服务
- **Gin** - Web框架
- **PostgreSQL 15** - 主数据库
- **Redis 7** - 缓存服务

### 部署
- **Docker** - 容器化部署
- **Nginx** - 反向代理和静态文件服务
- **Let's Encrypt** - SSL证书

## 📁 项目结构

```
pomodoro-genie/
├── docs/                    # 📚 整理后的文档
│   ├── overview/            # 文档总览
│   ├── development/         # 开发指南
│   ├── deployment/          # 部署指南
│   └── api/                 # API文档
├── backend/                 # Go后端API
├── mobile/                  # Flutter应用
├── docker-compose.yml       # 开发环境配置
├── start-pomodoro.sh        # 一键启动脚本
└── README.md                # 项目说明
```

## 🔧 开发命令

```bash
# 快速启动
bash start-pomodoro.sh

# 停止服务
bash stop-pomodoro.sh

# 开发环境
docker-compose up -d
cd backend && go run main.go
cd mobile && flutter run -d web-server --web-port 3001 --web-hostname 0.0.0.0
```

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支: `git checkout -b feature/AmazingFeature`
3. 提交更改: `git commit -m 'Add some AmazingFeature'`
4. 推送到分支: `git push origin feature/AmazingFeature`
5. 提交Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看[LICENSE](LICENSE)文件了解详情

---

**开始你的高效工作之旅！** 🚀