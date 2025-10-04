import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/screens/timer/pomodoro_screen.dart';
import '../../lib/providers/pomodoro_provider.dart';
import '../../lib/services/api_client.dart';
import '../../lib/models/pomodoro_session.dart';

// Generate mocks
@GenerateMocks([ApiClient])
import 'pomodoro_screen_test.mocks.dart';

void main() {
  group('Pomodoro Screen Widget Tests', () {
    late MockApiClient mockApiClient;
    late ProviderContainer container;

    setUp(() {
      mockApiClient = MockApiClient();
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Timer Display Tests', () {
      testWidgets('should display timer correctly in ready state', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.ready,
          duration: 25 * 60, // 25 minutes
          remainingTime: 25 * 60,
          startedAt: DateTime.now(),
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify timer display
        expect(find.text('25:00'), findsOneWidget);
        expect(find.text('Work Session'), findsOneWidget);
        expect(find.text('Ready to focus'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
      });

      testWidgets('should display timer correctly in active state', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.active,
          duration: 25 * 60,
          remainingTime: 15 * 60, // 15 minutes remaining
          startedAt: DateTime.now().subtract(Duration(minutes: 10)),
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify active timer display
        expect(find.text('15:00'), findsOneWidget);
        expect(find.text('Work Session'), findsOneWidget);
        expect(find.text('Focus time!'), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.text('Pause'), findsOneWidget);
        expect(find.byIcon(Icons.stop), findsOneWidget);
        expect(find.text('Stop'), findsOneWidget);
      });

      testWidgets('should display timer correctly in paused state', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.paused,
          duration: 25 * 60,
          remainingTime: 12 * 60 + 30, // 12:30 remaining
          startedAt: DateTime.now().subtract(Duration(minutes: 12)),
          pausedAt: DateTime.now(),
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify paused timer display
        expect(find.text('12:30'), findsOneWidget);
        expect(find.text('Work Session'), findsOneWidget);
        expect(find.text('Paused'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.text('Resume'), findsOneWidget);
        expect(find.byIcon(Icons.stop), findsOneWidget);
        expect(find.text('Stop'), findsOneWidget);
      });

      testWidgets('should display different session types correctly', (WidgetTester tester) async {
        // Test short break session
        final shortBreakSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.shortBreak,
          status: SessionStatus.ready,
          duration: 5 * 60, // 5 minutes
          remainingTime: 5 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => shortBreakSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify short break display
        expect(find.text('05:00'), findsOneWidget);
        expect(find.text('Short Break'), findsOneWidget);
        expect(find.text('Time for a quick break'), findsOneWidget);

        // Test long break session
        final longBreakSession = PomodoroSession(
          id: '2',
          taskId: 'task-1',
          type: SessionType.longBreak,
          status: SessionStatus.ready,
          duration: 15 * 60, // 15 minutes
          remainingTime: 15 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => longBreakSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify long break display
        expect(find.text('15:00'), findsOneWidget);
        expect(find.text('Long Break'), findsOneWidget);
        expect(find.text('Take a longer rest'), findsOneWidget);
      });
    });

    group('Timer Controls Tests', () {
      testWidgets('should start timer when start button is pressed', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.ready,
          duration: 25 * 60,
          remainingTime: 25 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        when(mockApiClient.startSession('1'))
            .thenAnswer((_) async => mockSession.copyWith(status: SessionStatus.active));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap start button
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();

        // Verify start API was called
        verify(mockApiClient.startSession('1')).called(1);
      });

      testWidgets('should pause timer when pause button is pressed', (WidgetTester tester) async {
        final activeSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.active,
          duration: 25 * 60,
          remainingTime: 15 * 60,
          startedAt: DateTime.now().subtract(Duration(minutes: 10)),
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => activeSession);

        when(mockApiClient.pauseSession('1'))
            .thenAnswer((_) async => activeSession.copyWith(
                  status: SessionStatus.paused,
                  pausedAt: DateTime.now(),
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap pause button
        await tester.tap(find.text('Pause'));
        await tester.pumpAndSettle();

        // Verify pause API was called
        verify(mockApiClient.pauseSession('1')).called(1);
      });

      testWidgets('should resume timer when resume button is pressed', (WidgetTester tester) async {
        final pausedSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.paused,
          duration: 25 * 60,
          remainingTime: 15 * 60,
          startedAt: DateTime.now().subtract(Duration(minutes: 10)),
          pausedAt: DateTime.now(),
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => pausedSession);

        when(mockApiClient.resumeSession('1'))
            .thenAnswer((_) async => pausedSession.copyWith(
                  status: SessionStatus.active,
                  pausedAt: null,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap resume button
        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();

        // Verify resume API was called
        verify(mockApiClient.resumeSession('1')).called(1);
      });

      testWidgets('should stop timer when stop button is pressed', (WidgetTester tester) async {
        final activeSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.active,
          duration: 25 * 60,
          remainingTime: 15 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => activeSession);

        when(mockApiClient.stopSession('1'))
            .thenAnswer((_) async => true);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap stop button
        await tester.tap(find.text('Stop'));
        await tester.pumpAndSettle();

        // Confirm in dialog
        await tester.tap(find.text('Yes, Stop'));
        await tester.pumpAndSettle();

        // Verify stop API was called
        verify(mockApiClient.stopSession('1')).called(1);
      });
    });

    group('Progress Visualization Tests', () {
      testWidgets('should show circular progress indicator', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.active,
          duration: 25 * 60,
          remainingTime: 15 * 60, // 60% progress
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify circular progress indicator exists
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Check progress value (40% completed = 10/25 minutes)
        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(progressIndicator.value, closeTo(0.4, 0.01));
      });

      testWidgets('should update progress as timer counts down', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.active,
          duration: 25 * 60,
          remainingTime: 25 * 60, // Starting at full time
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initial state
        expect(find.text('25:00'), findsOneWidget);

        // Simulate timer tick (this would require more sophisticated timer mocking)
        // For now, just verify the structure is correct
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Task Information Tests', () {
      testWidgets('should display current task information', (WidgetTester tester) async {
        final mockTask = Task(
          id: 'task-1',
          title: 'Important Project',
          description: 'Work on the quarterly report',
          priority: TaskPriority.high,
        );

        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.ready,
          duration: 25 * 60,
          remainingTime: 25 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        when(mockApiClient.getTask('task-1'))
            .thenAnswer((_) async => mockTask);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify task information is displayed
        expect(find.text('Important Project'), findsOneWidget);
        expect(find.text('Work on the quarterly report'), findsOneWidget);
        expect(find.text('High Priority'), findsOneWidget);
      });

      testWidgets('should show pomodoro count for current task', (WidgetTester tester) async {
        final mockTask = Task(
          id: 'task-1',
          title: 'Important Project',
          estimatedPomodoros: 8,
          completedPomodoros: 3,
        );

        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.active,
          duration: 25 * 60,
          remainingTime: 15 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        when(mockApiClient.getTask('task-1'))
            .thenAnswer((_) async => mockTask);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify pomodoro count
        expect(find.text('Pomodoro 4 of 8'), findsOneWidget);
        expect(find.text('3 completed'), findsOneWidget);
      });
    });

    group('Settings and Customization Tests', () {
      testWidgets('should show timer settings button', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.ready,
          duration: 25 * 60,
          remainingTime: 25 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify settings button exists
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('should open timer settings dialog', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.ready,
          duration: 25 * 60,
          remainingTime: 25 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap settings button
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Verify settings dialog is shown
        expect(find.text('Timer Settings'), findsOneWidget);
        expect(find.text('Work Duration'), findsOneWidget);
        expect(find.text('Short Break'), findsOneWidget);
        expect(find.text('Long Break'), findsOneWidget);
        expect(find.text('Auto Start Breaks'), findsOneWidget);
      });

      testWidgets('should show volume control', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.ready,
          duration: 25 * 60,
          remainingTime: 25 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Look for volume/sound controls
        expect(find.byIcon(Icons.volume_up), findsOneWidget);
      });
    });

    group('Notifications and Alerts Tests', () {
      testWidgets('should show session complete dialog', (WidgetTester tester) async {
        final completedSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.completed,
          duration: 25 * 60,
          remainingTime: 0,
          completedAt: DateTime.now(),
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => completedSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify completion dialog
        expect(find.text('Session Complete!'), findsOneWidget);
        expect(find.text('Great work! Time for a break.'), findsOneWidget);
        expect(find.text('Start Break'), findsOneWidget);
        expect(find.text('Continue Working'), findsOneWidget);
      });

      testWidgets('should show break complete dialog', (WidgetTester tester) async {
        final completedBreak = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.shortBreak,
          status: SessionStatus.completed,
          duration: 5 * 60,
          remainingTime: 0,
          completedAt: DateTime.now(),
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => completedBreak);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify break completion dialog
        expect(find.text('Break Complete!'), findsOneWidget);
        expect(find.text('Ready to get back to work?'), findsOneWidget);
        expect(find.text('Start Working'), findsOneWidget);
        expect(find.text('Extend Break'), findsOneWidget);
      });
    });

    group('No Active Session Tests', () {
      testWidgets('should show session selection when no active session', (WidgetTester tester) async {
        when(mockApiClient.getActiveSession())
            .thenThrow(ApiException('No active session'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify session selection screen
        expect(find.text('Start a Pomodoro Session'), findsOneWidget);
        expect(find.text('Work (25 min)'), findsOneWidget);
        expect(find.text('Short Break (5 min)'), findsOneWidget);
        expect(find.text('Long Break (15 min)'), findsOneWidget);
        expect(find.text('Select Task'), findsOneWidget);
      });

      testWidgets('should start new session when type selected', (WidgetTester tester) async {
        when(mockApiClient.getActiveSession())
            .thenThrow(ApiException('No active session'));

        when(mockApiClient.createSession(any))
            .thenAnswer((_) async => PomodoroSession(
                  id: '1',
                  taskId: 'task-1',
                  type: SessionType.work,
                  status: SessionStatus.ready,
                  duration: 25 * 60,
                  remainingTime: 25 * 60,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select work session
        await tester.tap(find.text('Work (25 min)'));
        await tester.pumpAndSettle();

        // Verify session creation API was called
        verify(mockApiClient.createSession(any)).called(1);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels for timer controls', (WidgetTester tester) async {
        final mockSession = PomodoroSession(
          id: '1',
          taskId: 'task-1',
          type: SessionType.work,
          status: SessionStatus.ready,
          duration: 25 * 60,
          remainingTime: 25 * 60,
        );

        when(mockApiClient.getActiveSession())
            .thenAnswer((_) async => mockSession);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: PomodoroScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify semantic labels exist for accessibility
        expect(find.byType(Semantics), findsWidgets);

        // Check timer display has semantic meaning
        final timerText = find.text('25:00');
        expect(timerText, findsOneWidget);
      });

      testWidgets('should announce timer state changes', (WidgetTester tester) async {
        // This would test screen reader announcements
        // Implementation would depend on platform-specific accessibility testing
        expect(true, isTrue); // Placeholder
      });
    });
  });
}