// Task selector widget
import 'package:flutter/material.dart';

class TaskSelector extends StatelessWidget {
  final String? selectedTaskId;
  final List<Task> tasks;
  final Function(String?) onTaskSelected;

  const TaskSelector({
    super.key,
    required this.selectedTaskId,
    required this.tasks,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 选择任务',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              const Text('暂无任务')
            else
              DropdownButtonFormField<String?>(
                value: selectedTaskId,
                decoration: const InputDecoration(
                  labelText: '选择要专注的任务',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('无任务'),
                  ),
                  ...tasks.map((task) => DropdownMenuItem<String?>(
                    value: task.id,
                    child: Text(task.title),
                  )),
                ],
                onChanged: onTaskSelected,
              ),
          ],
        ),
      ),
    );
  }
}

// Task model (simplified)
class Task {
  final String id;
  final String title;

  Task({required this.id, required this.title});
}
