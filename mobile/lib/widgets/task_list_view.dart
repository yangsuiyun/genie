import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';
import 'main_layout.dart';
import 'task_card.dart';

// 任务列表视图组件
class TaskListView extends ConsumerWidget {
  final TaskTimeFilter filter;
  final Function(Task) onTaskSelected;

  const TaskListView({
    super.key,
    required this.filter,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskService = ref.watch(taskServiceProvider);
    final tasks = taskService.getTasksByTimeFilter(filter);
    
    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () => onTaskSelected(task),
          onStartFocus: () => _startFocusMode(context, task),
          onEdit: () => _editTask(context, task),
          onDelete: () => _deleteTask(context, task),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String emptyMessage = '';
    IconData emptyIcon = Icons.task;
    
    switch (widget.filter) {
      case TaskTimeFilter.today:
        emptyMessage = '今天还没有任务\n点击下方按钮创建第一个任务吧！';
        emptyIcon = Icons.today;
        break;
      case TaskTimeFilter.tomorrow:
        emptyMessage = '明天还没有安排任务\n提前规划让工作更高效！';
        emptyIcon = Icons.wb_sunny_outlined;
        break;
      case TaskTimeFilter.thisWeek:
        emptyMessage = '本周还没有任务\n开始规划这一周的工作吧！';
        emptyIcon = Icons.calendar_view_week;
        break;
      case TaskTimeFilter.planned:
        emptyMessage = '还没有计划中的任务\n创建任务开始高效工作！';
        emptyIcon = Icons.schedule;
        break;
      case TaskTimeFilter.completed:
        emptyMessage = '还没有完成的任务\n完成一些任务后这里会显示！';
        emptyIcon = Icons.check_circle;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createTask(context),
              icon: const Icon(Icons.add),
              label: const Text('创建任务'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startFocusMode(BuildContext context, Task task) {
    Navigator.of(context).pushNamed('/focus', arguments: task);
  }

  void _editTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑任务'),
        content: Text('编辑任务: ${task.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现任务编辑逻辑
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务"${task.title}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现任务删除逻辑
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _createTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建任务'),
        content: const Text('任务创建功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

