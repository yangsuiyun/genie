import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

// 设置数据模型
class AppSettings {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // 设置项
  int workDuration = 25; // 工作时长（分钟）
  int shortBreak = 5;    // 短休息（分钟）
  int longBreak = 15;    // 长休息（分钟）
  bool soundEnabled = true; // 提醒声音
  String theme = 'red';     // 主题颜色
  bool notificationsEnabled = true; // 通知开关
  bool autoStartBreaks = false;     // 自动开始休息
  bool autoStartPomodoros = false;  // 自动开始番茄钟
  int longBreakInterval = 4;        // 长休息间隔

  // 监听器
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // 保存设置
  void saveSettings() {
    // 这里可以添加本地存储逻辑
    _notifyListeners();
  }

  // 重置为默认值
  void resetToDefaults() {
    workDuration = 25;
    shortBreak = 5;
    longBreak = 15;
    soundEnabled = true;
    theme = 'red';
    notificationsEnabled = true;
    autoStartBreaks = false;
    autoStartPomodoros = false;
    longBreakInterval = 4;
    saveSettings();
  }

  // 获取主题颜色
  Color get themeColor {
    switch (theme) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 设置'),
        backgroundColor: _settings.themeColor.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showResetDialog();
            },
            tooltip: '重置默认设置',
          ),
        ],
      ),
      body: ListView(
        children: [
          // 番茄钟设置
          _buildSectionHeader('番茄钟设置'),
          _buildDurationSetting(
            '工作时长',
            '${_settings.workDuration} 分钟',
            Icons.timer,
            () => _showDurationPicker('工作时长', _settings.workDuration, (value) {
              _settings.workDuration = value;
              _settings.saveSettings();
            }),
          ),
          _buildDurationSetting(
            '短休息',
            '${_settings.shortBreak} 分钟',
            Icons.coffee,
            () => _showDurationPicker('短休息时长', _settings.shortBreak, (value) {
              _settings.shortBreak = value;
              _settings.saveSettings();
            }),
          ),
          _buildDurationSetting(
            '长休息',
            '${_settings.longBreak} 分钟',
            Icons.hotel,
            () => _showDurationPicker('长休息时长', _settings.longBreak, (value) {
              _settings.longBreak = value;
              _settings.saveSettings();
            }),
          ),
          _buildNumberSetting(
            '长休息间隔',
            '每 ${_settings.longBreakInterval} 个番茄钟后',
            Icons.repeat,
            () => _showNumberPicker('长休息间隔', _settings.longBreakInterval, 2, 8, (value) {
              _settings.longBreakInterval = value;
              _settings.saveSettings();
            }),
          ),

          // 自动化设置
          _buildSectionHeader('自动化'),
          _buildSwitchSetting(
            '自动开始休息',
            '番茄钟结束后自动开始休息',
            Icons.play_circle_outline,
            _settings.autoStartBreaks,
            (value) {
              _settings.autoStartBreaks = value;
              _settings.saveSettings();
            },
          ),
          _buildSwitchSetting(
            '自动开始番茄钟',
            '休息结束后自动开始下一个番茄钟',
            Icons.replay,
            _settings.autoStartPomodoros,
            (value) {
              _settings.autoStartPomodoros = value;
              _settings.saveSettings();
            },
          ),

          // 通知设置
          _buildSectionHeader('通知与声音'),
          _buildSwitchSetting(
            '提醒声音',
            '番茄钟和休息结束时播放声音',
            Icons.volume_up,
            _settings.soundEnabled,
            (value) {
              _settings.soundEnabled = value;
              _settings.saveSettings();
            },
          ),
          _buildSwitchSetting(
            '推送通知',
            '允许应用发送通知提醒',
            Icons.notifications,
            _settings.notificationsEnabled,
            (value) {
              _settings.notificationsEnabled = value;
              _settings.saveSettings();
            },
          ),

          // 外观设置
          _buildSectionHeader('外观'),
          _buildThemeSetting(),

          // 关于
          _buildSectionHeader('关于'),
          _buildInfoSetting('应用版本', 'v1.0.0', Icons.info, () {
            _showAboutDialog();
          }),
          _buildInfoSetting('用户指南', '了解如何使用番茄工作法', Icons.help, () {
            _showUserGuide();
          }),
          _buildInfoSetting('意见反馈', '提交建议或报告问题', Icons.feedback, () {
            _showFeedbackDialog();
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _settings.themeColor,
        ),
      ),
    );
  }

  Widget _buildDurationSetting(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _settings.themeColor),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildNumberSetting(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _settings.themeColor),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSetting(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: _settings.themeColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _settings.themeColor,
      ),
    );
  }

  Widget _buildThemeSetting() {
    return ListTile(
      leading: Icon(Icons.palette, color: _settings.themeColor),
      title: const Text('主题颜色'),
      subtitle: Text(_getThemeName(_settings.theme)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        _showThemePicker();
      },
    );
  }

  Widget _buildInfoSetting(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _settings.themeColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'red':
        return '番茄红';
      case 'blue':
        return '天空蓝';
      case 'green':
        return '森林绿';
      case 'purple':
        return '薰衣草紫';
      case 'orange':
        return '活力橙';
      default:
        return '番茄红';
    }
  }

  void _showDurationPicker(String title, int currentValue, Function(int) onChanged) {
    int selectedValue = currentValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前设置: $currentValue 分钟'),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  selectedValue = index + 1;
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final value = index + 1;
                    return Center(
                      child: Text(
                        '$value 分钟',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: value == currentValue ? FontWeight.bold : FontWeight.normal,
                          color: value == currentValue ? _settings.themeColor : null,
                        ),
                      ),
                    );
                  },
                  childCount: 60, // 1-60分钟
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(selectedValue);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _settings.themeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showNumberPicker(String title, int currentValue, int min, int max, Function(int) onChanged) {
    int selectedValue = currentValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前设置: $currentValue'),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedValue = min + index;
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final value = min + index;
                    return Center(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: value == currentValue ? FontWeight.bold : FontWeight.normal,
                          color: value == currentValue ? _settings.themeColor : null,
                        ),
                      ),
                    );
                  },
                  childCount: max - min + 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(selectedValue);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _settings.themeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showThemePicker() {
    final themes = [
      {'key': 'red', 'name': '番茄红', 'color': Colors.red},
      {'key': 'blue', 'name': '天空蓝', 'color': Colors.blue},
      {'key': 'green', 'name': '森林绿', 'color': Colors.green},
      {'key': 'purple', 'name': '薰衣草紫', 'color': Colors.purple},
      {'key': 'orange', 'name': '活力橙', 'color': Colors.orange},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题颜色'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((theme) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme['color'] as Color,
                radius: 15,
              ),
              title: Text(theme['name'] as String),
              trailing: _settings.theme == theme['key']
                ? Icon(Icons.check, color: _settings.themeColor)
                : null,
              onTap: () {
                _settings.theme = theme['key'] as String;
                _settings.saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置为默认值吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              _settings.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已重置为默认值')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 Pomodoro Genie'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🍅 Pomodoro Genie v1.0.0'),
            SizedBox(height: 10),
            Text('一款基于番茄工作法的专注和时间管理应用'),
            SizedBox(height: 10),
            Text('特性:'),
            Text('• 可自定义的番茄钟计时器'),
            Text('• 智能休息提醒'),
            Text('• 任务管理和统计'),
            Text('• 跨平台数据同步'),
            Text('• 多主题支持'),
            SizedBox(height: 10),
            Text('© 2024 Pomodoro Genie'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _settings.themeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('番茄工作法指南'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🍅 什么是番茄工作法？', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('番茄工作法是一种时间管理技术，通过将工作分解为短时间间隔来提高专注力和生产力。'),
              SizedBox(height: 16),
              Text('📋 如何使用？', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. 选择一个任务'),
              Text('2. 设置25分钟的番茄钟'),
              Text('3. 专注工作直到铃声响起'),
              Text('4. 短暂休息5分钟'),
              Text('5. 每4个番茄钟后进行15分钟长休息'),
              SizedBox(height: 16),
              Text('💡 小贴士', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 在番茄钟期间避免干扰'),
              Text('• 如被打断，重新开始番茄钟'),
              Text('• 记录完成的番茄钟数量'),
              Text('• 根据需要调整工作和休息时长'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('意见反馈'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('您的建议对我们很重要！'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '请输入您的建议或问题...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // 这里可以添加发送反馈的逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('感谢您的反馈！')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _settings.themeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
}