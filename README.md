# 🧞 Genie - 智能效能提升工具

> 一个专为提升工作和生活效率而设计的跨平台工具集，让你的日常任务管理更加智能化。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/go-%3E%3D1.19-blue)](https://golang.org/)
[![Vue Version](https://img.shields.io/badge/vue-3.x-green)](https://vuejs.org/)

## ✨ 功能特性

### 🍅 智能番茄钟
- **专注时间管理**：经典番茄钟工作法，25分钟专注 + 5分钟休息
- **个性化设置**：自定义工作时长、休息时长和循环次数
- **统计分析**：详细的专注时间统计和效率分析报告
- **声音提醒**：支持多种提醒音效和桌面通知
- **数据可视化**：直观的图表展示你的专注习惯

### 📋 项目管理
- **任务管理**：创建、编辑、删除和标记任务完成状态
- **项目分组**：按项目或标签组织任务，清晰的层级结构
- **优先级设置**：高、中、低优先级标记，重要任务一目了然
- **进度跟踪**：实时进度条和完成度统计
- **时间估算**：为任务设置预估时间和实际用时记录
- **团队协作**：支持多人协作和任务分配（规划中）

### 🌐 多终端支持
- **Web应用**：现代化的浏览器端界面
- **桌面应用**：原生桌面客户端（规划中）
- **移动端**：响应式设计，完美适配移动设备
- **数据同步**：云端同步，多设备无缝切换

## 🛠 技术栈

### 后端
- **Go 1.19+**：高性能的后端API服务
- **Gin**：轻量级Web框架
- **GORM**：优雅的ORM库
- **PostgreSQL**：主数据库
- **Redis**：缓存和会话存储
- **JWT**：安全的用户认证

### 前端
- **Vue 3**：渐进式JavaScript框架
- **TypeScript**：类型安全的开发体验
- **Vite**：快速的构建工具
- **Pinia**：现代化的状态管理
- **Element Plus**：企业级UI组件库
- **Tailwind CSS**：实用优先的CSS框架

### 开发工具
- **Docker**：容器化部署
- **ESLint + Prettier**：代码质量和格式化
- **Vitest**：单元测试框架
- **GitHub Actions**：CI/CD自动化

## 🚀 快速开始

### 环境要求
- Go 1.19+
- Node.js 16+
- PostgreSQL 12+
- Redis 6+

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/your-username/genie.git
cd genie
```

2. **后端设置**
```bash
# 进入后端目录
cd backend

# 安装依赖
go mod download

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，配置数据库连接等信息

# 运行数据库迁移
go run cmd/migrate/main.go

# 启动后端服务
go run cmd/server/main.go
```

3. **前端设置**
```bash
# 进入前端目录
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

4. **访问应用**
打开浏览器访问 `http://localhost:3000`

## 📁 项目结构

```
genie/
├── backend/                # Go后端代码
│   ├── cmd/               # 命令行工具
│   ├── internal/          # 内部包
│   ├── pkg/               # 公共包
│   ├── migrations/        # 数据库迁移
│   └── configs/           # 配置文件
├── frontend/              # Vue前端代码
│   ├── src/
│   │   ├── components/    # 组件
│   │   ├── views/         # 页面
│   │   ├── stores/        # 状态管理
│   │   └── utils/         # 工具函数
│   └── public/            # 静态资源
├── docs/                  # 项目文档
├── scripts/               # 构建脚本
├── docker/                # Docker配置
└── README.md
```

## 🧪 测试

```bash
# 后端测试
cd backend
go test ./...

# 前端测试
cd frontend
npm run test
```

## 📖 使用指南

### 番茄钟使用
1. 设置专注时长（默认25分钟）
2. 点击开始按钮开始专注
3. 时间到后会自动提醒休息
4. 查看统计数据分析你的专注模式

### 项目管理使用
1. 创建新项目或选择现有项目
2. 添加任务并设置优先级
3. 开始工作并使用番茄钟计时
4. 标记任务完成并查看进度

## 🤝 贡献指南

我们欢迎所有形式的贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细信息。

### 开发流程
1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📝 更新日志

请查看 [CHANGELOG.md](CHANGELOG.md) 了解版本更新信息。

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 👥 作者

- **Your Name** - *初始工作* - [YourGitHub](https://github.com/yourusername)

## 🙏 致谢

- 感谢所有贡献者的支持
- 特别感谢开源社区提供的优秀工具和库

## 📞 联系我们

- 项目主页：[https://github.com/your-username/genie](https://github.com/your-username/genie)
- 问题反馈：[Issues](https://github.com/your-username/genie/issues)
- 邮箱：your-email@example.com

---

⭐️ 如果这个项目对你有帮助，请给它一个星标！