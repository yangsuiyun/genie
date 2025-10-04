import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock/wakelock.dart';

import '../../models/task.dart';
import '../../models/pomodoro_session.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/timer/circular_timer.dart';
import '../../widgets/timer/session_controls.dart';
import '../../widgets/timer/session_stats.dart';
import '../../widgets/timer/task_selector.dart';
import '../../widgets/common/loading_button.dart';
import '../../utils/audio_utils.dart';
import '../../utils/haptic_utils.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const PomodoroScreen({
    super.key,
    this.taskId,
  });

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breatheAnimation;

  Timer? _timer;
  bool _isScreenOn = true;
  String? _selectedTaskId;

  // Session state
  PomodoroSession? _currentSession;
  Duration _remainingTime = Duration.zero;
  SessionType _sessionType = SessionType.work;
  SessionState _sessionState = SessionState.ready;
  int _currentCycle = 1;
  int _totalCycles = 4;

  // Interruption tracking
  int _interruptions = 0;
  List<String> _interruptionNotes = [];

  // Completion tracking
  int? _productivityRating;
  int? _focusRating;
  String _sessionNotes = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedTaskId = widget.taskId;

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _breatheController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _breatheAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ));

    _initializeSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    _breatheController.dispose();
    Wakelock.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isScreenOn = false;
        if (_sessionState == SessionState.running) {
          _pauseSession();
        }
        break;
      case AppLifecycleState.resumed:
        _isScreenOn = true;
        // Auto-resume if session was running
        if (_sessionState == SessionState.paused && _currentSession != null) {
          _showResumeDialog();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _initializeSession() {
    final settings = ref.read(settingsProvider);

    setState(() {
      _sessionType = SessionType.work;
      _remainingTime = Duration(minutes: settings.workDuration);
      _sessionState = SessionState.ready;
      _totalCycles = settings.sessionsUntilLongBreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final settings = ref.watch(settingsProvider);
    final selectedTask = _selectedTaskId != null
        ? ref.watch(tasksProvider).tasks
            .where((t) => t.id == _selectedTaskId)
            .firstOrNull
        : null;

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _getOnBackgroundColor(),
          ),
          onPressed: _handleBackPressed,
        ),
        title: Text(
          _getSessionTitle(),
          style: TextStyle(
            color: _getOnBackgroundColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: _getOnBackgroundColor(),
            ),
            onPressed: () => _showSettingsSheet(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Task Selection
            if (_sessionState == SessionState.ready) _buildTaskSelector(selectedTask),

            // Main Timer
            Expanded(
              flex: 3,
              child: Center(
                child: _buildTimerDisplay(),
              ),
            ),

            // Session Info
            Expanded(
              flex: 1,
              child: _buildSessionInfo(),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSelector(Task? selectedTask) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TaskSelector(
        selectedTask: selectedTask,
        onTaskSelected: (task) {
          setState(() {
            _selectedTaskId = task?.id;
          });
        },
        enabled: _sessionState == SessionState.ready,
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return AnimatedBuilder(
      animation: _sessionState == SessionState.running
          ? _breatheAnimation
          : _pulseAnimation,
      builder: (context, child) {
        final scale = _sessionState == SessionState.running
            ? _breatheAnimation.value
            : (_sessionState == SessionState.paused ? _pulseAnimation.value : 1.0);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 280,
            height: 280,
            child: CircularTimer(
              duration: _getSessionDuration(),
              remaining: _remainingTime,
              isRunning: _sessionState == SessionState.running,
              sessionType: _sessionType,
              onTap: _handleTimerTap,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Cycle Progress
          Text(
            'Cycle $_currentCycle of $_totalCycles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _getOnBackgroundColor(),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // Cycle Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalCycles, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _currentCycle
                      ? _getPrimaryColor()
                      : _getOnBackgroundColor().withOpacity(0.3),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Session Stats
          if (_currentSession != null)
            SessionStats(
              session: _currentSession!,
              interruptions: _interruptions,
              textColor: _getOnBackgroundColor(),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return SessionControls(
      sessionState: _sessionState,
      sessionType: _sessionType,
      onPlay: _startSession,
      onPause: _pauseSession,
      onStop: _stopSession,
      onSkip: _skipSession,
      onInterruption: _recordInterruption,
      primaryColor: _getPrimaryColor(),
      onBackgroundColor: _getOnBackgroundColor(),
    );
  }

  // Timer Management

  void _startSession() async {
    try {
      // Enable wakelock to keep screen on
      await Wakelock.enable();

      if (_currentSession == null) {
        // Create new session
        _currentSession = await ref.read(pomodoroProvider.notifier).startSession(
          taskId: _selectedTaskId,
          type: _sessionType,
          durationMinutes: _getSessionDuration().inMinutes,
        );
      } else {
        // Resume existing session
        await ref.read(pomodoroProvider.notifier).resumeSession(_currentSession!.id);
      }

      setState(() {
        _sessionState = SessionState.running;
      });

      _startTimer();
      _startBreathingAnimation();

      // Schedule notification
      await ref.read(notificationsProvider.notifier).scheduleSessionEndNotification(
        _remainingTime,
        _sessionType,
      );

      // Haptic feedback
      HapticUtils.lightImpact();

      // Play start sound
      if (ref.read(settingsProvider).soundEnabled) {
        AudioUtils.playStartSound();
      }

    } catch (e) {
      _showError('Failed to start session: ${e.toString()}');
    }
  }

  void _pauseSession() async {
    try {
      _timer?.cancel();
      _breatheController.stop();

      if (_currentSession != null) {
        await ref.read(pomodoroProvider.notifier).pauseSession(_currentSession!.id);
      }

      setState(() {
        _sessionState = SessionState.paused;
      });

      _startPulseAnimation();

      // Cancel scheduled notification
      await ref.read(notificationsProvider.notifier).cancelSessionNotification();

      // Haptic feedback
      HapticUtils.mediumImpact();

      // Disable wakelock
      await Wakelock.disable();

    } catch (e) {
      _showError('Failed to pause session: ${e.toString()}');
    }
  }

  void _stopSession() async {
    try {
      _timer?.cancel();
      _breatheController.stop();
      _pulseController.stop();

      if (_currentSession != null) {
        // Show completion dialog if session was running
        if (_sessionState == SessionState.running || _sessionState == SessionState.paused) {
          final shouldComplete = await _showCompletionDialog();
          if (shouldComplete) {
            await _completeSession();
          } else {
            await ref.read(pomodoroProvider.notifier).cancelSession(_currentSession!.id);
          }
        }
      }

      _resetToInitialState();

      // Cancel scheduled notification
      await ref.read(notificationsProvider.notifier).cancelSessionNotification();

      // Haptic feedback
      HapticUtils.heavyImpact();

      // Disable wakelock
      await Wakelock.disable();

    } catch (e) {
      _showError('Failed to stop session: ${e.toString()}');
    }
  }

  void _skipSession() {
    _showSkipConfirmationDialog();
  }

  void _recordInterruption() async {
    if (_sessionState != SessionState.running) return;

    final note = await _showInterruptionDialog();
    if (note != null) {
      setState(() {
        _interruptions++;
        _interruptionNotes.add(note);
      });

      // Brief pause for recording interruption
      HapticUtils.mediumImpact();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        } else {
          _onSessionComplete();
        }
      });
    });
  }

  void _onSessionComplete() async {
    _timer?.cancel();
    _breatheController.stop();

    // Haptic feedback
    HapticUtils.heavyImpact();

    // Play completion sound
    if (ref.read(settingsProvider).soundEnabled) {
      AudioUtils.playCompletionSound(_sessionType);
    }

    // Show completion notification
    await ref.read(notificationsProvider.notifier).showSessionCompletedNotification(
      _sessionType,
    );

    // Complete the session
    await _completeSession();

    // Determine next session type
    _determineNextSession();
  }

  Future<void> _completeSession() async {
    if (_currentSession == null) return;

    try {
      await ref.read(pomodoroProvider.notifier).completeSession(
        _currentSession!.id,
        productivityRating: _productivityRating,
        focusRating: _focusRating,
        notes: _sessionNotes.isNotEmpty ? _sessionNotes : null,
        interruptions: _interruptions,
        interruptionNotes: _interruptionNotes,
      );

      // Update task's actual pomodoros if this was a work session
      if (_sessionType == SessionType.work && _selectedTaskId != null) {
        final task = ref.read(tasksProvider).tasks
            .where((t) => t.id == _selectedTaskId)
            .firstOrNull;

        if (task != null) {
          await ref.read(tasksProvider.notifier).updateTask(
            task.id,
            actualPomodoros: task.actualPomodoros + 1,
          );
        }
      }

    } catch (e) {
      _showError('Failed to complete session: ${e.toString()}');
    }
  }

  void _determineNextSession() {
    final settings = ref.read(settingsProvider);

    if (_sessionType == SessionType.work) {
      // Work session completed
      if (_currentCycle >= _totalCycles) {
        // Long break after completing all cycles
        _setupNextSession(SessionType.longBreak, settings.longBreakDuration);
        _currentCycle = 1; // Reset cycle count
      } else {
        // Short break
        _setupNextSession(SessionType.shortBreak, settings.shortBreakDuration);
      }
    } else {
      // Break completed, back to work
      if (_sessionType == SessionType.shortBreak) {
        _currentCycle++;
      }
      _setupNextSession(SessionType.work, settings.workDuration);
    }

    // Auto-start next session if enabled
    if (settings.autoStartNext) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _startSession();
        }
      });
    }
  }

  void _setupNextSession(SessionType type, int durationMinutes) {
    setState(() {
      _sessionType = type;
      _remainingTime = Duration(minutes: durationMinutes);
      _sessionState = SessionState.ready;
      _currentSession = null;
      _productivityRating = null;
      _focusRating = null;
      _sessionNotes = '';
      _interruptions = 0;
      _interruptionNotes.clear();
    });
  }

  void _resetToInitialState() {
    final settings = ref.read(settingsProvider);

    setState(() {
      _sessionType = SessionType.work;
      _remainingTime = Duration(minutes: settings.workDuration);
      _sessionState = SessionState.ready;
      _currentSession = null;
      _currentCycle = 1;
      _productivityRating = null;
      _focusRating = null;
      _sessionNotes = '';
      _interruptions = 0;
      _interruptionNotes.clear();
    });
  }

  // Animations

  void _startBreathingAnimation() {
    _breatheController.repeat(reverse: true);
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  // UI Helpers

  Color _getBackgroundColor() {
    switch (_sessionType) {
      case SessionType.work:
        return const Color(0xFF2D3748); // Dark blue-gray
      case SessionType.shortBreak:
        return const Color(0xFF38A169); // Green
      case SessionType.longBreak:
        return const Color(0xFF3182CE); // Blue
    }
  }

  Color _getOnBackgroundColor() {
    return Colors.white;
  }

  Color _getPrimaryColor() {
    switch (_sessionType) {
      case SessionType.work:
        return const Color(0xFFE53E3E); // Red
      case SessionType.shortBreak:
        return const Color(0xFF68D391); // Light green
      case SessionType.longBreak:
        return const Color(0xFF63B3ED); // Light blue
    }
  }

  String _getSessionTitle() {
    switch (_sessionType) {
      case SessionType.work:
        return 'Focus Time';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  Duration _getSessionDuration() {
    final settings = ref.read(settingsProvider);
    switch (_sessionType) {
      case SessionType.work:
        return Duration(minutes: settings.workDuration);
      case SessionType.shortBreak:
        return Duration(minutes: settings.shortBreakDuration);
      case SessionType.longBreak:
        return Duration(minutes: settings.longBreakDuration);
    }
  }

  // Event Handlers

  void _handleBackPressed() async {
    if (_sessionState == SessionState.running || _sessionState == SessionState.paused) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit Timer'),
          content: const Text('Are you sure you want to exit? Your current session will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Exit'),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        await _stopSession();
        if (mounted) context.pop();
      }
    } else {
      context.pop();
    }
  }

  void _handleTimerTap() {
    if (_sessionState == SessionState.ready) {
      _startSession();
    } else if (_sessionState == SessionState.running) {
      _pauseSession();
    } else if (_sessionState == SessionState.paused) {
      _startSession();
    }
  }

  // Dialogs

  Future<bool> _showCompletionDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Feedback'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your session?'),
              const SizedBox(height: 16),

              // Productivity Rating
              const Text('Productivity:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setDialogState(() {
                    _productivityRating = index + 1;
                  }),
                  icon: Icon(
                    _productivityRating != null && _productivityRating! > index
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                  ),
                )),
              ),

              const SizedBox(height: 8),

              // Focus Rating
              const Text('Focus:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setDialogState(() {
                    _focusRating = index + 1;
                  }),
                  icon: Icon(
                    _focusRating != null && _focusRating! > index
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.blue,
                  ),
                )),
              ),

              const SizedBox(height: 16),

              // Notes
              TextField(
                onChanged: (value) => _sessionNotes = value,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'How did this session go?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<String?> _showInterruptionDialog() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Interruption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What interrupted your focus?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Phone call, email notification...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Session'),
        content: Text('Are you sure you want to skip this ${_sessionType.name} session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _determineNextSession();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Session'),
        content: const Text('Would you like to resume your paused session?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _stopSession();
            },
            child: const Text('Stop Session'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startSession();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PomodoroSettingsSheet(),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

enum SessionState {
  ready,
  running,
  paused,
  completed,
}

enum SessionType {
  work,
  shortBreak,
  longBreak,
}

// Quick settings sheet for timer customization
class PomodoroSettingsSheet extends ConsumerWidget {
  const PomodoroSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timer Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Work Duration
          ListTile(
            title: const Text('Work Duration'),
            subtitle: Text('${settings.workDuration} minutes'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: settings.workDuration > 5 ? () {
                    ref.read(settingsProvider.notifier).updateSettings(
                      workDuration: settings.workDuration - 5,
                    );
                  } : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: settings.workDuration < 90 ? () {
                    ref.read(settingsProvider.notifier).updateSettings(
                      workDuration: settings.workDuration + 5,
                    );
                  } : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Short Break Duration
          ListTile(
            title: const Text('Short Break'),
            subtitle: Text('${settings.shortBreakDuration} minutes'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: settings.shortBreakDuration > 1 ? () {
                    ref.read(settingsProvider.notifier).updateSettings(
                      shortBreakDuration: settings.shortBreakDuration - 1,
                    );
                  } : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: settings.shortBreakDuration < 30 ? () {
                    ref.read(settingsProvider.notifier).updateSettings(
                      shortBreakDuration: settings.shortBreakDuration + 1,
                    );
                  } : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Long Break Duration
          ListTile(
            title: const Text('Long Break'),
            subtitle: Text('${settings.longBreakDuration} minutes'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: settings.longBreakDuration > 5 ? () {
                    ref.read(settingsProvider.notifier).updateSettings(
                      longBreakDuration: settings.longBreakDuration - 5,
                    );
                  } : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: settings.longBreakDuration < 60 ? () {
                    ref.read(settingsProvider.notifier).updateSettings(
                      longBreakDuration: settings.longBreakDuration + 5,
                    );
                  } : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          const Divider(),

          // Sound Toggle
          SwitchListTile(
            title: const Text('Sound Effects'),
            subtitle: const Text('Play sounds for session events'),
            value: settings.soundEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateSettings(
                soundEnabled: value,
              );
            },
          ),

          // Auto-start Toggle
          SwitchListTile(
            title: const Text('Auto-start Next Session'),
            subtitle: const Text('Automatically start the next session'),
            value: settings.autoStartNext,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateSettings(
                autoStartNext: value,
              );
            },
          ),

          const SizedBox(height: 24),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}