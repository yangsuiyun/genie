// Note list item widget (placeholder)
import 'package:flutter/material.dart';
import '../../models/index.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteListItem({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.content),
      subtitle: Text('创建于: ${note.createdAt.toString()}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
