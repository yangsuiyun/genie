// Task tags input widget (placeholder)
import 'package:flutter/material.dart';

class TaskTagsInput extends StatelessWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const TaskTagsInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: '标签',
        hintText: '输入标签，用逗号分隔',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final newTags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
        onTagsChanged(newTags);
      },
    );
  }
}
