# 🍅 Pomodoro Genie 数据持久化策略

## 问题分析

当前的实现存在以下问题：
- ❌ 只使用 `SharedPreferences` 本地存储
- ❌ 没有调用后端API进行数据持久化
- ❌ 不同设备数据不一致
- ❌ 无法实现多端同步

## 数据持久化时机

### 1. 立即持久化（Immediate Persistence）

**适用场景：** 关键数据操作，需要立即保存到后端

#### 项目（Project）操作
- ✅ **创建项目** - `addProject()` 
  - 本地：立即更新 state
  - 后端：立即调用 `POST /api/projects`
  - 失败处理：显示错误，回滚本地状态

- ✅ **更新项目** - `updateProject()`
  - 本地：立即更新 state
  - 后端：立即调用 `PUT /api/projects/{id}`
  - 失败处理：显示错误，回滚本地状态

- ✅ **删除项目** - `deleteProject()`
  - 本地：立即更新 state
  - 后端：立即调用 `DELETE /api/projects/{id}`
  - 失败处理：显示错误，回滚本地状态

#### 任务（Task）操作
- ✅ **创建任务** - `addTask()`
  - 本地：立即更新 state
  - 后端：立即调用 `POST /api/tasks`
  - 失败处理：显示错误，回滚本地状态

- ✅ **更新任务** - `updateTask()`
  - 本地：立即更新 state
  - 后端：立即调用 `PUT /api/tasks/{id}`
  - 失败处理：显示错误，回滚本地状态

- ✅ **删除任务** - `deleteTask()`
  - 本地：立即更新 state
  - 后端：立即调用 `DELETE /api/tasks/{id}`
  - 失败处理：显示错误，回滚本地状态

- ✅ **完成/取消任务** - `toggleTask()`
  - 本地：立即更新 state
  - 后端：立即调用 `PUT /api/tasks/{id}`
  - 失败处理：显示错误，回滚本地状态

### 2. 批量持久化（Batch Persistence）

**适用场景：** 频繁变化的数据，可以延迟同步

#### Pomodoro会话
- ⏱️ **开始会话** - 立即创建
  - 本地：记录开始时间
  - 后端：调用 `POST /api/pomodoro/start`

- ⏱️ **完成会话** - 立即更新
  - 本地：记录结束时间和统计
  - 后端：调用 `POST /api/pomodoro/complete`
  - 同时更新任务的番茄钟计数

- ⏸️ **暂停/恢复** - 可以延迟
  - 本地：立即更新状态
  - 后端：在会话完成时一次性上传

### 3. 定时同步（Periodic Sync）

**适用场景：** 数据同步和冲突解决

- 🔄 **启动时同步**
  - 从后端拉取最新数据
  - 合并本地待同步的数据
  - 解决冲突（使用时间戳策略）

- 🔄 **后台定时同步**
  - 每5分钟检查待同步数据
  - 批量上传本地更改
  - 下载服务器更新

- 🔄 **网络恢复时同步**
  - 监听网络状态变化
  - 网络恢复后立即同步

## 实现策略

### 架构设计

```
┌─────────────────┐
│   UI Layer      │
│  (Widgets)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ State Layer     │
│ (Providers)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│ Service Layer   │────▶│ API Service  │
│ (DataService)   │     │ (Backend)    │
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐
│ Cache Layer     │
│(SharedPreferences)│
└─────────────────┘
```

### 关键组件

#### 1. API Service
```dart
class ApiService {
  final String baseUrl;
  final http.Client client;
  
  // Projects
  Future<Project> createProject(Project project);
  Future<Project> updateProject(String id, Project project);
  Future<void> deleteProject(String id);
  Future<List<Project>> getProjects();
  
  // Tasks
  Future<Task> createTask(Task task);
  Future<Task> updateTask(String id, Task task);
  Future<void> deleteTask(String id);
  Future<List<Task>> getTasks({String? projectId});
  
  // Pomodoro
  Future<PomodoroSession> startSession(String taskId);
  Future<PomodoroSession> completeSession(String sessionId, int duration);
}
```

#### 2. Sync Service
```dart
class SyncService {
  // 同步状态
  Future<void> syncAll();
  Future<void> syncProjects();
  Future<void> syncTasks();
  
  // 冲突解决
  Future<void> resolveConflicts();
  
  // 离线队列
  Future<void> addToSyncQueue(SyncOperation operation);
  Future<void> processSyncQueue();
}
```

#### 3. Offline Queue
```dart
class SyncQueue {
  // 待同步操作队列
  List<SyncOperation> _queue = [];
  
  void add(SyncOperation op);
  Future<void> process();
  void clear();
}

class SyncOperation {
  final String type; // 'create', 'update', 'delete'
  final String entity; // 'project', 'task', 'session'
  final String id;
  final Map<String, dynamic> data;
  final DateTime timestamp;
}
```

## 数据流示例

### 创建任务的完整流程

```dart
Future<void> addTask(...) async {
  try {
    // 1. 生成临时ID（客户端ID）
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // 2. 立即更新本地状态（乐观更新）
    final task = Task(id: tempId, ...);
    state = [...state, task];
    
    // 3. 保存到本地缓存
    await DataService.saveTasks(state);
    
    // 4. 调用后端API
    final savedTask = await ApiService.createTask(task);
    
    // 5. 用后端返回的真实ID更新本地
    state = state.map((t) => t.id == tempId ? savedTask : t).toList();
    await DataService.saveTasks(state);
    
  } catch (e) {
    // 6. 失败处理
    if (isNetworkError(e)) {
      // 网络错误：加入同步队列
      await SyncQueue.add(SyncOperation(
        type: 'create',
        entity: 'task',
        data: task.toJson(),
      ));
    } else {
      // 其他错误：回滚并通知用户
      state = state.where((t) => t.id != tempId).toList();
      showError('创建任务失败');
    }
  }
}
```

## 错误处理策略

### 1. 网络错误
- ✅ 操作加入离线队列
- ✅ 本地状态保持
- ✅ 显示"离线模式"提示
- ✅ 网络恢复后自动同步

### 2. 服务器错误
- ❌ 回滚本地状态
- ❌ 显示错误信息
- ❌ 允许用户重试

### 3. 冲突错误
- 🔄 下载最新服务器数据
- 🔄 应用冲突解决策略
- 🔄 重新提交本地更改

## 冲突解决策略

### 策略1：Last Write Wins（最后写入获胜）
- 比较 `updated_at` 时间戳
- 保留最新的版本
- 简单但可能丢失数据

### 策略2：Three-Way Merge（三方合并）
- 比较服务器版本、本地版本、基础版本
- 合并非冲突字段
- 冲突字段提示用户选择

### 推荐策略
- **项目/任务元数据**：Last Write Wins
- **任务完成状态**：优先服务器版本
- **番茄钟计数**：求和合并

## 性能优化

### 1. 请求合并
```dart
// 批量更新多个任务
Future<void> batchUpdateTasks(List<Task> tasks) async {
  await ApiService.batchUpdate('/api/tasks/batch', tasks);
}
```

### 2. 增量同步
```dart
// 只同步自上次同步后的更改
Future<void> incrementalSync(DateTime lastSync) async {
  final changes = await ApiService.getChanges(since: lastSync);
  await applyChanges(changes);
}
```

### 3. 数据压缩
```dart
// 使用 gzip 压缩大量数据传输
final compressed = gzip.encode(json.encode(data));
```

## 实现优先级

### Phase 1: 基础同步 ⭐⭐⭐
1. ✅ 创建 ApiService
2. ✅ 项目的 CRUD 调用后端
3. ✅ 任务的 CRUD 调用后端
4. ✅ 基础错误处理

### Phase 2: 离线支持 ⭐⭐
1. ✅ 实现 SyncQueue
2. ✅ 网络状态监听
3. ✅ 离线操作队列
4. ✅ 自动重试机制

### Phase 3: 高级功能 ⭐
1. ✅ 冲突检测和解决
2. ✅ 增量同步
3. ✅ 批量操作优化
4. ✅ 数据预加载

## 测试要点

### 单元测试
- ✅ API调用成功
- ✅ API调用失败
- ✅ 离线队列逻辑
- ✅ 冲突解决逻辑

### 集成测试
- ✅ 创建-读取-更新-删除流程
- ✅ 离线模式切换
- ✅ 网络恢复后同步
- ✅ 多设备并发操作

### 场景测试
- ✅ 飞行模式下操作
- ✅ 网络切换（WiFi ↔ 蜂窝）
- ✅ 慢速网络
- ✅ 服务器维护

## 监控指标

- 📊 同步成功率
- 📊 同步延迟
- 📊 冲突发生率
- 📊 离线队列大小
- 📊 API响应时间

## 总结

**关键原则：**
1. **用户体验优先** - 乐观更新，立即响应
2. **数据一致性** - 最终一致性模型
3. **容错性** - 离线可用，自动恢复
4. **性能** - 批量操作，增量同步

**实现建议：**
- 先实现基础的立即持久化（Phase 1）
- 再添加离线支持（Phase 2）
- 最后优化高级功能（Phase 3）

