import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/sync_service.dart';
import 'services/task_service.dart';
import 'services/session_service.dart';
import 'models/index.dart';
// Web-specific imports
import 'settings_web_stub.dart'
    if (dart.library.html) 'settings_web.dart' as web_utils;

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
  MaterialColor get themeColor {
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
  final SyncService _syncService = SyncService();
  final TaskService _taskService = TaskService();
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _syncService.initialize();
    _taskService.initialize();
    _sessionService.initialize();
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

          // 数据同步
          _buildSectionHeader('数据同步'),
          _buildSyncStatusSection(),

          // 数据管理
          _buildSectionHeader('数据管理'),
          _buildDataManagementSection(),

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

  Widget _buildSyncStatusSection() {
    return FutureBuilder<void>(
      future: _syncService.checkConnectivity(),
      builder: (context, snapshot) {
        final isOnline = _syncService.isOnline;
        final lastSyncTime = _syncService.lastSyncTime;
        final isSyncing = _syncService.isSyncInProgress;

        return Column(
          children: [
            // 连接状态
            ListTile(
              leading: Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? Colors.green : Colors.grey,
              ),
              title: Text('服务器连接'),
              subtitle: Text(isOnline ? '已连接' : '离线'),
              trailing: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            ),

            // 上次同步时间
            ListTile(
              leading: Icon(Icons.sync, color: _settings.themeColor),
              title: const Text('上次同步'),
              subtitle: Text(_formatLastSyncTime(lastSyncTime)),
              trailing: ElevatedButton(
                onPressed: isSyncing ? null : () => _performManualSync(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _settings.themeColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(isSyncing ? '同步中...' : '手动同步'),
              ),
            ),

            // 同步统计
            if (isOnline) ...[
              ListTile(
                leading: Icon(Icons.analytics, color: _settings.themeColor),
                title: const Text('同步统计'),
                subtitle: Text(_getSyncStatisticsText()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSyncStatistics(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDataManagementSection() {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.download, color: _settings.themeColor),
          title: const Text('导出数据'),
          subtitle: const Text('导出所有任务和会话数据'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _exportData,
        ),
        ListTile(
          leading: Icon(Icons.upload, color: _settings.themeColor),
          title: const Text('导入数据'),
          subtitle: const Text('从备份文件导入数据'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _importData,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('清空所有数据'),
          subtitle: const Text('删除所有任务和会话记录'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showClearDataConfirmation,
        ),
      ],
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

  String _formatLastSyncTime(DateTime? lastSyncTime) {
    if (lastSyncTime == null) {
      return '从未同步';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${difference.inDays} 天前';
    }
  }

  String _getSyncStatisticsText() {
    final stats = _syncService.getSyncStatistics();
    final localTasks = stats['localTasks'] ?? 0;
    final localSessions = stats['localSessions'] ?? 0;
    return '$localTasks 个任务, $localSessions 个会话';
  }

  Future<void> _performManualSync() async {
    setState(() {}); // Refresh UI to show syncing state

    try {
      final result = await _syncService.syncAll();

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步成功: ${result.message}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步错误: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {}); // Refresh UI after sync
  }

  void _showSyncStatistics() {
    final stats = _syncService.getSyncStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('连接状态', stats['isOnline'] ? '在线' : '离线'),
            _buildStatRow('本地任务', '${stats['localTasks']} 个'),
            _buildStatRow('本地会话', '${stats['localSessions']} 个'),
            _buildStatRow('同步状态', stats['syncInProgress'] ? '同步中' : '空闲'),
            if (stats['lastSyncTime'] != null)
              _buildStatRow('上次同步', _formatLastSyncTime(DateTime.parse(stats['lastSyncTime']))),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // 收集所有数据
      final tasks = _taskService.tasks;
      final sessions = _sessionService.sessions;
      final settings = {
        'workDuration': _settings.workDuration,
        'shortBreak': _settings.shortBreak,
        'longBreak': _settings.longBreak,
        'theme': _settings.theme,
        'soundEnabled': _settings.soundEnabled,
        'notificationsEnabled': _settings.notificationsEnabled,
        'autoStartBreaks': _settings.autoStartBreaks,
        'autoStartPomodoros': _settings.autoStartPomodoros,
        'longBreakInterval': _settings.longBreakInterval,
      };

      final exportData = {
        'exportVersion': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'data': {
          'tasks': tasks.map((task) => task.toJson()).toList(),
          'sessions': sessions.map((session) => session.toJson()).toList(),
          'settings': settings,
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final bytes = utf8.encode(jsonString);

      web_utils.downloadFile(
        bytes,
        'pomodoro_genie_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('数据已导出 (${tasks.length} 个任务, ${sessions.length} 个会话)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importData() async {
    try {
      final content = await web_utils.uploadFile();
      if (content == null) return;

      try {
          final importData = json.decode(content) as Map<String, dynamic>;

          // 验证导入数据格式
          if (!importData.containsKey('data') || !importData.containsKey('exportVersion')) {
            throw Exception('无效的备份文件格式');
          }

          final data = importData['data'] as Map<String, dynamic>;
          final tasksData = data['tasks'] as List<dynamic>? ?? [];
          final sessionsData = data['sessions'] as List<dynamic>? ?? [];
          final settingsData = data['settings'] as Map<String, dynamic>? ?? {};

          // 显示确认对话框
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认导入'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('此操作将导入以下数据：'),
                  const SizedBox(height: 8),
                  Text('• ${tasksData.length} 个任务'),
                  Text('• ${sessionsData.length} 个会话记录'),
                  if (settingsData.isNotEmpty) Text('• 应用设置'),
                  const SizedBox(height: 16),
                  const Text(
                    '注意：现有数据将被合并，重复的项目将被跳过。',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: _settings.themeColor),
                  child: const Text('导入', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (result != true) return;

          int importedTasks = 0;
          int importedSessions = 0;

          // 导入任务
          for (final taskData in tasksData) {
            try {
              final task = Task.fromJson(taskData as Map<String, dynamic>);
              // 检查是否已存在相同ID的任务
              if (!_taskService.tasks.any((t) => t.id == task.id)) {
                await _taskService.addTask(task);
                importedTasks++;
              }
            } catch (e) {
              print('导入任务失败: $e');
            }
          }

          // 导入会话
          for (final sessionData in sessionsData) {
            try {
              final session = PomodoroSession.fromJson(sessionData as Map<String, dynamic>);
              // 检查是否已存在相同ID的会话
              if (!_sessionService.sessions.any((s) => s.id == session.id)) {
                await _sessionService.importSession(session);
                importedSessions++;
              }
            } catch (e) {
              print('导入会话失败: $e');
            }
          }

          // 导入设置（可选）
          if (settingsData.isNotEmpty) {
            final importSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('导入设置'),
                content: const Text('是否要导入备份中的应用设置？这将覆盖当前设置。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('跳过'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('导入设置'),
                  ),
                ],
              ),
            );

            if (importSettings == true) {
              _settings.workDuration = settingsData['workDuration'] ?? _settings.workDuration;
              _settings.shortBreak = settingsData['shortBreak'] ?? _settings.shortBreak;
              _settings.longBreak = settingsData['longBreak'] ?? _settings.longBreak;
              _settings.theme = settingsData['theme'] ?? _settings.theme;
              _settings.soundEnabled = settingsData['soundEnabled'] ?? _settings.soundEnabled;
              _settings.notificationsEnabled = settingsData['notificationsEnabled'] ?? _settings.notificationsEnabled;
              _settings.autoStartBreaks = settingsData['autoStartBreaks'] ?? _settings.autoStartBreaks;
              _settings.autoStartPomodoros = settingsData['autoStartPomodoros'] ?? _settings.autoStartPomodoros;
              _settings.longBreakInterval = settingsData['longBreakInterval'] ?? _settings.longBreakInterval;
              _settings.saveSettings();
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入完成: $importedTasks 个任务, $importedSessions 个会话'),
              backgroundColor: Colors.green,
            ),
          );

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件选择失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 危险操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('确定要清空所有数据吗？此操作将删除：'),
            const SizedBox(height: 8),
            Text('• ${_taskService.tasks.length} 个任务'),
            Text('• ${_sessionService.sessions.length} 个会话记录'),
            const SizedBox(height: 16),
            const Text(
              '此操作不可撤销！建议在清空前先导出数据备份。',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _taskService.clearAllTasks();
              await _sessionService.clearAllSessions();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('所有数据已清空'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}