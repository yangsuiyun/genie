import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
// 假设 Project 和 DataService 已经定义

/// 带API集成的项目Provider示例
/// 
/// 这个文件展示如何修改现有的 ProjectNotifier 来集成后端API调用

class ProjectNotifierWithApi extends StateNotifier<List<Project>> {
  final ApiService _apiService;
  
  ProjectNotifierWithApi(this._apiService) : super([]) {
    _loadProjects();
  }
  
  /// 加载项目列表
  /// 策略：先显示缓存，再从服务器更新
  Future<void> _loadProjects() async {
    try {
      // 1. 先加载本地缓存（快速显示UI）
      final cachedProjects = await DataService.loadProjects();
      if (cachedProjects.isNotEmpty) {
        state = cachedProjects;
      }
      
      // 2. 从服务器获取最新数据
      final serverData = await _apiService.getProjects();
      final serverProjects = serverData
          .map((json) => Project.fromJson(json))
          .toList();
      
      // 3. 更新状态和缓存
      state = serverProjects;
      await DataService.saveProjects(serverProjects);
      
    } catch (e) {
      print('加载项目失败: $e');
      
      // 如果服务器请求失败但有缓存，继续使用缓存
      if (state.isEmpty) {
        // 初始化默认项目
        state = _getDefaultProjects();
        await DataService.saveProjects(state);
      }
    }
  }
  
  /// 添加项目 - 使用乐观更新策略
  Future<void> addProject(String name) async {
    // 1. 生成临时ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // 2. 创建临时项目对象
    final tempProject = Project(
      id: tempId,
      name: name,
      icon: '📁',
      color: '#6c757d',
      createdAt: DateTime.now(),
    );
    
    // 3. 乐观更新：立即更新UI
    state = [...state, tempProject];
    await DataService.saveProjects(state);
    
    try {
      // 4. 调用后端API
      final response = await _apiService.createProject(tempProject.toJson());
      final savedProject = Project.fromJson(response);
      
      // 5. 用服务器返回的真实ID替换临时ID
      state = state.map((p) => p.id == tempId ? savedProject : p).toList();
      await DataService.saveProjects(state);
      
    } catch (e) {
      print('创建项目失败: $e');
      
      if (e is NetworkException) {
        // 网络错误：保持本地更改，标记为待同步
        // TODO: 添加到同步队列
        print('离线模式：项目已保存到本地，将在网络恢复后同步');
      } else {
        // 其他错误：回滚更改
        state = state.where((p) => p.id != tempId).toList();
        await DataService.saveProjects(state);
        
        // 通知用户错误
        rethrow; // 让UI层处理错误显示
      }
    }
  }
  
  /// 更新项目
  Future<void> updateProject(String id, String name) async {
    // 1. 保存旧状态（用于回滚）
    final oldState = state;
    
    // 2. 乐观更新
    state = state.map((project) {
      if (project.id == id) {
        return Project(
          id: project.id,
          name: name,
          icon: project.icon,
          color: project.color,
          createdAt: project.createdAt,
        );
      }
      return project;
    }).toList();
    await DataService.saveProjects(state);
    
    try {
      // 3. 调用后端API
      final updatedProject = state.firstWhere((p) => p.id == id);
      final response = await _apiService.updateProject(id, updatedProject.toJson());
      final serverProject = Project.fromJson(response);
      
      // 4. 用服务器返回的数据更新
      state = state.map((p) => p.id == id ? serverProject : p).toList();
      await DataService.saveProjects(state);
      
    } catch (e) {
      print('更新项目失败: $e');
      
      if (e is NetworkException) {
        // 网络错误：保持本地更改
        print('离线模式：更改已保存到本地');
      } else {
        // 其他错误：回滚
        state = oldState;
        await DataService.saveProjects(state);
        rethrow;
      }
    }
  }
  
  /// 删除项目
  Future<void> deleteProject(String id) async {
    // 1. 保存旧状态
    final oldState = state;
    final deletedProject = state.firstWhere((p) => p.id == id);
    
    // 2. 乐观删除
    state = state.where((project) => project.id != id).toList();
    await DataService.saveProjects(state);
    
    try {
      // 3. 调用后端API
      await _apiService.deleteProject(id);
      
    } catch (e) {
      print('删除项目失败: $e');
      
      if (e is NetworkException) {
        // 网络错误：保持删除状态，标记为待同步
        print('离线模式：删除将在网络恢复后同步');
      } else {
        // 其他错误：恢复项目
        state = oldState;
        await DataService.saveProjects(state);
        rethrow;
      }
    }
  }
  
  /// 手动刷新项目列表
  Future<void> refresh() async {
    await _loadProjects();
  }
  
  /// 获取默认项目
  List<Project> _getDefaultProjects() {
    return [
      Project(
        id: 'inbox',
        name: 'Inbox',
        icon: '📥',
        color: '#6c757d',
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'work',
        name: 'Work',
        icon: '💼',
        color: '#007bff',
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'personal',
        name: 'Personal',
        icon: '🏠',
        color: '#28a745',
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'study',
        name: 'Study',
        icon: '📚',
        color: '#ffc107',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

/// 任务Provider示例
class TaskNotifierWithApi extends StateNotifier<List<Task>> {
  final ApiService _apiService;
  
  TaskNotifierWithApi(this._apiService) : super([]) {
    _loadTasks();
  }
  
  Future<void> _loadTasks() async {
    try {
      // 1. 加载缓存
      final cachedTasks = await DataService.loadTasks();
      if (cachedTasks.isNotEmpty) {
        state = cachedTasks;
      }
      
      // 2. 从服务器获取
      final serverData = await _apiService.getTasks();
      final serverTasks = serverData.map((json) => Task.fromJson(json)).toList();
      
      // 3. 更新状态
      state = serverTasks;
      await DataService.saveTasks(serverTasks);
      
    } catch (e) {
      print('加载任务失败: $e');
      // 失败时使用缓存
    }
  }
  
  /// 添加任务
  Future<void> addTask(
    String title,
    String description,
    TaskPriority priority,
    String projectId,
    int plannedPomodoros,
    DateTime? dueDate,
  ) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    final tempTask = Task(
      id: tempId,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      priority: priority,
      projectId: projectId,
      plannedPomodoros: plannedPomodoros,
      dueDate: dueDate,
    );
    
    // 乐观更新
    state = [...state, tempTask];
    await DataService.saveTasks(state);
    
    try {
      // 调用API
      final response = await _apiService.createTask(tempTask.toJson());
      final savedTask = Task.fromJson(response);
      
      // 更新为真实ID
      state = state.map((t) => t.id == tempId ? savedTask : t).toList();
      await DataService.saveTasks(state);
      
    } catch (e) {
      print('创建任务失败: $e');
      
      if (e is! NetworkException) {
        // 非网络错误：回滚
        state = state.where((t) => t.id != tempId).toList();
        await DataService.saveTasks(state);
        rethrow;
      }
    }
  }
  
  /// 切换任务完成状态
  Future<void> toggleTask(String id) async {
    final oldState = state;
    
    // 乐观更新
    state = state.map((task) {
      if (task.id == id) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();
    await DataService.saveTasks(state);
    
    try {
      // 调用API
      final updatedTask = state.firstWhere((t) => t.id == id);
      await _apiService.updateTask(id, updatedTask.toJson());
      
    } catch (e) {
      print('更新任务状态失败: $e');
      
      if (e is! NetworkException) {
        // 回滚
        state = oldState;
        await DataService.saveTasks(state);
        rethrow;
      }
    }
  }
  
  /// 更新任务
  Future<void> updateTask(Task updatedTask) async {
    final oldState = state;
    
    // 乐观更新
    state = state.map((task) {
      if (task.id == updatedTask.id) {
        return updatedTask;
      }
      return task;
    }).toList();
    await DataService.saveTasks(state);
    
    try {
      // 调用API
      final response = await _apiService.updateTask(
        updatedTask.id,
        updatedTask.toJson(),
      );
      final serverTask = Task.fromJson(response);
      
      // 用服务器数据更新
      state = state.map((t) => t.id == serverTask.id ? serverTask : t).toList();
      await DataService.saveTasks(state);
      
    } catch (e) {
      print('更新任务失败: $e');
      
      if (e is! NetworkException) {
        state = oldState;
        await DataService.saveTasks(state);
        rethrow;
      }
    }
  }
  
  /// 删除任务
  Future<void> deleteTask(String id) async {
    final oldState = state;
    
    // 乐观删除
    state = state.where((task) => task.id != id).toList();
    await DataService.saveTasks(state);
    
    try {
      // 调用API
      await _apiService.deleteTask(id);
      
    } catch (e) {
      print('删除任务失败: $e');
      
      if (e is! NetworkException) {
        state = oldState;
        await DataService.saveTasks(state);
        rethrow;
      }
    }
  }
  
  /// 增加番茄钟计数
  Future<void> incrementPomodoroCount(String taskId) async {
    final oldState = state;
    
    // 乐观更新
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(completedPomodoros: task.completedPomodoros + 1);
      }
      return task;
    }).toList();
    await DataService.saveTasks(state);
    
    try {
      // 调用API
      final updatedTask = state.firstWhere((t) => t.id == taskId);
      await _apiService.updateTask(taskId, updatedTask.toJson());
      
    } catch (e) {
      print('更新番茄钟计数失败: $e');
      
      if (e is! NetworkException) {
        state = oldState;
        await DataService.saveTasks(state);
      }
    }
  }
  
  /// 手动刷新
  Future<void> refresh() async {
    await _loadTasks();
  }
}

/// Provider定义示例
/// 使用时需要在main.dart中替换现有的projectsProvider和tasksProvider

// final projectsProviderWithApi = StateNotifierProvider<ProjectNotifierWithApi, List<Project>>((ref) {
//   return ProjectNotifierWithApi(apiService);
// });

// final tasksProviderWithApi = StateNotifierProvider<TaskNotifierWithApi, List<Task>>((ref) {
//   return TaskNotifierWithApi(apiService);
// });

