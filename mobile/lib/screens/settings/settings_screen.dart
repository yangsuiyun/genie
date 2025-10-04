import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/settings/setting_section.dart';
import '../../widgets/settings/setting_tile.dart';
import '../../widgets/settings/time_picker_tile.dart';
import '../../widgets/settings/color_picker_tile.dart';
import '../../widgets/common/loading_button.dart';
import '../../utils/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  void _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            if (user != null) _buildUserProfileSection(user),

            // Pomodoro Settings
            SettingSection(
              title: 'Pomodoro Timer',
              icon: Icons.timer,
              children: [
                TimePickerTile(
                  title: 'Work Duration',
                  subtitle: 'Length of work sessions',
                  value: Duration(minutes: settings.workDuration),
                  onChanged: (duration) {
                    ref.read(settingsProvider.notifier).updateSettings(
                      workDuration: duration.inMinutes,
                    );
                  },
                  minDuration: const Duration(minutes: 5),
                  maxDuration: const Duration(minutes: 90),
                  stepMinutes: 5,
                ),
                TimePickerTile(
                  title: 'Short Break Duration',
                  subtitle: 'Length of short breaks',
                  value: Duration(minutes: settings.shortBreakDuration),
                  onChanged: (duration) {
                    ref.read(settingsProvider.notifier).updateSettings(
                      shortBreakDuration: duration.inMinutes,
                    );
                  },
                  minDuration: const Duration(minutes: 1),
                  maxDuration: const Duration(minutes: 30),
                  stepMinutes: 1,
                ),
                TimePickerTile(
                  title: 'Long Break Duration',
                  subtitle: 'Length of long breaks',
                  value: Duration(minutes: settings.longBreakDuration),
                  onChanged: (duration) {
                    ref.read(settingsProvider.notifier).updateSettings(
                      longBreakDuration: duration.inMinutes,
                    );
                  },
                  minDuration: const Duration(minutes: 5),
                  maxDuration: const Duration(minutes: 60),
                  stepMinutes: 5,
                ),
                SettingTile(
                  title: 'Sessions Until Long Break',
                  subtitle: 'Number of work sessions before long break',
                  trailing: DropdownButton<int>(
                    value: settings.sessionsUntilLongBreak,
                    items: List.generate(8, (index) => index + 1)
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          sessionsUntilLongBreak: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Auto-start Breaks',
                  subtitle: 'Automatically start break sessions',
                  trailing: Switch(
                    value: settings.autoStartBreaks,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        autoStartBreaks: value,
                      );
                    },
                  ),
                ),
                SettingTile(
                  title: 'Auto-start Work Sessions',
                  subtitle: 'Automatically start work sessions after breaks',
                  trailing: Switch(
                    value: settings.autoStartWork,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        autoStartWork: value,
                      );
                    },
                  ),
                ),
              ],
            ),

            // Audio & Notifications
            SettingSection(
              title: 'Audio & Notifications',
              icon: Icons.notifications,
              children: [
                SettingTile(
                  title: 'Sound Effects',
                  subtitle: 'Play sounds for timer events',
                  trailing: Switch(
                    value: settings.soundEnabled,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        soundEnabled: value,
                      );
                    },
                  ),
                ),
                SettingTile(
                  title: 'Sound Volume',
                  subtitle: 'Adjust volume level',
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: settings.soundVolume.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      onChanged: settings.soundEnabled ? (value) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          soundVolume: value.round(),
                        );
                      } : null,
                    ),
                  ),
                ),
                SettingTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive session and reminder notifications',
                  trailing: Switch(
                    value: settings.notificationEnabled,
                    onChanged: (value) async {
                      if (value) {
                        final granted = await ref.read(notificationsProvider.notifier)
                            .requestPermissions();
                        if (granted) {
                          ref.read(settingsProvider.notifier).updateSettings(
                            notificationEnabled: true,
                          );
                        }
                      } else {
                        ref.read(settingsProvider.notifier).updateSettings(
                          notificationEnabled: false,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Notification Sound',
                  subtitle: 'Choose notification sound',
                  trailing: DropdownButton<String>(
                    value: settings.notificationSound,
                    items: const [
                      DropdownMenuItem(value: 'default', child: Text('Default')),
                      DropdownMenuItem(value: 'bell', child: Text('Bell')),
                      DropdownMenuItem(value: 'chime', child: Text('Chime')),
                      DropdownMenuItem(value: 'ding', child: Text('Ding')),
                    ],
                    onChanged: settings.notificationEnabled ? (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          notificationSound: value,
                        );
                      }
                    } : null,
                  ),
                ),
              ],
            ),

            // Appearance
            SettingSection(
              title: 'Appearance',
              icon: Icons.palette,
              children: [
                SettingTile(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  trailing: Switch(
                    value: settings.darkMode,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        darkMode: value,
                      );
                    },
                  ),
                ),
                ColorPickerTile(
                  title: 'Primary Color',
                  subtitle: 'Choose your accent color',
                  value: Color(int.parse(settings.primaryColor.substring(1), radix: 16) + 0xFF000000),
                  onChanged: (color) {
                    ref.read(settingsProvider.notifier).updateSettings(
                      primaryColor: '#${color.value.toRadixString(16).substring(2)}',
                    );
                  },
                ),
                ColorPickerTile(
                  title: 'Accent Color',
                  subtitle: 'Choose your secondary color',
                  value: Color(int.parse(settings.accentColor.substring(1), radix: 16) + 0xFF000000),
                  onChanged: (color) {
                    ref.read(settingsProvider.notifier).updateSettings(
                      accentColor: '#${color.value.toRadixString(16).substring(2)}',
                    );
                  },
                ),
                SettingTile(
                  title: 'Font Size',
                  subtitle: 'Adjust text size',
                  trailing: DropdownButton<String>(
                    value: settings.fontSize,
                    items: const [
                      DropdownMenuItem(value: 'small', child: Text('Small')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'large', child: Text('Large')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          fontSize: value,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            // Productivity & Tasks
            SettingSection(
              title: 'Productivity & Tasks',
              icon: Icons.task_alt,
              children: [
                SettingTile(
                  title: 'Default Task Priority',
                  subtitle: 'Priority for new tasks',
                  trailing: DropdownButton<String>(
                    value: settings.defaultTaskPriority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          defaultTaskPriority: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Default Estimated Pomodoros',
                  subtitle: 'Default estimate for new tasks',
                  trailing: DropdownButton<int>(
                    value: settings.defaultEstimatedPomodoros,
                    items: List.generate(8, (index) => index + 1)
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          defaultEstimatedPomodoros: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Default Reminder Time',
                  subtitle: 'Minutes before due date',
                  trailing: DropdownButton<int>(
                    value: settings.defaultReminderMinutes,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('None')),
                      DropdownMenuItem(value: 5, child: Text('5 min')),
                      DropdownMenuItem(value: 10, child: Text('10 min')),
                      DropdownMenuItem(value: 15, child: Text('15 min')),
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                      DropdownMenuItem(value: 120, child: Text('2 hours')),
                      DropdownMenuItem(value: 1440, child: Text('1 day')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          defaultReminderMinutes: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Show Completed Tasks',
                  subtitle: 'Keep completed tasks visible in lists',
                  trailing: Switch(
                    value: settings.showCompletedTasks,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        showCompletedTasks: value,
                      );
                    },
                  ),
                ),
              ],
            ),

            // Sync & Data
            SettingSection(
              title: 'Sync & Data',
              icon: Icons.sync,
              children: [
                SettingTile(
                  title: 'Auto Sync',
                  subtitle: 'Automatically sync data when online',
                  trailing: Switch(
                    value: settings.autoSync,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        autoSync: value,
                      );
                    },
                  ),
                ),
                SettingTile(
                  title: 'Sync Over Cellular',
                  subtitle: 'Sync data when using mobile data',
                  trailing: Switch(
                    value: settings.syncOverCellular,
                    onChanged: settings.autoSync ? (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        syncOverCellular: value,
                      );
                    } : null,
                  ),
                ),
                SettingTile(
                  title: 'Last Sync',
                  subtitle: syncState.lastSyncTime != null
                      ? 'Synced ${_formatLastSync(syncState.lastSyncTime!)}'
                      : 'Never synced',
                  trailing: syncState.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.sync),
                          onPressed: () {
                            ref.read(syncProvider.notifier).syncNow();
                          },
                        ),
                ),
                SettingTile(
                  title: 'Backup Data',
                  subtitle: 'Export your data for backup',
                  trailing: const Icon(Icons.backup),
                  onTap: _exportData,
                ),
                SettingTile(
                  title: 'Restore Data',
                  subtitle: 'Import data from backup',
                  trailing: const Icon(Icons.restore),
                  onTap: _importData,
                ),
              ],
            ),

            // Language & Region
            SettingSection(
              title: 'Language & Region',
              icon: Icons.language,
              children: [
                SettingTile(
                  title: 'Language',
                  subtitle: 'App language',
                  trailing: DropdownButton<String>(
                    value: settings.language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      DropdownMenuItem(value: 'zh', child: Text('中文')),
                      DropdownMenuItem(value: 'ja', child: Text('日本語')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          language: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Timezone',
                  subtitle: settings.timezone,
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectTimezone,
                ),
                SettingTile(
                  title: 'Date Format',
                  subtitle: settings.dateFormat,
                  trailing: DropdownButton<String>(
                    value: settings.dateFormat,
                    items: const [
                      DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/dd/yyyy')),
                      DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('dd/MM/yyyy')),
                      DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('yyyy-MM-dd')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          dateFormat: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Time Format',
                  subtitle: settings.timeFormat,
                  trailing: DropdownButton<String>(
                    value: settings.timeFormat,
                    items: const [
                      DropdownMenuItem(value: '12h', child: Text('12 hour')),
                      DropdownMenuItem(value: '24h', child: Text('24 hour')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          timeFormat: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Week Start',
                  subtitle: 'First day of week',
                  trailing: DropdownButton<String>(
                    value: settings.weekStart,
                    items: const [
                      DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
                      DropdownMenuItem(value: 'monday', child: Text('Monday')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          weekStart: value,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            // Privacy & Security
            SettingSection(
              title: 'Privacy & Security',
              icon: Icons.security,
              children: [
                SettingTile(
                  title: 'Biometric Lock',
                  subtitle: 'Use fingerprint or face unlock',
                  trailing: Switch(
                    value: settings.biometricLock,
                    onChanged: (value) async {
                      if (value) {
                        // Check if biometrics are available and authenticate
                        final authenticated = await _authenticateBiometric();
                        if (authenticated) {
                          ref.read(settingsProvider.notifier).updateSettings(
                            biometricLock: true,
                          );
                        }
                      } else {
                        ref.read(settingsProvider.notifier).updateSettings(
                          biometricLock: false,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Auto Lock Timeout',
                  subtitle: 'Lock app after inactivity',
                  trailing: DropdownButton<int>(
                    value: settings.autoLockTimeout,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Never')),
                      DropdownMenuItem(value: 30, child: Text('30 seconds')),
                      DropdownMenuItem(value: 60, child: Text('1 minute')),
                      DropdownMenuItem(value: 300, child: Text('5 minutes')),
                      DropdownMenuItem(value: 900, child: Text('15 minutes')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          autoLockTimeout: value,
                        );
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: 'Analytics',
                  subtitle: 'Help improve the app with usage data',
                  trailing: Switch(
                    value: settings.analyticsEnabled,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        analyticsEnabled: value,
                      );
                    },
                  ),
                ),
                SettingTile(
                  title: 'Crash Reports',
                  subtitle: 'Send crash reports to help fix bugs',
                  trailing: Switch(
                    value: settings.crashReportsEnabled,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        crashReportsEnabled: value,
                      );
                    },
                  ),
                ),
              ],
            ),

            // Account
            if (user != null)
              SettingSection(
                title: 'Account',
                icon: Icons.account_circle,
                children: [
                  SettingTile(
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    trailing: const Icon(Icons.lock),
                    onTap: () => context.push('/settings/change-password'),
                  ),
                  SettingTile(
                    title: 'Email Preferences',
                    subtitle: 'Manage email notifications',
                    trailing: const Icon(Icons.email),
                    onTap: () => context.push('/settings/email-preferences'),
                  ),
                  SettingTile(
                    title: 'Connected Devices',
                    subtitle: 'Manage your synced devices',
                    trailing: const Icon(Icons.devices),
                    onTap: () => context.push('/settings/devices'),
                  ),
                  SettingTile(
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    trailing: const Icon(Icons.delete_forever, color: Colors.red),
                    onTap: _showDeleteAccountDialog,
                    textColor: Colors.red,
                  ),
                ],
              ),

            // Support & About
            SettingSection(
              title: 'Support & About',
              icon: Icons.help,
              children: [
                SettingTile(
                  title: 'Help Center',
                  subtitle: 'Get help and tutorials',
                  trailing: const Icon(Icons.help_center),
                  onTap: () => context.push('/help'),
                ),
                SettingTile(
                  title: 'Contact Support',
                  subtitle: 'Get in touch with our team',
                  trailing: const Icon(Icons.support_agent),
                  onTap: _contactSupport,
                ),
                SettingTile(
                  title: 'Rate App',
                  subtitle: 'Rate us on the app store',
                  trailing: const Icon(Icons.star_rate),
                  onTap: _rateApp,
                ),
                SettingTile(
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  trailing: const Icon(Icons.privacy_tip),
                  onTap: () => context.push('/privacy-policy'),
                ),
                SettingTile(
                  title: 'Terms of Service',
                  subtitle: 'Read our terms of service',
                  trailing: const Icon(Icons.description),
                  onTap: () => context.push('/terms-of-service'),
                ),
                SettingTile(
                  title: 'Licenses',
                  subtitle: 'View open source licenses',
                  trailing: const Icon(Icons.code),
                  onTap: () => showLicensePage(context: context),
                ),
                SettingTile(
                  title: 'Version',
                  subtitle: _packageInfo != null
                      ? 'v${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                      : 'Loading...',
                  trailing: const Icon(Icons.info),
                  onTap: _showVersionInfo,
                ),
              ],
            ),

            // Sign Out
            if (user != null)
              Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                child: LoadingButton(
                  onPressed: _signOut,
                  isLoading: authState.isLoading,
                  text: 'Sign Out',
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(user) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.firstName?.isNotEmpty == true
                      ? user.firstName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (!user.isVerified)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Email not verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/settings/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Event Handlers

  void _selectTimezone() {
    // Show timezone selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Timezone'),
        content: const Text('Timezone selection not implemented in this demo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _authenticateBiometric() async {
    // Implement biometric authentication
    // This would use local_auth package
    return true; // Mock implementation
  }

  void _exportData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _importData() async {
    // Show file picker and import data
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This will replace all your current data. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement file picker and import logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import functionality not implemented in demo')),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() async {
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authProvider.notifier).signOut();
        if (mounted) {
          context.go('/auth/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _contactSupport() {
    // Launch email or support URL
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support functionality not implemented in demo')),
    );
  }

  void _rateApp() {
    // Launch app store rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rate app functionality not implemented in demo')),
    );
  }

  void _showVersionInfo() {
    if (_packageInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppConstants.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${_packageInfo!.version}'),
            Text('Build: ${_packageInfo!.buildNumber}'),
            Text('Package: ${_packageInfo!.packageName}'),
            const SizedBox(height: 16),
            const Text('Focus. Work. Achieve.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    context.push('/help');
  }
}