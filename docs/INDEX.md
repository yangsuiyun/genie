# 📚 Pomodoro Genie 文档索引

> **最后更新**: 2025-10-10
> **文档版本**: v2.0
> **项目完成度**: 85%

## 🎯 快速导航

### 🚀 我想快速开始使用
👉 [README.md](../README.md) - 5分钟快速启动

### 💻 我想开发这个项目
👉 [CLAUDE.md](../CLAUDE.md) - 开发指南和命令速查

### 🏗️ 我想了解技术架构
👉 [ARCHITECTURE.md](../ARCHITECTURE.md) - 完整架构说明

### 🌐 我想在不同设备上使用
👉 [PLATFORM_GUIDE.md](../PLATFORM_GUIDE.md) - 跨平台指南

---

## 📂 完整文档目录

### 一、项目概览文档

#### 📖 README.md
**位置**: `/README.md`
**用途**: 项目入口、快速开始
**适合**: 所有用户
**内容**:
- ✨ 功能特性展示
- 🚀 快速启动指南
- 📊 项目状态 (85%完成)
- 🏗️ 技术栈概览
- 📁 项目结构

#### 🏗️ ARCHITECTURE.md
**位置**: `/ARCHITECTURE.md`
**用途**: 技术架构说明
**适合**: 架构师、高级开发者
**内容**:
- 🎨 系统架构图
- 🔐 安全架构
- ⚡ 性能优化
- 🔄 同步架构
- 🧪 测试策略

#### 🌐 PLATFORM_GUIDE.md
**位置**: `/PLATFORM_GUIDE.md`
**用途**: 跨平台使用指南
**适合**: 终端用户
**内容**:
- 📱 Web应用访问
- 💻 MacBook使用
- 🤖 Android访问
- 🔧 平台特性

#### 🤖 CLAUDE.md
**位置**: `/CLAUDE.md`
**用途**: Claude开发配置
**适合**: 开发人员 + AI助手
**内容**:
- 🔧 活跃技术栈
- 📁 项目结构
- 📊 实现进度 (85%)
- 🚀 基本命令
- 🎯 下一步行动

---

### 二、开发文档

#### 💻 开发指南
**位置**: `/docs/development/DEVELOPMENT_GUIDE.md`
**用途**: 完整开发指南
**适合**: 开发人员
**内容**:
- 🔧 环境搭建 (Flutter 3.24.3 + Go 1.21+)
- 📁 项目结构详解
- 🎨 代码规范
- 🔄 开发工作流
- 🐛 调试技巧
- 🧪 测试方法
- ❓ 常见问题

**快速链接**:
- [环境搭建](development/DEVELOPMENT_GUIDE.md#环境搭建)
- [项目结构](development/DEVELOPMENT_GUIDE.md#项目结构)
- [代码规范](development/DEVELOPMENT_GUIDE.md#代码规范)

#### 🔗 后端集成映射
**位置**: `/docs/backend-integration.md`
**用途**: 前后端集成指南
**适合**: 全栈开发人员
**内容**:
- 📡 API端点映射
- 🎨 前端组件集成
- 🔄 数据流模式
- ⚠️ 错误处理

#### 🏗️ 后端集成指南
**位置**: `/backend/INTEGRATION_GUIDE.md`
**用途**: 后端项目集成
**适合**: 后端开发人员
**内容**:
- 🧪 TDD实现方法
- 🗄️ 数据库设计
- 📡 API接口规范
- 🚀 部署说明

---

### 三、部署文档

#### 🚀 通用部署指南
**位置**: `/docs/deployment/DEPLOYMENT_GUIDE.md`
**用途**: 部署概览和通用步骤
**适合**: 运维人员
**内容**:
- 📋 部署前检查清单
- 🐳 Docker部署
- 💻 macOS部署
- ⚙️ 配置说明
- 🔒 安全配置
- 📊 监控维护

#### 🐳 Docker部署详解
**位置**: `/docs/deployment/DOCKER_DEPLOYMENT_GUIDE.md`
**用途**: Docker容器化部署
**适合**: DevOps工程师
**内容**:
- 🏗️ 生产环境架构
- 🚀 一键部署脚本
- 🔧 服务管理
- 📊 监控和维护
- 🐛 故障排查

#### 💻 macOS部署详解
**位置**: `/docs/deployment/MACBOOK_DEPLOYMENT_GUIDE.md`
**用途**: macOS生产环境
**适合**: macOS管理员
**内容**:
- 🌐 Flutter Web部署
- 🖥️ macOS原生应用
- ⚙️ 系统服务管理
- ⚡ 性能优化

**部署方式对比**:
| 方式 | 难度 | 适用场景 | 文档 |
|------|------|----------|------|
| 一键启动 | ⭐ | 本地开发 | [README.md](../README.md#快速开始) |
| Docker | ⭐⭐ | 生产部署 | [Docker指南](deployment/DOCKER_DEPLOYMENT_GUIDE.md) |
| macOS | ⭐⭐⭐ | macOS生产 | [macOS指南](deployment/MACBOOK_DEPLOYMENT_GUIDE.md) |

---

### 四、API文档

#### 📡 API完整文档
**位置**: `/docs/api/API_DOCUMENTATION.md`
**用途**: REST API接口文档
**适合**: API集成开发者
**内容**:
- 🔐 认证和授权 (JWT)
- 📋 任务管理API
- 🍅 番茄钟API
- 📊 报告和统计API
- 👤 用户管理API
- ⚠️ 错误代码说明

#### 📄 后端API文档
**位置**: `/backend/docs/README.md`
**用途**: 后端API详细说明
**适合**: 后端开发者
**内容**:
- 🎯 API功能特性
- 🔒 认证流程
- 📝 使用示例
- 🛠️ SDK和客户端库

#### 📋 OpenAPI规范
**位置**: `/backend/docs/swagger.yaml`
**用途**: API接口规范
**适合**: API工具和自动化
**内容**:
- 完整端点定义
- 请求/响应格式
- 数据模型Schema

**API快速查询**:
```
认证API     → /api/auth/*
任务API     → /api/tasks/*
番茄钟API   → /api/pomodoro/*
报告API     → /api/reports/*
用户API     → /api/users/*
```

---

### 五、测试文档

#### 🧪 端到端测试
**位置**: `/mobile/test/e2e/README.md`
**用途**: E2E测试指南
**内容**:
- 测试环境搭建
- 测试用例编写
- 自动化测试执行

#### ⏱️ 计时器测试
**位置**: `/mobile/test/timer/README.md`
**用途**: 计时器精度测试
**内容**:
- 计时器精度测试
- 长时间运行测试
- 性能测试

#### ⚡ 性能测试
**位置**: `/backend/tests/performance/README.md`
**用途**: 后端性能测试
**内容**:
- API性能测试
- 数据库性能测试
- 负载测试

#### 🖐️ 手动测试
**位置**: `/backend/tests/manual/README.md`
**用途**: 手动测试流程
**内容**:
- 测试用例列表
- 测试执行计划
- 问题记录

---

### 六、工作流文档

#### ⚙️ GitHub Actions
**位置**: `/.github/workflows/README.md`
**用途**: CI/CD工作流说明
**内容**:
- 自动化构建流程
- 多平台构建配置
- Release发布流程

---

### 七、文档总览

#### 📚 文档导航
**位置**: `/docs/overview/DOCUMENTATION.md`
**用途**: 文档分类导航
**适合**: 需要深入了解的用户
**内容**:
- 📖 文档分类
- 🎯 按场景导航
- 👥 按角色导航
- 📊 项目状态

#### 📄 文档摘要
**位置**: `/docs/overview/DOCUMENTATION_SUMMARY.md`
**用途**: 文档简要总结
**内容**:
- 文档概述
- 快速链接

---

## 🎯 按角色查找文档

### 👨‍💻 开发人员
**推荐阅读顺序**:
1. [README.md](../README.md) - 了解项目
2. [CLAUDE.md](../CLAUDE.md) - 开发配置
3. [ARCHITECTURE.md](../ARCHITECTURE.md) - 理解架构
4. [开发指南](development/DEVELOPMENT_GUIDE.md) - 开始开发
5. [后端集成](backend-integration.md) - 前后端联调

### 🚀 运维人员
**推荐阅读顺序**:
1. [README.md](../README.md) - 了解项目
2. [部署指南](deployment/DEPLOYMENT_GUIDE.md) - 部署概览
3. [Docker指南](deployment/DOCKER_DEPLOYMENT_GUIDE.md) 或 [macOS指南](deployment/MACBOOK_DEPLOYMENT_GUIDE.md)
4. [PLATFORM_GUIDE.md](../PLATFORM_GUIDE.md) - 平台支持

### 📱 终端用户
**推荐阅读顺序**:
1. [README.md](../README.md) - 功能介绍
2. [PLATFORM_GUIDE.md](../PLATFORM_GUIDE.md) - 使用指南

### 🔧 API集成开发者
**推荐阅读顺序**:
1. [API文档](api/API_DOCUMENTATION.md) - API概览
2. [后端API](../backend/docs/README.md) - 详细文档
3. [OpenAPI规范](../backend/docs/swagger.yaml) - 接口规范
4. [后端集成](backend-integration.md) - 集成示例

### 🏗️ 架构师
**推荐阅读顺序**:
1. [ARCHITECTURE.md](../ARCHITECTURE.md) - 技术架构
2. [CLAUDE.md](../CLAUDE.md) - 实现状态
3. [开发指南](development/DEVELOPMENT_GUIDE.md) - 技术细节
4. [部署指南](deployment/DEPLOYMENT_GUIDE.md) - 部署架构

---

## 🔍 按主题查找文档

### 🍅 番茄钟功能
- [功能特性](../README.md#功能特性) - 番茄钟完整功能
- [技术实现](../ARCHITECTURE.md#设置系统架构) - 计时器架构
- [API文档](api/API_DOCUMENTATION.md) - 番茄钟API

### 📋 任务管理
- [功能介绍](../README.md#任务管理) - 任务功能
- [数据模型](../ARCHITECTURE.md#数据模型) - 任务数据结构
- [API接口](api/API_DOCUMENTATION.md) - 任务管理API

### ⚙️ 设置系统
- [设置功能](../README.md#全面设置系统) - 设置项说明
- [设置架构](../ARCHITECTURE.md#设置系统架构) - 技术实现
- [主题系统](../ARCHITECTURE.md#主题系统架构) - 主题定制

### 📊 数据统计
- [统计功能](../README.md#数据统计) - 统计特性
- [报告API](api/API_DOCUMENTATION.md) - 报告接口

### 🚀 部署配置
- [快速部署](../README.md#快速开始) - 一键启动
- [Docker部署](deployment/DOCKER_DEPLOYMENT_GUIDE.md) - 容器化
- [macOS部署](deployment/MACBOOK_DEPLOYMENT_GUIDE.md) - macOS环境

### 🔐 安全认证
- [安全架构](../ARCHITECTURE.md#安全架构) - 安全设计
- [JWT认证](api/API_DOCUMENTATION.md) - 认证流程

---

## 📊 文档统计

### 文档总览
- **总文档数**: 20+ 个Markdown文档
- **文档总大小**: ~150KB
- **最后更新**: 2025-10-10
- **维护状态**: ✅ 活跃维护

### 文档质量
- ✅ **结构化**: 清晰的目录结构
- ✅ **分类明确**: 按功能和角色分类
- ✅ **内容完整**: 覆盖开发、部署、使用
- ✅ **更新及时**: 与代码同步更新
- ✅ **导航友好**: 多重索引和链接

### 文档覆盖率
```
核心功能文档: ████████████████████ 100%
开发指南文档: ████████████████████ 100%
部署指南文档: ████████████████████ 100%
API接口文档:  ████████████████████ 100%
测试文档:     ████████████████░░░░  80%
```

---

## 🔧 文档维护

### 文档更新流程
1. 代码功能变更
2. 更新对应文档
3. 检查相关链接
4. 更新文档索引
5. 提交变更

### 文档质量检查
```bash
# 检查死链接
find docs -name "*.md" -exec grep -l "](.*\.md)" {} \;

# 检查重复内容
grep -r "# 技术栈" --include="*.md" .

# 验证文档完整性
ls docs/overview/ docs/development/ docs/deployment/ docs/api/
```

### 贡献文档
1. Fork项目
2. 创建文档分支
3. 编写/更新文档
4. 提交Pull Request

---

## 📝 快速参考

### 常用命令
```bash
# 快速启动
bash start-pomodoro.sh

# 查看文档
ls docs/

# 搜索文档
grep -r "关键词" docs/
```

### 常用链接
- [项目仓库](https://github.com/your-repo/pomodoro-genie)
- [在线演示](https://demo.pomodoro-genie.com)
- [问题反馈](https://github.com/your-repo/pomodoro-genie/issues)

---

## 🎉 开始使用

### 第一次使用？
👉 从 [README.md](../README.md) 开始

### 开始开发？
👉 查看 [CLAUDE.md](../CLAUDE.md)

### 部署项目？
👉 参考 [部署指南](deployment/DEPLOYMENT_GUIDE.md)

### 集成API？
👉 阅读 [API文档](api/API_DOCUMENTATION.md)

---

**💡 提示**: 使用 Ctrl+F 或 Cmd+F 在本索引中搜索关键词,快速找到你需要的文档。

**📧 反馈**: 如果您发现文档问题或有改进建议,请提交 [Issue](https://github.com/your-repo/pomodoro-genie/issues)。
