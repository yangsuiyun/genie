# 🔄 数据持久化策略

> 数据同步机制和持久化时机说明

## 📋 概述

本项目采用**乐观更新 + 后台同步**的数据持久化策略，确保：
- 🚀 **即时响应** - 用户操作立即生效
- 🔄 **数据同步** - 后台自动同步到服务器
- 💾 **离线支持** - 网络故障时保留本地更改
- ⚡ **容错恢复** - 业务错误时智能回滚

## 🎯 核心原则

### 1. 持久化时机

| 操作类型 | 本地更新 | API调用 | 失败处理 |
|---------|---------|---------|---------|
| **创建** | 立即 | 立即 | 回滚/保留 |
| **更新** | 立即 | 立即 | 回滚/保留 |
| **删除** | 立即 | 立即 | 恢复/保留 |
| **加载** | 缓存优先 | 后台刷新 | 使用缓存 |

### 2. 错误处理策略

```
┌─────────────┐
│  操作失败   │
└──────┬──────┘
       │
    判断错误类型
       │
   ┌───┴───┐
   │       │
网络错误  业务错误
   │       │
保留更改  回滚状态
   │       │
待同步队列 提示用户
```

## 🏗️ 实现架构

### 乐观更新流程

```
用户操作
  ↓
1. 立即更新本地UI
  ↓
2. 保存到本地缓存
  ↓
3. 调用后端API
  ↓
┌─────────┴─────────┐
│                   │
成功               失败
│                   │
更新真实ID      判断错误类型
│              ┌─────┴─────┐
保存到缓存    网络错误  业务错误
              │          │
            保留更改    回滚状态
              │          │
            标记待同步  提示错误
```

### 数据加载策略

```
应用启动
  ↓
1. 加载本地缓存
  ↓
2. 显示UI（快速响应）
  ↓
3. 请求服务器最新数据
  ↓
┌─────────┴─────────┐
│                   │
成功               失败
│                   │
更新UI和缓存    继续使用缓存
```

## 📝 代码实现

### 创建操作模板

```dart
Future<void> create(...params) async {
  // 生成临时ID
  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final entity = Entity(id: tempId, ...params);
  
  // 乐观更新
  state = [...state, entity];
  await cache.save(state);
  
  try {
    // API调用
    final saved = await api.create(entity);
    
    // 更新真实ID
    state = state.map((e) => e.id == tempId ? saved : e).toList();
    await cache.save(state);
    
  } on NetworkException {
    // 网络错误：保留本地更改
    print('离线模式：待网络恢复后同步');
    
  } catch (e) {
    // 业务错误：回滚
    state = state.where((e) => e.id != tempId).toList();
    await cache.save(state);
    rethrow;
  }
}
```

### 更新操作模板

```dart
Future<void> update(String id, ...params) async {
  // 保存旧状态
  final oldState = state;
  
  // 乐观更新
  state = state.map((e) => e.id == id ? e.copyWith(...params) : e).toList();
  await cache.save(state);
  
  try {
    // API调用
    await api.update(id, state.firstWhere((e) => e.id == id));
    
  } on NetworkException {
    // 网络错误：保留更改
    print('离线模式');
    
  } catch (e) {
    // 业务错误：回滚
    state = oldState;
    await cache.save(state);
    rethrow;
  }
}
```

### 删除操作模板

```dart
Future<void> delete(String id) async {
  // 保存旧状态
  final oldState = state;
  
  // 乐观删除
  state = state.where((e) => e.id != id).toList();
  await cache.save(state);
  
  try {
    // API调用
    await api.delete(id);
    
  } on NetworkException {
    // 网络错误：保持删除状态
    print('离线模式：删除将在同步后生效');
    
  } catch (e) {
    // 业务错误：恢复
    state = oldState;
    await cache.save(state);
    rethrow;
  }
}
```

### 加载操作模板

```dart
Future<void> load() async {
  try {
    // 1. 加载缓存
    final cached = await cache.load();
    if (cached.isNotEmpty) {
      state = cached;
    }
    
    // 2. 请求服务器
    final entities = await api.getAll();
    
    // 3. 更新状态和缓存
    state = entities;
    await cache.save(entities);
    
  } catch (e) {
    // 失败时使用缓存
    print('加载失败: $e');
  }
}
```

## 🔍 实际应用示例

### 示例1：创建任务

```
用户输入 "完成项目文档"
  ↓
本地立即显示新任务（临时ID: temp_1234567890）
  ↓
调用 POST /api/tasks
  ↓
成功：任务ID更新为 task_xyz123
  ↓
用户看到任务已创建（无感知）
```

### 示例2：网络故障场景

```
用户完成任务（点击勾选框）
  ↓
本地立即显示为已完成 ✓
  ↓
调用 PUT /api/tasks/123 → 网络错误
  ↓
保留本地已完成状态
  ↓
控制台提示："离线模式"
  ↓
网络恢复后，下次启动自动同步
```

### 示例3：业务错误场景

```
用户删除不存在的任务
  ↓
本地立即从列表移除
  ↓
调用 DELETE /api/tasks/999 → 404错误
  ↓
回滚：任务重新出现在列表
  ↓
提示："删除失败：任务不存在"
```

## 📊 持久化决策树

```
需要持久化数据？
  │
  ├─ 关键数据（项目/任务/会话）
  │    └→ 立即持久化
  │        ├─ 本地：立即
  │        └─ 后端：立即
  │
  ├─ 频繁变化（计时器状态）
  │    └→ 批量持久化
  │        ├─ 本地：立即
  │        └─ 后端：完成时
  │
  └─ 临时数据（UI状态）
       └→ 不持久化
           └─ 仅内存
```

## 🔐 数据一致性保证

### 冲突解决策略

当本地和服务器数据冲突时：

| 场景 | 策略 | 依据 |
|------|------|------|
| 同一字段不同值 | Last Write Wins | updated_at时间戳 |
| 本地有，服务器无 | 上传到服务器 | 离线创建的数据 |
| 服务器有，本地无 | 下载到本地 | 其他设备创建 |
| 都已删除 | 忽略 | 已同步 |

### 事务完整性

```dart
// 保证原子性操作
Future<void> completeTaskWithPomodoro(String taskId) async {
  final oldState = state;
  
  try {
    // 1. 更新任务状态
    await updateTask(taskId, isCompleted: true);
    
    // 2. 增加番茄钟计数
    await incrementPomodoroCount(taskId);
    
    // 3. 创建会话记录
    await createPomodoroSession(taskId);
    
  } catch (e) {
    // 任何步骤失败，回滚所有更改
    state = oldState;
    rethrow;
  }
}
```

## 🚀 性能优化

### 1. 批量操作

```dart
// 批量创建任务
Future<void> batchCreate(List<Task> tasks) async {
  // 本地立即全部添加
  state = [...state, ...tasks];
  await cache.save(state);
  
  // 后端批量API（更高效）
  await api.batchCreate(tasks);
}
```

### 2. 增量同步

```dart
// 只同步变更数据
Future<void> incrementalSync() async {
  final lastSync = await cache.getLastSyncTime();
  
  // 只获取lastSync之后的变更
  final changes = await api.getChangesSince(lastSync);
  
  // 应用变更
  applyChanges(changes);
  
  // 更新同步时间
  await cache.setLastSyncTime(DateTime.now());
}
```

### 3. 请求去重

```dart
// 防止重复请求
final _pendingRequests = <String, Future>{};

Future<T> deduplicateRequest<T>(String key, Future<T> Function() request) async {
  if (_pendingRequests.containsKey(key)) {
    return await _pendingRequests[key] as T;
  }
  
  final future = request();
  _pendingRequests[key] = future;
  
  try {
    return await future;
  } finally {
    _pendingRequests.remove(key);
  }
}
```

## 📈 监控指标

建议监控以下指标：

| 指标 | 说明 | 目标值 |
|------|------|--------|
| 同步成功率 | 成功同步请求/总请求 | >99% |
| 同步延迟 | 操作到同步完成的时间 | <500ms |
| 冲突率 | 发生冲突的操作比例 | <1% |
| 离线队列大小 | 待同步的操作数量 | <10 |
| 缓存命中率 | 从缓存加载的比例 | >80% |

## 📚 相关文档

- [API集成指南](API_INTEGRATION_GUIDE.md) - 详细的API集成方法
- [系统设计文档](DESIGN.md) - 整体架构设计
- [后端API文档](backend/docs/README.md) - API接口说明

---

最后更新：2025-10-11
