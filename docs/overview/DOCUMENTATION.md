# 📚 Pomodoro Genie 文档导航

## 🎯 文档概览

Pomodoro Genie 是一个基于番茄工作法的任务与时间管理应用，支持Web、移动端和桌面平台。本文档导航帮助您快速找到所需的信息。

## 📖 文档分类

### 🚀 快速开始
- **[README.md](./README.md)** - 项目总览、功能特性、快速启动指南
- **[PLATFORM_GUIDE.md](./PLATFORM_GUIDE.md)** - 跨平台使用指南（Web、MacBook、Android）

### 🏗️ 技术架构
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - 完整技术架构说明
  - 前端应用架构（Flutter、Web）
  - 后端服务架构（Go、PostgreSQL、Redis）
  - 数据流和同步机制
  - 安全架构和性能优化

### 💻 开发指南
- **[CLAUDE.md](./CLAUDE.md)** - 开发指南和实现状态
  - 技术栈和项目结构
  - 实现进度（85%完成）
  - 开发命令和测试
  - 下一步开发计划

- **[docs/backend-integration.md](./docs/backend-integration.md)** - 后端集成映射
  - API端点映射
  - 前端组件集成
  - 数据流模式
  - 错误处理策略

- **[backend/INTEGRATION_GUIDE.md](./backend/INTEGRATION_GUIDE.md)** - 项目管理系统集成
  - TDD实现方法
  - 数据库设计
  - API接口规范
  - 部署说明

### 🚀 部署指南
- **[DOCKER_DEPLOYMENT_GUIDE.md](./DOCKER_DEPLOYMENT_GUIDE.md)** - Docker容器化部署
  - 生产环境架构
  - 一键部署脚本
  - 服务管理
  - 监控和维护

- **[MACBOOK_DEPLOYMENT_GUIDE.md](./MACBOOK_DEPLOYMENT_GUIDE.md)** - macOS生产环境部署
  - Flutter Web应用部署
  - macOS原生应用打包
  - 系统服务管理
  - 性能优化

### 📡 API文档
- **[backend/docs/README.md](./backend/docs/README.md)** - API文档说明
  - API功能特性
  - 认证和授权
  - 使用示例
  - SDK和客户端库

- **[backend/docs/swagger.yaml](./backend/docs/swagger.yaml)** - OpenAPI 3.0规范
  - 完整的API端点定义
  - 请求/响应格式
  - 数据模型定义

### 🧪 测试文档
- **[mobile/test/e2e/README.md](./mobile/test/e2e/README.md)** - 端到端测试
- **[mobile/test/timer/README.md](./mobile/test/timer/README.md)** - 计时器测试
- **[backend/tests/performance/README.md](./backend/tests/performance/README.md)** - 性能测试
- **[backend/tests/manual/README.md](./backend/tests/manual/README.md)** - 手动测试

## 🎯 按使用场景导航

### 👨‍💻 开发者
1. 阅读 [README.md](./README.md) 了解项目概览
2. 查看 [ARCHITECTURE.md](./ARCHITECTURE.md) 理解技术架构
3. 参考 [CLAUDE.md](./CLAUDE.md) 进行开发
4. 使用 [docs/backend-integration.md](./docs/backend-integration.md) 进行前后端集成

### 🚀 运维人员
1. 选择部署方式：
   - Docker部署：[DOCKER_DEPLOYMENT_GUIDE.md](./DOCKER_DEPLOYMENT_GUIDE.md)
   - macOS部署：[MACBOOK_DEPLOYMENT_GUIDE.md](./MACBOOK_DEPLOYMENT_GUIDE.md)
2. 参考 [PLATFORM_GUIDE.md](./PLATFORM_GUIDE.md) 了解平台支持

### 📱 用户
1. 查看 [PLATFORM_GUIDE.md](./PLATFORM_GUIDE.md) 了解如何使用
2. 参考 [README.md](./README.md) 了解功能特性

### 🔧 API集成
1. 阅读 [backend/docs/README.md](./backend/docs/README.md) 了解API
2. 查看 [backend/docs/swagger.yaml](./backend/docs/swagger.yaml) 获取详细规范
3. 参考 [docs/backend-integration.md](./docs/backend-integration.md) 进行集成

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

## 🔗 相关链接

- **GitHub仓库**: [项目地址]
- **在线演示**: [演示地址]
- **API文档**: [API文档地址]
- **问题反馈**: [Issues页面]

## 📝 文档维护

- **最后更新**: 2025-01-07
- **维护者**: Pomodoro Genie 开发团队
- **更新频率**: 随项目开发进度更新

---

**💡 提示**: 如果您是第一次接触本项目，建议从 [README.md](./README.md) 开始阅读，然后根据您的角色选择相应的文档进行深入了解。
