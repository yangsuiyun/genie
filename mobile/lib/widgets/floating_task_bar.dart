import 'package:flutter/material.dart';
import '../models/index.dart';

// 浮动操作栏组件
class FloatingTaskBar extends StatelessWidget {
  final Task? currentTask;
  final VoidCallback onStartFocus;
  final VoidCallback onTaskTap;

  const FloatingTaskBar({
    super.key,
    this.currentTask,
    required this.onStartFocus,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (currentTask == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 500) {
            // 向下滑动关闭
            onTaskTap();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // 任务计数
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${currentTask!.completedPomodoros}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 任务名称
              Expanded(
                child: GestureDetector(
                  onTap: onTaskTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTask!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '🍅 ${currentTask!.completedPomodoros}/${currentTask!.plannedPomodoros}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 背景装饰
              if (currentTask!.priority == TaskPriority.high)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text('🌿', style: TextStyle(fontSize: 20)),
                ),

              // 开始按钮
              ElevatedButton(
                onPressed: onStartFocus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 18),
                    SizedBox(width: 4),
                    Text('Start'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

