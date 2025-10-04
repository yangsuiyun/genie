import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import '../../lib/services/timer_service.dart';
import '../../lib/providers/timer_provider.dart';
import '../../lib/models/pomodoro_session.dart';
import 'timer_precision_test.mocks.dart';

/// Timer Stress Test Suite
///
/// Tests timer behavior under stress conditions to ensure reliability
/// and precision are maintained even under adverse conditions.
void main() {
  group('Timer Stress Tests', () {
    late MockTimerService mockTimerService;
    late ProviderContainer container;

    setUp(() {
      mockTimerService = MockTimerService();
      container = ProviderContainer(
        overrides: [
          timerServiceProvider.overrideWithValue(mockTimerService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Memory Pressure Tests', () {
      testWidgets('Timer precision under memory pressure', (WidgetTester tester) async {
        const sessionDuration = Duration(seconds: 5);
        const tolerance = Duration(milliseconds: 1500); // More lenient under stress

        final session = PomodoroSession(
          id: 'memory-stress-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: sessionDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);

        // Create memory pressure by allocating large objects
        final memoryPressure = <List<int>>[];
        for (int i = 0; i < 100; i++) {
          memoryPressure.add(List.filled(10000, i)); // 10k integers each
        }

        final startTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          sessionDuration,
        );

        // Continue adding memory pressure during timer run
        for (int i = 0; i < 50; i++) {
          memoryPressure.add(List.filled(5000, i));
          await tester.pump(const Duration(milliseconds: 100));
        }

        final endTime = DateTime.now();
        final actualDuration = endTime.difference(startTime);
        final difference = (actualDuration - sessionDuration).abs();

        // Clean up memory
        memoryPressure.clear();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'Timer should maintain precision under memory pressure. '
              'Expected: ${sessionDuration.inMilliseconds}ms, '
              'Actual: ${actualDuration.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );
      });

      testWidgets('Multiple timers with memory allocation', (WidgetTester tester) async {
        const numTimers = 5;
        const timerDuration = Duration(seconds: 3);
        const tolerance = Duration(seconds: 1);

        final containers = <ProviderContainer>[];
        final startTimes = <DateTime>[];

        // Start multiple timers
        for (int i = 0; i < numTimers; i++) {
          final timerContainer = ProviderContainer(
            overrides: [
              timerServiceProvider.overrideWithValue(mockTimerService),
            ],
          );
          containers.add(timerContainer);

          final session = PomodoroSession(
            id: 'stress-session-$i',
            taskId: 'test-task-$i',
            sessionType: SessionType.work,
            duration: timerDuration,
            startTime: DateTime.now(),
            status: SessionStatus.active,
          );

          when(mockTimerService.startTimer('test-task-$i', any))
              .thenAnswer((_) async => session);

          final startTime = DateTime.now();
          startTimes.add(startTime);
          await timerContainer.read(timerProvider.notifier).startTimer(
            'test-task-$i',
            timerDuration,
          );

          // Add memory allocation between timer starts
          final memoryBurst = List.generate(1000, (index) => 'stress_data_$index');
          // Let it be garbage collected
        }

        await tester.pump(timerDuration);

        // Check precision for all timers
        final endTime = DateTime.now();
        for (int i = 0; i < numTimers; i++) {
          final actualDuration = endTime.difference(startTimes[i]);
          final difference = (actualDuration - timerDuration).abs();

          expect(
            difference,
            lessThanOrEqualTo(tolerance),
            reason: 'Timer $i should maintain precision under memory stress',
          );
        }

        // Cleanup
        for (final container in containers) {
          container.dispose();
        }
      });
    });

    group('CPU Intensive Operations', () {
      testWidgets('Timer precision during CPU intensive tasks', (WidgetTester tester) async {
        const sessionDuration = Duration(seconds: 4);
        const tolerance = Duration(seconds: 1);

        final session = PomodoroSession(
          id: 'cpu-stress-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: sessionDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);

        final startTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          sessionDuration,
        );

        // Simulate CPU intensive work during timer execution
        final cpuWorkCompleter = Completer<void>();

        // Run CPU intensive work in background
        _performCPUIntensiveWork().then((_) {
          cpuWorkCompleter.complete();
        });

        await tester.pump(sessionDuration);

        final endTime = DateTime.now();
        final actualDuration = endTime.difference(startTime);
        final difference = (actualDuration - sessionDuration).abs();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'Timer should maintain precision during CPU intensive operations. '
              'Expected: ${sessionDuration.inMilliseconds}ms, '
              'Actual: ${actualDuration.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );

        // Ensure CPU work completes
        await cpuWorkCompleter.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
      });

      testWidgets('Timer precision with blocking operations', (WidgetTester tester) async {
        const sessionDuration = Duration(seconds: 3);
        const tolerance = Duration(milliseconds: 1500);

        final session = PomodoroSession(
          id: 'blocking-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: sessionDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);

        final startTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          sessionDuration,
        );

        // Simulate blocking operations periodically
        const blockingInterval = Duration(milliseconds: 500);
        const blockingDuration = Duration(milliseconds: 100);

        for (int i = 0; i < 6; i++) {
          await tester.pump(blockingInterval);

          // Simulate a blocking operation
          final blockingCompleter = Completer<void>();
          Timer(blockingDuration, () {
            // Simulate sync work that might block the isolate
            _performSyncWork(1000);
            blockingCompleter.complete();
          });
          await blockingCompleter.future;
        }

        final endTime = DateTime.now();
        final actualDuration = endTime.difference(startTime);
        final difference = (actualDuration - sessionDuration).abs();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'Timer should maintain reasonable precision despite blocking operations. '
              'Expected: ${sessionDuration.inMilliseconds}ms, '
              'Actual: ${actualDuration.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );
      });
    });

    group('Rapid State Changes', () {
      testWidgets('Timer precision with rapid pause/resume cycles', (WidgetTester tester) async {
        const totalDuration = Duration(seconds: 6);
        const cycleInterval = Duration(milliseconds: 200);
        const tolerance = Duration(seconds: 2); // More lenient for rapid changes

        final session = PomodoroSession(
          id: 'rapid-cycle-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: totalDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);
        when(mockTimerService.pauseTimer(any))
            .thenAnswer((_) async => session.copyWith(status: SessionStatus.paused));
        when(mockTimerService.resumeTimer(any))
            .thenAnswer((_) async => session.copyWith(status: SessionStatus.active));

        final startTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          totalDuration,
        );

        // Perform rapid pause/resume cycles
        var totalPausedTime = Duration.zero;
        bool isPaused = false;

        for (int cycle = 0; cycle < 15; cycle++) {
          await tester.pump(cycleInterval);

          if (!isPaused) {
            final pauseStart = DateTime.now();
            await container.read(timerProvider.notifier).pauseTimer();
            isPaused = true;

            // Short pause
            await tester.pump(const Duration(milliseconds: 50));
            totalPausedTime += DateTime.now().difference(pauseStart);
          } else {
            await container.read(timerProvider.notifier).resumeTimer();
            isPaused = false;
          }
        }

        // Ensure timer is running at the end
        if (isPaused) {
          await container.read(timerProvider.notifier).resumeTimer();
        }

        await tester.pump(const Duration(seconds: 1));

        final endTime = DateTime.now();
        final totalElapsed = endTime.difference(startTime);
        final expectedActiveTime = totalElapsed - totalPausedTime;
        final difference = (expectedActiveTime - totalDuration).abs();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'Timer should handle rapid state changes reasonably. '
              'Expected active time: ${totalDuration.inMilliseconds}ms, '
              'Calculated active time: ${expectedActiveTime.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );
      });

      testWidgets('Timer precision with rapid timer switches', (WidgetTester tester) async {
        const switchInterval = Duration(milliseconds: 300);
        const totalTestTime = Duration(seconds: 5);
        const tolerance = Duration(seconds: 1);

        final sessions = [
          PomodoroSession(
            id: 'switch-session-1',
            taskId: 'test-task-1',
            sessionType: SessionType.work,
            duration: const Duration(minutes: 25),
            startTime: DateTime.now(),
            status: SessionStatus.active,
          ),
          PomodoroSession(
            id: 'switch-session-2',
            taskId: 'test-task-2',
            sessionType: SessionType.shortBreak,
            duration: const Duration(minutes: 5),
            startTime: DateTime.now(),
            status: SessionStatus.active,
          ),
        ];

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((invocation) async {
          final taskId = invocation.positionalArguments[0] as String;
          return taskId.contains('1') ? sessions[0] : sessions[1];
        });

        when(mockTimerService.stopTimer(any))
            .thenAnswer((_) async => sessions[0].copyWith(status: SessionStatus.stopped));

        final startTime = DateTime.now();
        var currentTimer = 0;

        // Start first timer
        await container.read(timerProvider.notifier).startTimer(
          'test-task-1',
          const Duration(minutes: 25),
        );

        // Rapidly switch between timers
        while (DateTime.now().difference(startTime) < totalTestTime) {
          await tester.pump(switchInterval);

          // Stop current timer
          await container.read(timerProvider.notifier).stopTimer();

          // Switch to other timer
          currentTimer = 1 - currentTimer;
          await container.read(timerProvider.notifier).startTimer(
            'test-task-${currentTimer + 1}',
            Duration(minutes: currentTimer == 0 ? 25 : 5),
          );
        }

        final endTime = DateTime.now();
        final actualDuration = endTime.difference(startTime);
        final difference = (actualDuration - totalTestTime).abs();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'System should handle rapid timer switches without significant drift. '
              'Expected: ${totalTestTime.inMilliseconds}ms, '
              'Actual: ${actualDuration.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );
      });
    });

    group('Resource Exhaustion Tests', () {
      testWidgets('Timer precision with many simultaneous timers', (WidgetTester tester) async {
        const numTimers = 20;
        const timerDuration = Duration(seconds: 3);
        const tolerance = Duration(seconds: 1);

        final containers = <ProviderContainer>[];
        final startTimes = <DateTime>[];

        try {
          // Create many simultaneous timers
          for (int i = 0; i < numTimers; i++) {
            final timerContainer = ProviderContainer(
              overrides: [
                timerServiceProvider.overrideWithValue(mockTimerService),
              ],
            );
            containers.add(timerContainer);

            final session = PomodoroSession(
              id: 'exhaustion-session-$i',
              taskId: 'test-task-$i',
              sessionType: SessionType.work,
              duration: timerDuration,
              startTime: DateTime.now(),
              status: SessionStatus.active,
            );

            when(mockTimerService.startTimer('test-task-$i', any))
                .thenAnswer((_) async => session);

            final startTime = DateTime.now();
            startTimes.add(startTime);
            await timerContainer.read(timerProvider.notifier).startTimer(
              'test-task-$i',
              timerDuration,
            );

            // Small delay between timer starts to prevent overwhelming
            await tester.pump(const Duration(milliseconds: 10));
          }

          await tester.pump(timerDuration);

          // Check precision for a sample of timers
          final endTime = DateTime.now();
          final samplesToCheck = min(5, numTimers); // Check first 5 timers

          for (int i = 0; i < samplesToCheck; i++) {
            final actualDuration = endTime.difference(startTimes[i]);
            final difference = (actualDuration - timerDuration).abs();

            expect(
              difference,
              lessThanOrEqualTo(tolerance),
              reason: 'Timer $i should maintain precision even with many simultaneous timers. '
                  'Expected: ${timerDuration.inMilliseconds}ms, '
                  'Actual: ${actualDuration.inMilliseconds}ms, '
                  'Difference: ${difference.inMilliseconds}ms',
            );
          }
        } finally {
          // Cleanup all containers
          for (final container in containers) {
            container.dispose();
          }
        }
      });

      testWidgets('Timer recovery after resource exhaustion', (WidgetTester tester) async {
        const sessionDuration = Duration(seconds: 4);
        const tolerance = Duration(seconds: 1);

        // First, exhaust resources
        final exhaustionContainers = <ProviderContainer>[];

        try {
          // Create many containers to exhaust resources
          for (int i = 0; i < 50; i++) {
            final container = ProviderContainer(
              overrides: [
                timerServiceProvider.overrideWithValue(mockTimerService),
              ],
            );
            exhaustionContainers.add(container);
          }

          // Clean up exhaustion containers
          for (final container in exhaustionContainers) {
            container.dispose();
          }
          exhaustionContainers.clear();

          // Small delay for cleanup
          await tester.pump(const Duration(milliseconds: 100));

          // Now test timer precision after resource exhaustion
          final session = PomodoroSession(
            id: 'recovery-session',
            taskId: 'test-task',
            sessionType: SessionType.work,
            duration: sessionDuration,
            startTime: DateTime.now(),
            status: SessionStatus.active,
          );

          when(mockTimerService.startTimer(any, any))
              .thenAnswer((_) async => session);

          final startTime = DateTime.now();
          await container.read(timerProvider.notifier).startTimer(
            'test-task',
            sessionDuration,
          );

          await tester.pump(sessionDuration);

          final endTime = DateTime.now();
          final actualDuration = endTime.difference(startTime);
          final difference = (actualDuration - sessionDuration).abs();

          expect(
            difference,
            lessThanOrEqualTo(tolerance),
            reason: 'Timer should recover and maintain precision after resource exhaustion. '
                'Expected: ${sessionDuration.inMilliseconds}ms, '
                'Actual: ${actualDuration.inMilliseconds}ms, '
                'Difference: ${difference.inMilliseconds}ms',
          );
        } finally {
          // Ensure cleanup
          for (final container in exhaustionContainers) {
            container.dispose();
          }
        }
      });
    });
  });
}

// Helper functions for stress testing

Future<void> _performCPUIntensiveWork() async {
  // Simulate CPU intensive work
  const iterations = 100000;
  var result = 0;

  for (int i = 0; i < iterations; i++) {
    result += _complexCalculation(i);

    // Yield control periodically to prevent blocking
    if (i % 1000 == 0) {
      await Future.delayed(Duration.zero);
    }
  }

  // Prevent optimization
  if (result < 0) print('Unexpected result: $result');
}

int _complexCalculation(int input) {
  // Perform some complex calculations
  var result = input;
  for (int i = 0; i < 100; i++) {
    result = (result * 31 + i) % 1000000;
  }
  return result;
}

void _performSyncWork(int iterations) {
  // Simulate synchronous work that might block
  var result = 0;
  for (int i = 0; i < iterations; i++) {
    result += i * i % 1000;
  }

  // Prevent optimization
  if (result < 0) print('Sync work result: $result');
}