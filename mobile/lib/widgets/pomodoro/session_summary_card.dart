// Session summary card widget (placeholder)
import 'package:flutter/material.dart';
import '../../models/index.dart';

class SessionSummaryCard extends StatelessWidget {
  final PomodoroSession session;

  const SessionSummaryCard({
    super.key,
    required this.session,
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
              '会话摘要',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('时长: ${session.duration.inMinutes} 分钟'),
            Text('状态: ${session.status.name}'),
            Text('开始时间: ${session.startTime.toString()}'),
          ],
        ),
      ),
    );
  }
}
