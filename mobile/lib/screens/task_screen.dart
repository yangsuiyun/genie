import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../settings.dart';
import '../main.dart'; // 导入PomodoroState

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final AppSettings _settings = AppSettings();
  final PomodoroState _pomodoroState = PomodoroState();
  late TabController _tabController;
  List<Task> _tasks = [];
  TaskStatus? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _taskService.addListener(_onTasksChanged);
    _settings.addListener(_onSettingsChanged);
    _initializeTasks();
  }

  @override
  void dispose() {
    _taskService.removeListener(_onTasksChanged);
    _settings.removeListener(_onSettingsChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTasksChanged() {
    if (mounted) {
      setState(() {
        _loadTasks();
      });
    }
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeTasks() async {
    await _taskService.initialize();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasks = _taskService.getTasksByStatus(_currentFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 我的任务'),
        backgroundColor: _settings.themeColor.shade400,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _currentFilter = null;
                  break;
                case 1:
                  _currentFilter = TaskStatus.pending;
                  break;
                case 2:
                  _currentFilter = TaskStatus.inProgress;
                  break;
                case 3:
                  _currentFilter = TaskStatus.completed;
                  break;
              }
              _loadTasks();
            });
          },
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '待开始'),
            Tab(text: '进行中'),
            Tab(text: '已完成'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 统计卡片
          _buildStatisticsCard(),
          // 任务列表
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(_taskService.getTasksByStatus(null)),
                _buildTaskList(_taskService.getTasksByStatus(TaskStatus.pending)),
                _buildTaskList(_taskService.getTasksByStatus(TaskStatus.inProgress)),
                _buildTaskList(_taskService.getTasksByStatus(TaskStatus.completed)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: _settings.themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _taskService.getStatistics();
    final overdueTasks = _taskService.getOverdueTasks().length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _settings.themeColor.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _settings.themeColor.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总计', stats.total.toString(), Icons.list_alt),
          _buildStatItem('已完成', stats.completed.toString(), Icons.check_circle),
          _buildStatItem('进行中', stats.inProgress.toString(), Icons.play_circle),
          if (overdueTasks > 0)
            _buildStatItem('过期', overdueTasks.toString(), Icons.warning, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    final itemColor = color ?? _settings.themeColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: itemColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: itemColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无任务',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击 + 按钮添加新任务',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(tasks[index]);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showTaskDetailDialog(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 任务标题和状态
              Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      _taskService.toggleTaskCompletion(task.id);
                    },
                    activeColor: _settings.themeColor,
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Text(task.priorityEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(task.statusEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  // 开始番茄钟按钮
                  if (!task.isCompleted)
                    IconButton(
                      onPressed: () => _startPomodoroForTask(task),
                      icon: const Icon(Icons.timer, size: 20),
                      tooltip: '开始番茄钟',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      iconSize: 20,
                      color: _settings.themeColor,
                    ),
                ],
              ),

              // 任务描述
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 8),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),

              // 子任务进度
              if (task.subtasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.completedSubtasks}/${task.subtasks.length} 子任务完成',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: task.progress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(_settings.themeColor),
                        ),
                      ),
                    ],
                  ),
                ),

              // 到期时间和标签
              Row(
                children: [
                  const SizedBox(width: 48),
                  // 到期时间
                  if (task.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isOverdue ? Colors.red.shade100 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: task.isOverdue ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(task.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: task.isOverdue ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 8),

                  // 标签
                  ...task.tags.take(2).map((tag) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _settings.themeColor.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: _settings.themeColor.shade700,
                      ),
                    ),
                  )),

                  if (task.tags.length > 2)
                    Text(
                      '+${task.tags.length - 2}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return '已过期 ${-difference} 天';
    } else if (difference == 0) {
      return '今天到期';
    } else if (difference == 1) {
      return '明天到期';
    } else {
      return '$difference 天后到期';
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: (task) {
          _taskService.addTask(task);
        },
      ),
    );
  }

  void _showTaskDetailDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        onTaskUpdated: (updatedTask) {
          _taskService.updateTask(updatedTask);
        },
        onTaskDeleted: () {
          _taskService.deleteTask(task.id);
        },
      ),
    );
  }

  void _startPomodoroForTask(Task task) {
    // 切换到番茄钟页面并开始计时
    if (!_pomodoroState.isRunning) {
      _pomodoroState.start(task);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已开始为"${task.title}"计时，请切换到番茄钟页面查看'),
          duration: const Duration(seconds: 3),
          backgroundColor: _settings.themeColor,
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () {
              // 这里可以添加导航逻辑，暂时先提示用户手动切换
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('番茄钟正在运行中，请先停止当前计时'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// 添加任务对话框
class AddTaskDialog extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskDialog({super.key, required this.onTaskAdded});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  final List<String> _tags = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加新任务'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '任务标题 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '任务描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: '优先级',
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_dueDate == null ? '设置到期日期' : '到期日期: ${_formatDate(_dueDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDueDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _titleController.text.trim().isEmpty ? null : _addTask,
          child: const Text('添加'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  void _addTask() {
    final task = Task.create(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      tags: _tags,
    );

    widget.onTaskAdded(task);
    Navigator.pop(context);
  }
}

// 任务详情对话框
class TaskDetailDialog extends StatelessWidget {
  final Task task;
  final Function(Task) onTaskUpdated;
  final VoidCallback onTaskDeleted;

  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(task.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.description.isNotEmpty) ...[
              const Text('描述:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(task.description),
              const SizedBox(height: 16),
            ],

            Text('优先级: ${task.priority.displayName}'),
            Text('状态: ${task.status.displayName}'),

            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Text('到期日期: ${_formatDate(task.dueDate!)}'),
            ],

            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('标签: ${task.tags.join(', ')}'),
            ],

            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('子任务:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...task.subtasks.map((subtask) => CheckboxListTile(
                title: Text(subtask.title),
                value: subtask.isCompleted,
                onChanged: (value) {
                  // 这里可以添加子任务状态切换功能
                },
              )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        TextButton(
          onPressed: () {
            onTaskDeleted();
            Navigator.pop(context);
          },
          child: const Text('删除', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () {
            // 切换完成状态
            final updatedTask = task.copyWith(
              status: task.isCompleted ? TaskStatus.pending : TaskStatus.completed,
            );
            onTaskUpdated(updatedTask);
            Navigator.pop(context);
          },
          child: Text(task.isCompleted ? '标记未完成' : '标记完成'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}