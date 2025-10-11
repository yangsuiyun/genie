# 🔌 API集成指南

## 当前问题

现在的代码只使用 `SharedPreferences` 保存数据到本地，**完全没有调用后端API**，导致：
- ❌ 数据只在当前设备存在
- ❌ 多设备间无法同步
- ❌ 数据在不同会话间不一致
- ❌ 无法实现协作功能

## 解决方案概览

### 第一步：添加依赖

在 `mobile/pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  shared_preferences: ^2.2.0
  http: ^1.1.0  # ← 添加这个依赖
```

运行：
```bash
cd mobile
flutter pub get
```

### 第二步：使用提供的文件

我已经创建了以下文件：

1. **`mobile/lib/services/api_service.dart`** - API服务类
2. **`mobile/lib/providers/project_provider_with_api.dart`** - 带API集成的Provider示例

### 第三步：修改现有代码

#### 方案A：快速集成（推荐）

直接修改 `mobile/lib/main.dart` 中的 `ProjectNotifier` 和 `TaskNotifier`：

```dart
// 在 main.dart 顶部添加导入
import 'services/api_service.dart';

// 修改 ProjectNotifier 的 addProject 方法
class ProjectNotifier extends StateNotifier<List<Project>> {
  // ... 其他代码保持不变 ...
  
  Future<void> addProject(String name) async {
    // 1. 生成临时ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // 2. 创建项目对象
    final project = Project(
      id: tempId,
      name: name,
      icon: '📁',
      color: '#6c757d',
      createdAt: DateTime.now(),
    );
    
    // 3. 立即更新UI（乐观更新）
    state = [...state, project];
    await DataService.saveProjects(state);
    
    try {
      // 4. 调用后端API ← 新增这部分
      final response = await apiService.createProject(project.toJson());
      final savedProject = Project.fromJson(response);
      
      // 5. 用服务器返回的真实ID更新
      state = state.map((p) => p.id == tempId ? savedProject : p).toList();
      await DataService.saveProjects(state);
      
    } catch (e) {
      print('创建项目失败: $e');
      if (e is! NetworkException) {
        // 非网络错误：回滚更改
        state = state.where((p) => p.id != tempId).toList();
        await DataService.saveProjects(state);
      }
      // 网络错误：保持本地更改，等待后续同步
    }
  }
  
  // 类似地修改 updateProject 和 deleteProject
}
```

#### 方案B：完全替换（更好的架构）

1. 将 `project_provider_with_api.dart` 中的代码复制到 `main.dart`
2. 替换现有的 `ProjectNotifier` 和 `TaskNotifier`
3. 确保导入了 `api_service.dart`

### 第四步：配置API基础URL

根据你的环境修改 `api_service.dart` 中的 `baseUrl`：

```dart
// 本地开发
static const String baseUrl = 'http://localhost:8081/api';

// Docker环境
// static const String baseUrl = 'http://pomodoro-backend:8081/api';

// 生产环境
// static const String baseUrl = 'https://your-domain.com/api';
```

### 第五步：测试集成

#### 测试清单

- [ ] 启动后端服务：`docker-compose up -d`
- [ ] 验证后端运行：`curl http://localhost:8081/health`
- [ ] 启动前端：`cd mobile && flutter run`
- [ ] 测试创建项目
- [ ] 测试创建任务
- [ ] 测试更新任务
- [ ] 测试删除操作
- [ ] 检查后端日志：`docker logs pomodoro-backend`

#### 测试创建项目

```bash
# 在前端创建项目后，检查后端数据
curl http://localhost:8081/api/projects
```

应该能看到刚创建的项目。

#### 测试创建任务

```bash
# 在前端创建任务后，检查后端数据
curl http://localhost:8081/api/tasks
```

## 关键修改点总结

### 需要修改的方法（按优先级）

#### 高优先级 ⭐⭐⭐（必须立即修改）

1. **ProjectNotifier**
   - `addProject()` - 添加 API 调用
   - `updateProject()` - 添加 API 调用
   - `deleteProject()` - 添加 API 调用
   - `_loadProjects()` - 从服务器加载数据

2. **TaskNotifier**
   - `addTask()` - 添加 API 调用
   - `updateTask()` - 添加 API 调用
   - `deleteTask()` - 添加 API 调用
   - `toggleTask()` - 添加 API 调用
   - `_loadTasks()` - 从服务器加载数据

#### 中优先级 ⭐⭐（重要）

3. **TimerNotifier**
   - 番茄钟开始时调用 `apiService.startPomodoroSession()`
   - 番茄钟完成时调用 `apiService.completePomodoroSession()`
   - 更新任务的番茄钟计数

#### 低优先级 ⭐（可选）

4. **统计和报表**
   - 从服务器获取统计数据
   - 实现数据同步

## 代码修改模板

### 创建操作模板

```dart
Future<void> createEntity(...params) async {
  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final entity = Entity(id: tempId, ...);
  
  // 乐观更新
  state = [...state, entity];
  await saveToCache(state);
  
  try {
    // API调用
    final response = await apiService.create(entity.toJson());
    final saved = Entity.fromJson(response);
    
    // 更新真实ID
    state = state.map((e) => e.id == tempId ? saved : e).toList();
    await saveToCache(state);
    
  } catch (e) {
    if (e is! NetworkException) {
      // 非网络错误：回滚
      state = state.where((e) => e.id != tempId).toList();
      await saveToCache(state);
      rethrow;
    }
    // 网络错误：保持本地更改
  }
}
```

### 更新操作模板

```dart
Future<void> updateEntity(String id, ...params) async {
  final oldState = state;
  
  // 乐观更新
  state = state.map((e) {
    if (e.id == id) {
      return e.copyWith(...params);
    }
    return e;
  }).toList();
  await saveToCache(state);
  
  try {
    // API调用
    final updated = state.firstWhere((e) => e.id == id);
    await apiService.update(id, updated.toJson());
    
  } catch (e) {
    if (e is! NetworkException) {
      // 回滚
      state = oldState;
      await saveToCache(state);
      rethrow;
    }
  }
}
```

### 删除操作模板

```dart
Future<void> deleteEntity(String id) async {
  final oldState = state;
  
  // 乐观删除
  state = state.where((e) => e.id != id).toList();
  await saveToCache(state);
  
  try {
    // API调用
    await apiService.delete(id);
    
  } catch (e) {
    if (e is! NetworkException) {
      // 恢复
      state = oldState;
      await saveToCache(state);
      rethrow;
    }
  }
}
```

### 加载操作模板

```dart
Future<void> _loadEntities() async {
  try {
    // 1. 先显示缓存
    final cached = await loadFromCache();
    if (cached.isNotEmpty) {
      state = cached;
    }
    
    // 2. 从服务器获取最新
    final response = await apiService.getAll();
    final entities = response.map((json) => Entity.fromJson(json)).toList();
    
    // 3. 更新状态和缓存
    state = entities;
    await saveToCache(entities);
    
  } catch (e) {
    // 失败时使用缓存
    print('加载失败: $e');
  }
}
```

## 错误处理指南

### UI层错误显示

在调用 Provider 方法时捕获错误：

```dart
try {
  await ref.read(projectsProvider.notifier).addProject(name);
  // 成功提示
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('项目创建成功')),
  );
} catch (e) {
  // 错误提示
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('创建失败: ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### 网络状态监听

可以添加网络状态监听来优化用户体验：

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// 在UI中显示网络状态
Consumer(
  builder: (context, ref, child) {
    final connectivity = ref.watch(connectivityProvider);
    return connectivity.when(
      data: (result) => result == ConnectivityResult.none
          ? const Banner(
              message: '离线模式',
              location: BannerLocation.topEnd,
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  },
)
```

## 测试数据同步

### 测试脚本

创建 `test_sync.sh`:

```bash
#!/bin/bash

echo "测试项目创建..."
curl -X POST http://localhost:8081/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试项目",
    "icon": "📁",
    "color": "#6c757d"
  }'

echo -e "\n\n获取所有项目..."
curl http://localhost:8081/api/projects

echo -e "\n\n测试任务创建..."
curl -X POST http://localhost:8081/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "测试任务",
    "description": "这是一个测试任务",
    "project_id": "inbox",
    "priority": "medium"
  }'

echo -e "\n\n获取所有任务..."
curl http://localhost:8081/api/tasks
```

运行：
```bash
chmod +x test_sync.sh
./test_sync.sh
```

## 下一步优化

完成基础集成后，可以考虑：

1. **离线队列** - 实现离线操作队列，网络恢复后自动同步
2. **冲突解决** - 处理多设备间的数据冲突
3. **增量同步** - 只同步变更的数据
4. **实时同步** - 使用WebSocket实现实时数据同步
5. **数据加密** - 敏感数据加密存储和传输

## 常见问题

### Q: API调用失败怎么办？
A: 使用乐观更新策略，失败时根据错误类型决定是回滚还是保留本地更改。

### Q: 如何处理临时ID？
A: 创建时使用 `temp_timestamp` 格式，收到服务器响应后替换为真实ID。

### Q: 网络错误时如何处理？
A: 保留本地更改，标记为待同步，网络恢复后自动上传。

### Q: 如何避免数据重复？
A: 使用幂等性设计，服务器端根据客户端ID去重。

## 总结

**关键要点：**
1. ✅ 所有数据操作都要调用后端API
2. ✅ 使用乐观更新提升用户体验
3. ✅ 本地缓存作为备份，不是主要数据源
4. ✅ 区分网络错误和业务错误
5. ✅ 启动时从服务器加载最新数据

**立即行动：**
1. 添加 `http` 依赖
2. 复制 `api_service.dart` 到项目
3. 修改 `ProjectNotifier.addProject()` 添加API调用
4. 测试验证
5. 逐步修改其他方法

