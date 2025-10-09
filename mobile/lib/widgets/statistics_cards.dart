import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';
import '../services/session_service.dart';
import 'main_layout.dart';

// 统计卡片组件
class StatisticsCards extends ConsumerWidget {
  final TaskTimeFilter filter;

  const StatisticsCards({
    super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskService = ref.watch(taskServiceProvider);
    final sessionService = ref.watch(sessionServiceProvider);
    
    final stats = _calculateStats(taskService, sessionService, filter);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            context: context,
            label: '预计',
            value: _formatDuration(stats.estimatedTime),
            color: Colors.blue,
            icon: Icons.schedule,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context: context,
            label: '待办',
            value: stats.tasksToComplete.toString(),
            color: Colors.orange,
            icon: Icons.task_alt,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context: context,
            label: '已用',
            value: _formatDuration(stats.elapsedTime),
            color: Colors.green,
            icon: Icons.timer,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context: context,
            label: '完成',
            value: stats.completedTasks.toString(),
            color: Colors.purple,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 数值
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 标签
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TodayStatistics _calculateStats(
    TaskService taskService,
    SessionService sessionService,
    TaskTimeFilter filter,
  ) {
    final tasks = taskService.getTasksByTimeFilter(filter);
    final sessions = sessionService.getSessions();

    // 计算预计时间
    final estimatedTime = tasks.fold(
      Duration.zero,
      (sum, task) => sum + Duration(minutes: task.plannedPomodoros * 25),
    );

    // 计算待办任务数
    final tasksToComplete = tasks.where((task) => !task.isCompleted).length;

    // 计算已用时间
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    Duration elapsedTime = Duration.zero;
    if (filter == TaskTimeFilter.today) {
      final todaySessions = sessions.where((session) {
        return session.startTime.isAfter(today) && 
               session.startTime.isBefore(tomorrow) &&
               session.isCompleted;
      });
      elapsedTime = todaySessions.fold(
        Duration.zero,
        (sum, session) => sum + Duration(seconds: session.actualDuration ?? 0),
      );
    }

    // 计算完成任务数
    final completedTasks = tasks.where((task) => task.isCompleted).length;

    return TodayStatistics(
      estimatedTime: estimatedTime,
      tasksToComplete: tasksToComplete,
      elapsedTime: elapsedTime,
      completedTasks: completedTasks,
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
}

// 统计数据模型
class TodayStatistics {
  final Duration estimatedTime;
  final int tasksToComplete;
  final Duration elapsedTime;
  final int completedTasks;

  TodayStatistics({
    required this.estimatedTime,
    required this.tasksToComplete,
    required this.elapsedTime,
    required this.completedTasks,
  });
}

