// Subtask list item widget (placeholder)
import 'package:flutter/material.dart';
import '../../models/index.dart';

class SubtaskListItem extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SubtaskListItem({
    super.key,
    required this.subtask,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(subtask.title),
      subtitle: subtask.description != null ? Text(subtask.description!) : null,
      leading: Checkbox(
        value: subtask.status == TaskStatus.completed,
        onChanged: (value) {
          // Handle status change
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
