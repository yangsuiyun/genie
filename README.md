# 🍅 Pomodoro Genie

一个功能完整的番茄工作法应用，支持项目管理和任务跟踪。

## ✨ 功能特点

### 🎯 核心功能
- ✅ **项目管理**: 创建、编辑、删除项目，组织任务
- ✅ **任务管理**: 添加、编辑、删除、拖拽排序任务
- ✅ **番茄钟计时**: 自定义工作时间、短休息、长休息
- ✅ **自动切换**: 智能的工作-休息循环
- ✅ **设置页面**: 完整的番茄钟配置选项
- ✅ **数据持久化**: 所有数据本地保存

### 🎨 用户体验
- 📱 响应式设计，支持桌面和移动端
- 🎨 清晰的视觉层次和直观的交互
- 📊 实时数据统计和进度追踪
- 🔔 任务完成提醒

## 🚀 快速开始

### 方法一: 一键启动（推荐）
```bash
./start-all.sh
```

### 方法二: 分别启动

#### 启动前端
```bash
cd mobile
flutter pub get
flutter run -d web-server --web-port 3001
```

#### 启动后端（可选）
```bash
cd backend
go run cmd/main.go
```

## 🌐 访问应用

- **前端应用**: http://localhost:3001
- **后端API**: http://localhost:8081 (可选)

## 🏗️ 技术栈

### 前端
- **Flutter Web** - 跨平台UI框架
- **Riverpod** - 状态管理
- **SharedPreferences** - 本地数据存储

### 后端（可选）
- **Go 1.21+** - 高性能后端语言
- **Gin** - Web框架
- **PostgreSQL** - 关系型数据库

## 📁 项目结构

```
pomodoro-genie/
├── mobile/                  # Flutter前端应用
│   ├── lib/
│   │   └── main.dart       # 主应用文件（所有功能集成）
│   └── pubspec.yaml        # Flutter依赖配置
│
├── backend/                 # Go后端服务（可选）
│   ├── cmd/
│   │   └── main.go        # 后端入口
│   ├── internal/          # 内部包
│   │   ├── models/        # 数据模型
│   │   ├── handlers/      # HTTP处理器
│   │   ├── services/      # 业务逻辑
│   │   └── repositories/  # 数据访问层
│   └── migrations/        # 数据库迁移
│
├── start-all.sh            # 一键启动脚本
└── README.md               # 项目文档
```

## 💡 使用说明

### 基础操作
1. **创建项目**: 点击侧边栏的 ➕ 按钮
2. **添加任务**: 点击右上角的 ➕ 按钮
3. **编辑任务**: 点击任务上的 ✏️ 编辑按钮
4. **拖拽排序**: 长按任务卡片拖拽到新位置
5. **开始番茄钟**: 点击任务上的 ▶️ 播放按钮
6. **配置设置**: 点击底部 ⚙️ 设置标签页

### 番茄钟设置
- **工作时长**: 默认25分钟，可自定义
- **短休息**: 默认5分钟
- **长休息**: 默认15分钟
- **自动开始**: 可设置自动开始下一个番茄钟

## 📊 项目特点

### ✅ 简洁架构
- 核心代码集中在单个文件中
- 清晰的模块划分
- 易于理解和维护

### ✅ 完整功能
- 所有核心功能都已实现
- 生产环境可用
- 稳定可靠

### ✅ 开发友好
- 一键启动脚本
- 热重载支持
- 清晰的代码注释

## 🔧 开发指南

### 环境要求
- Flutter 3.0+
- Dart 3.0+
- Go 1.21+ (如果使用后端)

### 开发命令
```bash
# Flutter开发
cd mobile
flutter pub get              # 安装依赖
flutter run -d chrome        # 在Chrome中运行
flutter build web --release  # 构建生产版本

# Go后端开发
cd backend
go mod download              # 下载依赖
go run cmd/main.go          # 运行开发服务器
go build -o app cmd/main.go # 构建可执行文件
```

### 代码格式化
```bash
# Flutter
cd mobile && flutter format lib/

# Go
cd backend && go fmt ./...
```

## 📖 相关文档

- **[项目整理总结](PROJECT_CLEANUP_SUMMARY.md)** - 项目简化过程说明
- **[后端集成指南](backend/INTEGRATION_GUIDE.md)** - 后端服务集成文档

## 🤝 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📝 开发理念

这是一个**简化优先**的项目：
- 🎯 **专注核心**: 只保留必要功能
- 📦 **精简架构**: 避免过度设计
- 🚀 **快速启动**: 最小化配置
- 📖 **易于理解**: 代码即文档

## 📄 许可证

MIT License

---

**开始你的高效工作之旅！** 🚀

> 💡 提示: 这是一个精简版项目，所有核心功能都集中在 `mobile/lib/main.dart` 文件中，便于理解和维护。
