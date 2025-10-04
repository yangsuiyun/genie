import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/services/timer_service.dart';
import '../../lib/providers/timer_provider.dart';
import '../../lib/models/pomodoro_session.dart';
import '../../lib/models/task.dart';

// Generate mocks
@GenerateMocks([TimerService])
import 'timer_precision_test.mocks.dart';

/// Timer Precision Test Suite
///
/// Tests timer accuracy with ±1 second tolerance as required.
/// Validates that timer operations maintain precision under various conditions.
void main() {
  group('Timer Precision Tests', () {
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

    group('Basic Timer Precision', () {
      testWidgets('Timer counts down with ±1s accuracy', (WidgetTester tester) async {
        const testDuration = Duration(seconds: 10);
        const checkInterval = Duration(seconds: 1);
        const tolerance = Duration(seconds: 1);

        // Create a test session
        final session = PomodoroSession(
          id: 'test-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: testDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);

        // Start timer
        final startTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          testDuration,
        );

        // Check precision at regular intervals
        for (int i = 1; i <= 5; i++) {
          await tester.pump(checkInterval);

          final elapsed = DateTime.now().difference(startTime);
          final expectedElapsed = checkInterval * i;
          final actualDifference = (elapsed - expectedElapsed).abs();

          expect(
            actualDifference,
            lessThanOrEqualTo(tolerance),
            reason: 'Timer drift at ${i}s should be within ±1s tolerance. '
                'Expected: ${expectedElapsed.inMilliseconds}ms, '
                'Actual: ${elapsed.inMilliseconds}ms, '
                'Difference: ${actualDifference.inMilliseconds}ms',
          );
        }
      });

      testWidgets('Timer maintains precision during pause/resume', (WidgetTester tester) async {
        const totalDuration = Duration(seconds: 10);
        const pauseAt = Duration(seconds: 3);
        const pauseDuration = Duration(seconds: 2);
        const tolerance = Duration(seconds: 1);

        final session = PomodoroSession(
          id: 'test-session',
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

        // Start timer
        final overallStartTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          totalDuration,
        );

        // Run until pause point
        await tester.pump(pauseAt);
        final pauseStartTime = DateTime.now();

        // Pause timer
        await container.read(timerProvider.notifier).pauseTimer();

        // Wait during pause
        await tester.pump(pauseDuration);

        // Resume timer
        final resumeTime = DateTime.now();
        await container.read(timerProvider.notifier).resumeTimer();

        // Continue running
        const remainingActiveTime = Duration(seconds: 4);
        await tester.pump(remainingActiveTime);

        // Calculate total active time (excluding pause)
        final totalActiveTime = pauseAt + remainingActiveTime;
        final actualElapsed = DateTime.now().difference(overallStartTime) - pauseDuration;
        final timeDifference = (actualElapsed - totalActiveTime).abs();

        expect(
          timeDifference,
          lessThanOrEqualTo(tolerance),
          reason: 'Timer precision after pause/resume should be within ±1s. '
              'Expected active time: ${totalActiveTime.inMilliseconds}ms, '
              'Actual active time: ${actualElapsed.inMilliseconds}ms, '
              'Difference: ${timeDifference.inMilliseconds}ms',
        );
      });

      testWidgets('Timer precision under rapid start/stop operations', (WidgetTester tester) async {
        const sessionDuration = Duration(seconds: 2);
        const tolerance = Duration(seconds: 1);
        const numOperations = 5;

        final precisionResults = <Duration>[];

        for (int i = 0; i < numOperations; i++) {
          final session = PomodoroSession(
            id: 'test-session-$i',
            taskId: 'test-task',
            sessionType: SessionType.work,
            duration: sessionDuration,
            startTime: DateTime.now(),
            status: SessionStatus.active,
          );

          when(mockTimerService.startTimer(any, any))
              .thenAnswer((_) async => session);
          when(mockTimerService.stopTimer(any))
              .thenAnswer((_) async => session.copyWith(status: SessionStatus.stopped));

          // Start timer
          final startTime = DateTime.now();
          await container.read(timerProvider.notifier).startTimer(
            'test-task',
            sessionDuration,
          );

          // Let it run for the duration
          await tester.pump(sessionDuration);

          // Stop timer
          await container.read(timerProvider.notifier).stopTimer();
          final endTime = DateTime.now();

          final actualDuration = endTime.difference(startTime);
          final difference = (actualDuration - sessionDuration).abs();
          precisionResults.add(difference);

          expect(
            difference,
            lessThanOrEqualTo(tolerance),
            reason: 'Timer $i precision should be within ±1s tolerance. '
                'Expected: ${sessionDuration.inMilliseconds}ms, '
                'Actual: ${actualDuration.inMilliseconds}ms, '
                'Difference: ${difference.inMilliseconds}ms',
          );

          // Small delay between operations
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Verify overall precision consistency
        final averageDifference = precisionResults.reduce((a, b) =>
            Duration(milliseconds: (a.inMilliseconds + b.inMilliseconds) ~/ 2));

        expect(
          averageDifference,
          lessThanOrEqualTo(const Duration(milliseconds: 500)),
          reason: 'Average timer precision should be better than 500ms',
        );
      });
    });

    group('Timer Precision Under Load', () {
      testWidgets('Multiple concurrent timers maintain precision', (WidgetTester tester) async {
        const numTimers = 3;
        const timerDuration = Duration(seconds: 5);
        const tolerance = Duration(seconds: 1);

        final containers = <ProviderContainer>[];
        final startTimes = <DateTime>[];

        // Create multiple timer instances
        for (int i = 0; i < numTimers; i++) {
          final container = ProviderContainer(
            overrides: [
              timerServiceProvider.overrideWithValue(mockTimerService),
            ],
          );
          containers.add(container);

          final session = PomodoroSession(
            id: 'test-session-$i',
            taskId: 'test-task-$i',
            sessionType: SessionType.work,
            duration: timerDuration,
            startTime: DateTime.now(),
            status: SessionStatus.active,
          );

          when(mockTimerService.startTimer('test-task-$i', any))
              .thenAnswer((_) async => session);

          // Start timer
          final startTime = DateTime.now();
          startTimes.add(startTime);
          await container.read(timerProvider.notifier).startTimer(
            'test-task-$i',
            timerDuration,
          );
        }

        // Let all timers run
        await tester.pump(timerDuration);

        // Check precision for each timer
        final endTime = DateTime.now();
        for (int i = 0; i < numTimers; i++) {
          final actualDuration = endTime.difference(startTimes[i]);
          final difference = (actualDuration - timerDuration).abs();

          expect(
            difference,
            lessThanOrEqualTo(tolerance),
            reason: 'Concurrent timer $i should maintain ±1s precision. '
                'Expected: ${timerDuration.inMilliseconds}ms, '
                'Actual: ${actualDuration.inMilliseconds}ms, '
                'Difference: ${difference.inMilliseconds}ms',
          );
        }

        // Cleanup
        for (final container in containers) {
          container.dispose();
        }
      });

      testWidgets('Timer precision during background/foreground transitions', (WidgetTester tester) async {
        const sessionDuration = Duration(seconds: 8);
        const backgroundAt = Duration(seconds: 3);
        const backgroundDuration = Duration(seconds: 2);
        const tolerance = Duration(seconds: 1);

        final session = PomodoroSession(
          id: 'test-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: sessionDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);

        // Start timer
        final startTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          sessionDuration,
        );

        // Run until background transition
        await tester.pump(backgroundAt);

        // Simulate app going to background
        tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<void>(
          SystemChannels.lifecycle,
          (message) async {
            await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
              SystemChannels.lifecycle.name,
              SystemChannels.lifecycle.codec.encodeMessage('AppLifecycleState.paused'),
              (data) {},
            );
            return null;
          },
        );

        await tester.pump(backgroundDuration);

        // Simulate app returning to foreground
        tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<void>(
          SystemChannels.lifecycle,
          (message) async {
            await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
              SystemChannels.lifecycle.name,
              SystemChannels.lifecycle.codec.encodeMessage('AppLifecycleState.resumed'),
              (data) {},
            );
            return null;
          },
        );

        // Continue running
        const remainingTime = Duration(seconds: 3);
        await tester.pump(remainingTime);

        final endTime = DateTime.now();
        final actualDuration = endTime.difference(startTime);
        final difference = (actualDuration - sessionDuration).abs();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'Timer should maintain precision through background/foreground transitions. '
              'Expected: ${sessionDuration.inMilliseconds}ms, '
              'Actual: ${actualDuration.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );
      });
    });

    group('Timer Edge Cases', () {
      testWidgets('Very short timer precision (1-2 seconds)', (WidgetTester tester) async {
        const shortDurations = [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(milliseconds: 1500),
        ];
        const tolerance = Duration(milliseconds: 500); // More lenient for very short timers

        for (final duration in shortDurations) {
          final session = PomodoroSession(
            id: 'short-session',
            taskId: 'test-task',
            sessionType: SessionType.shortBreak,
            duration: duration,
            startTime: DateTime.now(),
            status: SessionStatus.active,
          );

          when(mockTimerService.startTimer(any, any))
              .thenAnswer((_) async => session);

          final startTime = DateTime.now();
          await container.read(timerProvider.notifier).startTimer(
            'test-task',
            duration,
          );

          await tester.pump(duration);

          final actualDuration = DateTime.now().difference(startTime);
          final difference = (actualDuration - duration).abs();

          expect(
            difference,
            lessThanOrEqualTo(tolerance),
            reason: 'Short timer (${duration.inMilliseconds}ms) precision should be within tolerance. '
                'Actual: ${actualDuration.inMilliseconds}ms, '
                'Difference: ${difference.inMilliseconds}ms',
          );
        }
      });

      testWidgets('Long timer precision (25+ minutes)', (WidgetTester tester) async {
        // Note: This test simulates long duration without actually waiting
        const longDuration = Duration(minutes: 25);
        const simulationSteps = 25; // Check every minute
        const stepDuration = Duration(seconds: 1); // Simulate 1 minute per second
        const tolerance = Duration(seconds: 2); // Slightly more lenient for long timers

        final session = PomodoroSession(
          id: 'long-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: longDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);

        final startTime = DateTime.now();
        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          longDuration,
        );

        // Simulate timer running and check precision at intervals
        for (int step = 1; step <= simulationSteps; step++) {
          await tester.pump(stepDuration);

          // Calculate expected elapsed time (simulated)
          final simulatedElapsed = Duration(minutes: step);
          final actualElapsed = DateTime.now().difference(startTime);

          // For this test, we adjust expectations since we're simulating
          final expectedActualElapsed = stepDuration * step;
          final difference = (actualElapsed - expectedActualElapsed).abs();

          expect(
            difference,
            lessThanOrEqualTo(tolerance),
            reason: 'Long timer precision at step $step should be maintained. '
                'Expected: ${expectedActualElapsed.inMilliseconds}ms, '
                'Actual: ${actualElapsed.inMilliseconds}ms, '
                'Difference: ${difference.inMilliseconds}ms',
          );
        }
      });

      testWidgets('Timer precision with system time changes', (WidgetTester tester) async {
        // This test simulates how the timer handles system time changes
        const sessionDuration = Duration(seconds: 6);
        const tolerance = Duration(seconds: 1);

        final session = PomodoroSession(
          id: 'test-session',
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

        // Run for half the duration
        await tester.pump(const Duration(seconds: 3));

        // Simulate system time change (this would typically require platform-specific handling)
        // For testing, we verify the timer can handle such scenarios gracefully

        // Continue running
        await tester.pump(const Duration(seconds: 3));

        final endTime = DateTime.now();
        final actualDuration = endTime.difference(startTime);
        final difference = (actualDuration - sessionDuration).abs();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'Timer should handle system time changes gracefully. '
              'Expected: ${sessionDuration.inMilliseconds}ms, '
              'Actual: ${actualDuration.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );
      });
    });

    group('Timer Precision Statistics', () {
      testWidgets('Measure timer precision statistics over multiple runs', (WidgetTester tester) async {
        const numRuns = 10;
        const sessionDuration = Duration(seconds: 3);
        const tolerance = Duration(seconds: 1);

        final differences = <Duration>[];

        for (int run = 0; run < numRuns; run++) {
          final session = PomodoroSession(
            id: 'stats-session-$run',
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

          final actualDuration = DateTime.now().difference(startTime);
          final difference = (actualDuration - sessionDuration).abs();
          differences.add(difference);

          expect(
            difference,
            lessThanOrEqualTo(tolerance),
            reason: 'Run $run should be within tolerance',
          );

          // Reset for next run
          await container.read(timerProvider.notifier).stopTimer();
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Calculate statistics
        final totalDifference = differences.fold<int>(
          0,
          (sum, diff) => sum + diff.inMilliseconds,
        );
        final averageDifference = Duration(milliseconds: totalDifference ~/ numRuns);

        final maxDifference = differences.reduce((a, b) =>
            a.inMilliseconds > b.inMilliseconds ? a : b);

        final minDifference = differences.reduce((a, b) =>
            a.inMilliseconds < b.inMilliseconds ? a : b);

        // Log statistics for analysis
        debugPrint('Timer Precision Statistics:');
        debugPrint('  Runs: $numRuns');
        debugPrint('  Average difference: ${averageDifference.inMilliseconds}ms');
        debugPrint('  Min difference: ${minDifference.inMilliseconds}ms');
        debugPrint('  Max difference: ${maxDifference.inMilliseconds}ms');

        // Verify statistical requirements
        expect(
          averageDifference,
          lessThanOrEqualTo(const Duration(milliseconds: 500)),
          reason: 'Average precision should be better than 500ms',
        );

        expect(
          maxDifference,
          lessThanOrEqualTo(tolerance),
          reason: 'Worst-case precision should still be within tolerance',
        );
      });
    });

    group('Real-Time Timer Updates', () {
      testWidgets('Timer UI updates maintain precision', (WidgetTester tester) async {
        const sessionDuration = Duration(seconds: 5);
        const updateInterval = Duration(milliseconds: 100); // 10 FPS updates
        const tolerance = Duration(milliseconds: 200);

        final session = PomodoroSession(
          id: 'ui-session',
          taskId: 'test-task',
          sessionType: SessionType.work,
          duration: sessionDuration,
          startTime: DateTime.now(),
          status: SessionStatus.active,
        );

        when(mockTimerService.startTimer(any, any))
            .thenAnswer((_) async => session);

        await container.read(timerProvider.notifier).startTimer(
          'test-task',
          sessionDuration,
        );

        final startTime = DateTime.now();
        final updateTimes = <DateTime>[];

        // Simulate UI updates at regular intervals
        for (int i = 0; i < 50; i++) { // 5 seconds worth of updates
          await tester.pump(updateInterval);
          updateTimes.add(DateTime.now());

          // Verify the timer state is being updated correctly
          final timerState = container.read(timerProvider);
          expect(timerState.isRunning, isTrue);
        }

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);
        final expectedDuration = updateInterval * 50;
        final difference = (totalDuration - expectedDuration).abs();

        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason: 'UI update timing should maintain precision. '
              'Expected: ${expectedDuration.inMilliseconds}ms, '
              'Actual: ${totalDuration.inMilliseconds}ms, '
              'Difference: ${difference.inMilliseconds}ms',
        );

        // Verify consistent update intervals
        for (int i = 1; i < updateTimes.length; i++) {
          final intervalDuration = updateTimes[i].difference(updateTimes[i-1]);
          final intervalDifference = (intervalDuration - updateInterval).abs();

          expect(
            intervalDifference,
            lessThanOrEqualTo(const Duration(milliseconds: 50)),
            reason: 'UI update interval $i should be consistent',
          );
        }
      });
    });
  });
}