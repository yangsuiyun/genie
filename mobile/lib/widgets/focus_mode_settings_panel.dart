import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 专注模式设置面板
class FocusModeSettingsPanel extends ConsumerStatefulWidget {
  const FocusModeSettingsPanel({super.key});

  @override
  ConsumerState<FocusModeSettingsPanel> createState() => _FocusModeSettingsPanelState();
}

class _FocusModeSettingsPanelState extends ConsumerState<FocusModeSettingsPanel> {
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _longBreakInterval = 4;
  bool _autoStartBreaks = false;
  bool _autoStartPomodoros = false;
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.settings, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '专注模式设置',
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
          
          // 时间设置
          _buildSectionTitle('时间设置'),
          const SizedBox(height: 12),
          
          _buildTimeSetting(
            '工作时长',
            _workDuration,
            (value) => setState(() => _workDuration = value),
            min: 1,
            max: 60,
            unit: '分钟',
          ),
          
          _buildTimeSetting(
            '短休息时长',
            _shortBreakDuration,
            (value) => setState(() => _shortBreakDuration = value),
            min: 1,
            max: 30,
            unit: '分钟',
          ),
          
          _buildTimeSetting(
            '长休息时长',
            _longBreakDuration,
            (value) => setState(() => _longBreakDuration = value),
            min: 1,
            max: 60,
            unit: '分钟',
          ),
          
          _buildTimeSetting(
            '长休息间隔',
            _longBreakInterval,
            (value) => setState(() => _longBreakInterval = value),
            min: 2,
            max: 10,
            unit: '个番茄钟',
          ),
          
          const SizedBox(height: 20),
          
          // 自动化设置
          _buildSectionTitle('自动化设置'),
          const SizedBox(height: 12),
          
          _buildSwitchSetting(
            '自动开始休息',
            '番茄钟完成后自动开始休息',
            _autoStartBreaks,
            (value) => setState(() => _autoStartBreaks = value),
          ),
          
          _buildSwitchSetting(
            '自动开始番茄钟',
            '休息完成后自动开始下一个番茄钟',
            _autoStartPomodoros,
            (value) => setState(() => _autoStartPomodoros = value),
          ),
          
          const SizedBox(height: 20),
          
          // 通知设置
          _buildSectionTitle('通知设置'),
          const SizedBox(height: 12),
          
          _buildSwitchSetting(
            '声音提醒',
            '番茄钟完成时播放提示音',
            _soundEnabled,
            (value) => setState(() => _soundEnabled = value),
          ),
          
          _buildSwitchSetting(
            '桌面通知',
            '显示桌面通知提醒',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          
          const SizedBox(height: 24),
          
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTimeSetting(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    required int min,
    required int max,
    required String unit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value $unit',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: value > min ? () => onChanged(value - 1) : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: value < max ? () => onChanged(value + 1) : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.red,
            activeTrackColor: Colors.red.withOpacity(0.3),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // TODO: 保存设置到本地存储
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('设置已保存'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

