// Task priority selector widget
import 'package:flutter/material.dart';
import '../../models/index.dart';

class TaskPrioritySelector extends StatelessWidget {
  final TaskPriority selectedPriority;
  final Function(TaskPriority) onPriorityChanged;

  const TaskPrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskPriority>(
      value: selectedPriority,
      decoration: const InputDecoration(
        labelText: '优先级',
        border: OutlineInputBorder(),
      ),
      items: TaskPriority.values.map((priority) {
        return DropdownMenuItem<TaskPriority>(
          value: priority,
          child: Row(
            children: [
              Icon(_getPriorityIcon(priority), color: _getPriorityColor(priority)),
              const SizedBox(width: 8),
              Text(_getPriorityText(priority)),
            ],
          ),
        );
      }).toList(),
      onChanged: (priority) {
        if (priority != null) {
          onPriorityChanged(priority);
        }
      },
    );
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }
}
