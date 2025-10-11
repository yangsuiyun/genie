# 🔌 API集成指南

> 快速集成指南 - 将后端API集成到Flutter前端

## 📋 概述

本项目已完成API集成，前端所有数据操作都会同步到后端。本文档记录集成方法供参考。

## ✅ 当前状态

### 已集成的功能

- ✅ 项目CRUD - 创建、读取、更新、删除
- ✅ 任务CRUD - 创建、读取、更新、删除
- ✅ 任务状态切换 - 完成/取消
- ✅ 番茄钟计数 - 自动更新
- ✅ 启动时数据加载 - 从服务器同步
- ✅ 乐观更新策略 - 立即响应，后台同步
- ✅ 错误处理 - 网络错误与业务错误区分

## 🏗️ 架构设计

```
┌─────────────────┐
│   UI Layer      │  Widget显示和用户交互
│   (Widgets)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ State Layer     │  Riverpod状态管理
│ (Providers)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│ Service Layer   │────▶│ API Service  │  HTTP请求
│ (DataService)   │     │ (Backend)    │
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐
│ Cache Layer     │  本地缓存
│(SharedPrefs)    │
└─────────────────┘
```

## 📝 代码实现

### 1. API Service

`mobile/lib/services/api_service.dart`

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8081/api';
  
  // 项目API
  Future<List<Map<String, dynamic>>> getProjects();
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> project);
  Future<Map<String, dynamic>> updateProject(String id, Map<String, dynamic> project);
  Future<void> deleteProject(String id);
  
  // 任务API
  Future<List<Map<String, dynamic>>> getTasks({String? projectId});
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> task);
  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> task);
  Future<void> deleteTask(String id);
}
```

### 2. 乐观更新模式

所有数据操作遵循统一模式：

```dart
Future<void> addEntity(...params) async {
  // 1. 生成临时ID
  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final entity = Entity(id: tempId, ...);
  
  // 2. 乐观更新：立即更新UI
  state = [...state, entity];
  await saveToCache(state);
  
  try {
    // 3. 调用后端API
    final response = await apiService.create(entity.toJson());
    final saved = Entity.fromJson(response);
    
    // 4. 用服务器返回的真实ID更新
    state = state.map((e) => e.id == tempId ? saved : e).toList();
    await saveToCache(state);
    
  } catch (e) {
    // 5. 错误处理
    if (e is NetworkException) {
      // 网络错误：保留本地更改，标记待同步
      print('离线模式：将在网络恢复后同步');
    } else {
      // 业务错误：回滚本地状态
      state = state.where((e) => e.id != tempId).toList();
      await saveToCache(state);
      rethrow; // 让UI显示错误
    }
  }
}
```

### 3. 启动时加载

```dart
Future<void> _loadData() async {
  try {
    // 1. 先显示缓存（快速）
    final cached = await DataService.load();
    if (cached.isNotEmpty) {
      state = cached;
    }
    
    // 2. 从服务器获取最新（准确）
    final serverData = await apiService.getAll();
    final entities = serverData.map((json) => Entity.fromJson(json)).toList();
    
    // 3. 更新状态和缓存
    state = entities;
    await DataService.save(entities);
    
  } catch (e) {
    // 失败时继续使用缓存
    print('加载失败: $e');
  }
}
```

## 🔄 数据流示例

### 创建任务流程

```
1. 用户点击"创建任务"
   ↓
2. UI立即显示新任务（临时ID）
   ↓
3. 调用 POST /api/tasks
   ↓
4. 成功：用真实ID替换临时ID
   ↓
5. 失败：回滚或保留（根据错误类型）
```

### 更新任务流程

```
1. 用户修改任务状态
   ↓
2. UI立即显示新状态
   ↓
3. 调用 PUT /api/tasks/:id
   ↓
4. 成功：保持当前状态
   ↓
5. 失败：恢复旧状态，提示用户
```

## 🛠️ 关键配置

### API基础URL

在 `api_service.dart` 中配置：

```dart
// 本地开发
static const String baseUrl = 'http://localhost:8081/api';

// Docker环境
// static const String baseUrl = 'http://pomodoro-backend:8081/api';

// 生产环境
// static const String baseUrl = 'https://api.yourdomain.com/api';
```

### 依赖配置

`pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  flutter_riverpod: ^2.6.1
  shared_preferences: ^2.2.2
```

## 🧪 测试验证

### 测试脚本

```bash
# 运行API集成测试
./test-api-integration.sh
```

### 手动测试

```bash
# 1. 启动后端
docker-compose up -d

# 2. 验证API
curl http://localhost:8081/health

# 3. 启动前端
cd mobile && flutter run

# 4. 查看后端日志
docker logs -f pomodoro-backend
```

## 📊 集成清单

| 功能 | Provider | API端点 | 状态 |
|------|----------|---------|------|
| 项目列表 | ProjectNotifier._loadProjects | GET /api/projects | ✅ |
| 创建项目 | ProjectNotifier.addProject | POST /api/projects | ✅ |
| 更新项目 | ProjectNotifier.updateProject | PUT /api/projects/:id | ✅ |
| 删除项目 | ProjectNotifier.deleteProject | DELETE /api/projects/:id | ✅ |
| 任务列表 | TaskNotifier._loadTasks | GET /api/tasks | ✅ |
| 创建任务 | TaskNotifier.addTask | POST /api/tasks | ✅ |
| 更新任务 | TaskNotifier.updateTask | PUT /api/tasks/:id | ✅ |
| 切换任务 | TaskNotifier.toggleTask | PUT /api/tasks/:id | ✅ |
| 删除任务 | TaskNotifier.deleteTask | DELETE /api/tasks/:id | ✅ |
| 番茄钟计数 | TaskNotifier.incrementPomodoroCount | PUT /api/tasks/:id | ✅ |

## 🐛 常见问题

### Q: API调用失败怎么办？
**A:** 检查：
1. 后端服务是否运行：`docker-compose ps`
2. 健康检查：`curl http://localhost:8081/health`
3. 网络连接是否正常
4. API URL配置是否正确

### Q: 数据不同步？
**A:** 原因可能是：
1. 网络错误被忽略（检查控制台日志）
2. API响应格式不匹配
3. 临时ID未被替换

### Q: 如何调试API调用？
**A:** 
1. 查看Flutter控制台日志
2. 查看后端日志：`docker logs -f pomodoro-backend`
3. 使用网络抓包工具

## 📚 相关文档

- [数据持久化策略](DATA_PERSISTENCE_STRATEGY.md)
- [系统设计文档](DESIGN.md)
- [环境配置指南](ENVIRONMENT_CONFIG_GUIDE.md)

---

最后更新：2025-10-11
