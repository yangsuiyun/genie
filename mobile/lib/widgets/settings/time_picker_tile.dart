import 'package:flutter/material.dart';

class TimePickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Duration value;
  final ValueChanged<Duration> onChanged;

  const TimePickerTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(_formatDuration(value)),
      onTap: () => _showTimePicker(context),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    return '${minutes}分钟';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: value.inHours,
        minute: value.inMinutes % 60,
      ),
    );

    if (time != null) {
      final newDuration = Duration(
        hours: time.hour,
        minutes: time.minute,
      );
      onChanged(newDuration);
    }
  }
}
