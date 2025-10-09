// Session controls widget
import 'package:flutter/material.dart';

class SessionControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onSkip;

  const SessionControls({
    super.key,
    required this.isRunning,
    required this.isPaused,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Start/Resume button
        if (!isRunning || isPaused)
          _buildControlButton(
            icon: isPaused ? Icons.play_arrow : Icons.play_arrow,
            label: isPaused ? '继续' : '开始',
            onPressed: isPaused ? onResume : onStart,
            color: Colors.green,
          ),
        
        // Pause button
        if (isRunning && !isPaused)
          _buildControlButton(
            icon: Icons.pause,
            label: '暂停',
            onPressed: onPause,
            color: Colors.orange,
          ),
        
        // Stop button
        if (isRunning)
          _buildControlButton(
            icon: Icons.stop,
            label: '停止',
            onPressed: onStop,
            color: Colors.red,
          ),
        
        // Skip button
        if (isRunning)
          _buildControlButton(
            icon: Icons.skip_next,
            label: '跳过',
            onPressed: onSkip,
            color: Colors.blue,
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
