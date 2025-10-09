import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';
import '../services/session_service.dart';
import '../services/pomodoro_state.dart';
import '../services/white_noise_service.dart';
import '../screens/main_layout.dart';
import '../widgets/white_noise_panel.dart';
import '../widgets/focus_mode_settings_panel.dart';
import '../widgets/focus_mode_stats_panel.dart';

// 全屏专注模式组件
class FocusModeScreen extends ConsumerStatefulWidget {
  final Task? task;

  const FocusModeScreen({
    super.key,
    this.task,
  });

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen>
    with TickerProviderStateMixin {
  final PomodoroState _pomodoroState = PomodoroState();
  bool _showSidebar = true;
  bool _isFullscreen = false;
  bool _isWhiteNoisePlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _pomodoroState.start(widget.task);
    }
    _pomodoroState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _pomodoroState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // 背景装饰
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2C3E50),
                      Color(0xFF34495E),
                      Color(0xFF1A1A1A),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 主内容
          SafeArea(
            child: Column(
              children: [
                // 顶部控制栏
                _buildTopBar(),

                Expanded(
                  child: Row(
                    children: [
                      // 主计时器区域
                      Expanded(
                        child: _buildTimerArea(),
                      ),

                      // 侧边栏（可折叠）
                      if (_showSidebar && !_isFullscreen)
                        _buildSidebar(),
                    ],
                  ),
                ),

                // 底部控制栏
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () => _showStats(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 任务名称
          if (widget.task != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                widget.task!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // 大圆形计时器
          SizedBox(
            width: 400,
            height: 400,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 进度圆环
                CircularProgressIndicator(
                  value: _pomodoroState.progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _pomodoroState.progressColor,
                  ),
                ),

                // 时间显示
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _pomodoroState.timeDisplay,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pomodoroState.statusText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 重置按钮
              ElevatedButton(
                onPressed: _pomodoroState.reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 4),
                    Text('重置'),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 开始/暂停按钮
              ElevatedButton(
                onPressed: _pomodoroState.isRunning
                    ? _pomodoroState.pause
                    : _pomodoroState.resume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_pomodoroState.isRunning ? Icons.pause : Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(
                      _pomodoroState.isRunning ? 'Pause' : 'Start to Focus',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 跳过按钮
              ElevatedButton(
                onPressed: _pomodoroState.skip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.skip_next, size: 18),
                    SizedBox(width: 4),
                    Text('跳过'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final taskService = ref.watch(taskServiceProvider);
    final sessionService = ref.watch(sessionServiceProvider);
    final todayTasks = taskService.getTasksByTimeFilter(TaskTimeFilter.today);
    final sessions = sessionService.getSessions();

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focus Time of Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // 今日任务列表
          const Text(
            'Today',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: todayTasks.take(5).length,
              itemBuilder: (context, index) {
                final task = todayTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                        color: task.isCompleted ? Colors.green : Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // 今日专注时间记录
          const Text(
            "Today's Focus Time Records",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: 12, // 显示12小时
              itemBuilder: (context, index) {
                final hour = 9 + index; // 从9:00开始
                final hasSession = sessions.any((s) => s.startTime.hour == hour);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            if (hasSession)
                              Positioned(
                                left: 20,
                                top: -4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            label: 'Fullscreen',
            onTap: _toggleFullscreen,
            isActive: _isFullscreen,
          ),
          const SizedBox(width: 30),
          _buildControlButton(
            icon: _showSidebar ? Icons.menu : Icons.menu_open,
            label: 'Sidebar',
            onTap: _toggleSidebar,
            isActive: _showSidebar,
          ),
          const SizedBox(width: 30),
          _buildControlButton(
            icon: _isWhiteNoisePlaying ? Icons.volume_up : Icons.volume_off,
            label: 'White Noise',
            onTap: _toggleWhiteNoise,
            isActive: _isWhiteNoisePlaying,
          ),
          const SizedBox(width: 30),
          _buildControlButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => _showSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              color: isActive ? Colors.white : Colors.white70, 
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70, 
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
    });
  }

  void _toggleWhiteNoise() {
    setState(() {
      _isWhiteNoisePlaying = !_isWhiteNoisePlaying;
    });
    
    if (_isWhiteNoisePlaying) {
      _showWhiteNoisePanel();
    } else {
      WhiteNoiseService().stop();
    }
  }

  void _showWhiteNoisePanel() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: WhiteNoisePanel(),
      ),
    );
  }

  void _showStats(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FocusModeStatsPanel(),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FocusModeSettingsPanel(),
      ),
    );
  }

}
