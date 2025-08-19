# Genie - 全栈应用

一个采用最佳实践的全栈应用项目，包含前端、后端和完整的开发工具链。

## 🚀 特性

- 🎯 **现代化架构**: 前后端分离，RESTful API
- 📱 **响应式设计**: 支持多种设备和屏幕尺寸
- 🔒 **安全性**: 身份验证、授权和数据验证
- 🧪 **测试覆盖**: 单元测试和集成测试
- 🔧 **开发工具**: ESLint、Prettier、TypeScript
- 🚀 **CI/CD**: 自动化构建、测试和部署

## 📁 项目结构

```
genie/
├── frontend/           # 前端应用
│   ├── src/
│   │   ├── components/ # React 组件
│   │   ├── pages/      # 页面组件
│   │   ├── hooks/      # 自定义 Hook
│   │   ├── utils/      # 工具函数
│   │   ├── assets/     # 静态资源
│   │   └── styles/     # 样式文件
│   └── public/         # 公共资源
├── backend/            # 后端 API
│   ├── src/
│   │   ├── controllers/# 控制器
│   │   ├── models/     # 数据模型
│   │   ├── routes/     # 路由配置
│   │   ├── middleware/ # 中间件
│   │   ├── services/   # 业务逻辑
│   │   ├── utils/      # 工具函数
│   │   └── config/     # 配置文件
│   └── tests/          # 后端测试
├── docs/               # 项目文档
├── api-docs/           # API 文档
├── tests/              # 测试文件
├── scripts/            # 构建脚本
├── config/             # 配置文件
└── .github/workflows/  # GitHub Actions
```

## 🛠️ 技术栈

### 前端
- **React 18** - UI 框架
- **TypeScript** - 类型安全
- **Vite** - 构建工具
- **Tailwind CSS** - 样式框架
- **React Router** - 路由管理
- **Zustand/Redux** - 状态管理

### 后端
- **Node.js** - 运行时环境
- **Express.js** - Web 框架
- **TypeScript** - 类型安全
- **PostgreSQL/MongoDB** - 数据库
- **Prisma/Mongoose** - ORM/ODM
- **JWT** - 身份验证

### 开发工具
- **ESLint** - 代码检查
- **Prettier** - 代码格式化
- **Husky** - Git 钩子
- **Jest** - 测试框架
- **GitHub Actions** - CI/CD

## 🚀 快速开始

### 环境要求
- Node.js >= 18.0.0
- npm >= 8.0.0
- PostgreSQL >= 13 (或 MongoDB >= 5.0)

### 安装依赖
```bash
# 安装所有依赖
npm run install:all

# 或者分别安装
npm install
cd frontend && npm install
cd ../backend && npm install
```

### 环境配置
1. 复制环境变量文件
```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

2. 配置数据库连接和其他环境变量

### 启动开发服务器
```bash
# 同时启动前端和后端
npm run dev

# 或者分别启动
npm run dev:frontend  # 前端: http://localhost:3000
npm run dev:backend   # 后端: http://localhost:5000
```

## 📝 开发指南

### 代码规范
- 使用 TypeScript
- 遵循 ESLint 规则
- 使用 Prettier 格式化代码
- 组件命名使用 PascalCase
- 文件命名使用 kebab-case

### 提交规范
使用约定式提交 (Conventional Commits):
```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建过程或辅助工具的变动
```

### 测试
```bash
# 运行所有测试
npm test

# 运行前端测试
npm run test:frontend

# 运行后端测试
npm run test:backend

# 测试覆盖率
npm run test:coverage
```

### 构建
```bash
# 构建生产版本
npm run build

# 分别构建
npm run build:frontend
npm run build:backend
```

## 📚 文档

- [API 文档](./api-docs/README.md)
- [前端开发指南](./docs/frontend.md)
- [后端开发指南](./docs/backend.md)
- [部署指南](./docs/deployment.md)

## 🤝 贡献

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)

## 📞 联系方式

- 作者: Your Name
- 邮箱: your.email@example.com
- 项目链接: [https://github.com/yourusername/genie](https://github.com/yourusername/genie)
