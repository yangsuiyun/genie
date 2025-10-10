// Task status selector widget
import 'package:flutter/material.dart';
import '../../models/index.dart';

class TaskStatusSelector extends StatelessWidget {
  final TaskStatus selectedStatus;
  final Function(TaskStatus) onStatusChanged;

  const TaskStatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskStatus>(
      value: selectedStatus,
      decoration: const InputDecoration(
        labelText: '状态',
        border: OutlineInputBorder(),
      ),
      items: TaskStatus.values.map((status) {
        return DropdownMenuItem<TaskStatus>(
          value: status,
          child: Row(
            children: [
              Icon(_getStatusIcon(status), color: _getStatusColor(status)),
              const SizedBox(width: 8),
              Text(_getStatusText(status)),
            ],
          ),
        );
      }).toList(),
      onChanged: (status) {
        if (status != null) {
          onStatusChanged(status);
        }
      },
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '待处理';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.cancelled:
        return '已取消';
    }
  }
}
