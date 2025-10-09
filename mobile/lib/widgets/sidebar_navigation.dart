import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';
import '../services/session_service.dart';
import 'main_layout.dart';

// 侧边栏导航组件
class SidebarNavigation extends ConsumerWidget {
  final TaskTimeFilter selectedFilter;
  final Function(TaskTimeFilter) onFilterChanged;

  const SidebarNavigation({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskService = ref.watch(taskServiceProvider);
    final sessionService = ref.watch(sessionServiceProvider);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 侧边栏头部
          _buildHeader(context),
          
          // 导航项
          Expanded(
            child: ListView(
              children: [
                _buildFilterItem(
                  context: context,
                  icon: Icons.today,
                  label: '今天',
                  filter: TaskTimeFilter.today,
                  taskService: taskService,
                  sessionService: sessionService,
                ),
                _buildFilterItem(
                  context: context,
                  icon: Icons.wb_sunny_outlined,
                  label: '明天',
                  filter: TaskTimeFilter.tomorrow,
                  taskService: taskService,
                  sessionService: sessionService,
                ),
                _buildFilterItem(
                  context: context,
                  icon: Icons.calendar_view_week,
                  label: '本周',
                  filter: TaskTimeFilter.thisWeek,
                  taskService: taskService,
                  sessionService: sessionService,
                ),
                _buildFilterItem(
                  context: context,
                  icon: Icons.schedule,
                  label: '计划中',
                  filter: TaskTimeFilter.planned,
                  taskService: taskService,
                  sessionService: sessionService,
                ),
                _buildFilterItem(
                  context: context,
                  icon: Icons.check_circle,
                  label: '已完成',
                  filter: TaskTimeFilter.completed,
                  taskService: taskService,
                  sessionService: sessionService,
                ),
              ],
            ),
          ),
          
          // 底部操作
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.view_list,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '任务分类',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TaskTimeFilter filter,
    required TaskService taskService,
    required SessionService sessionService,
  }) {
    final isSelected = selectedFilter == filter;
    final taskCount = _getTaskCount(taskService, filter);
    final estimatedTime = _getEstimatedTime(taskService, filter);

    return InkWell(
      onTap: () => onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
          border: isSelected 
            ? Border(
                left: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 3,
                ),
              )
            : null,
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 20,
              color: isSelected 
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    '${taskCount}个任务 • ${_formatDuration(estimatedTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // 任务计数徽章
            if (taskCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  taskCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 快速操作按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateTaskDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建任务'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 项目管理按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showProjectManager(context),
              icon: const Icon(Icons.folder_outlined, size: 18),
              label: const Text('项目管理'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getTaskCount(TaskService taskService, TaskTimeFilter filter) {
    final tasks = taskService.getTasksByTimeFilter(filter);
    return tasks.length;
  }

  Duration _getEstimatedTime(TaskService taskService, TaskTimeFilter filter) {
    final tasks = taskService.getTasksByTimeFilter(filter);
    return tasks.fold(
      Duration.zero,
      (sum, task) => sum + Duration(minutes: task.plannedPomodoros * 25),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _showCreateTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建任务'),
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

  void _showProjectManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('项目管理'),
        content: const Text('项目管理功能开发中...'),
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

