import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/session_service.dart';

// 专注模式统计面板
class FocusModeStatsPanel extends ConsumerWidget {
  const FocusModeStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionService = ref.watch(sessionServiceProvider);
    final sessions = sessionService.getSessions();
    
    // 计算统计数据
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final todaySessions = sessions.where((s) {
      return s.startTime.isAfter(todayStart) && 
             s.startTime.isBefore(todayEnd) &&
             s.isCompleted;
    }).toList();
    
    final totalFocusTime = todaySessions.fold(
      Duration.zero,
      (sum, session) => sum + Duration(seconds: session.actualDuration ?? 0),
    );
    
    final completedPomodoros = todaySessions.where((s) => s.sessionType == SessionType.work).length;
    final completedBreaks = todaySessions.where((s) => s.sessionType != SessionType.work).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '今日专注统计',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 统计卡片
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '🍅',
                  '完成番茄钟',
                  completedPomodoros.toString(),
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '⏰',
                  '专注时间',
                  _formatDuration(totalFocusTime),
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '☕',
                  '休息次数',
                  completedBreaks.toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '📈',
                  '平均时长',
                  _formatDuration(_calculateAverageDuration(todaySessions)),
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 时间轴
          const Text(
            '今日专注时间轴',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // 时间轴视图
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: 24, // 24小时
              itemBuilder: (context, index) {
                final hour = index;
                final hourSessions = todaySessions.where((s) => s.startTime.hour == hour).toList();
                final hasSession = hourSessions.isNotEmpty;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              if (hasSession)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              if (hasSession)
                                Center(
                                  child: Text(
                                    '${hourSessions.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 关闭按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('关闭'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Duration _calculateAverageDuration(List<PomodoroSession> sessions) {
    if (sessions.isEmpty) return Duration.zero;
    
    final totalDuration = sessions.fold(
      Duration.zero,
      (sum, session) => sum + Duration(seconds: session.actualDuration ?? 0),
    );
    
    return Duration(
      seconds: totalDuration.inSeconds ~/ sessions.length,
    );
  }
}

