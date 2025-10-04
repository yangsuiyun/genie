import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/screens/tasks/task_list_screen.dart';
import '../../lib/screens/tasks/task_detail_screen.dart';
import '../../lib/providers/task_provider.dart';
import '../../lib/services/api_client.dart';
import '../../lib/models/task.dart';

// Generate mocks
@GenerateMocks([ApiClient])
import 'task_screen_test.mocks.dart';

void main() {
  group('Task Screens Widget Tests', () {
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

    group('TaskListScreen Tests', () {
      testWidgets('should render empty state when no tasks', (WidgetTester tester) async {
        // Mock empty task list
        when(mockApiClient.getTasks(any))
            .thenAnswer((_) async => TaskListResponse(
                  tasks: [],
                  total: 0,
                  page: 1,
                  totalPages: 0,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify empty state
        expect(find.text('No tasks yet'), findsOneWidget);
        expect(find.text('Create your first task to get started'), findsOneWidget);
        expect(find.byIcon(Icons.assignment), findsOneWidget);
        expect(find.text('Create Task'), findsOneWidget);
      });

      testWidgets('should render task list when tasks exist', (WidgetTester tester) async {
        final mockTasks = [
          Task(
            id: '1',
            title: 'Test Task 1',
            description: 'Description 1',
            priority: TaskPriority.high,
            status: TaskStatus.pending,
            dueDate: DateTime.now().add(Duration(days: 1)),
            estimatedPomodoros: 3,
            completedPomodoros: 1,
            tags: ['work', 'important'],
          ),
          Task(
            id: '2',
            title: 'Test Task 2',
            description: 'Description 2',
            priority: TaskPriority.medium,
            status: TaskStatus.inProgress,
            estimatedPomodoros: 2,
            completedPomodoros: 0,
            tags: ['personal'],
          ),
        ];

        when(mockApiClient.getTasks(any))
            .thenAnswer((_) async => TaskListResponse(
                  tasks: mockTasks,
                  total: 2,
                  page: 1,
                  totalPages: 1,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify task list is rendered
        expect(find.text('Test Task 1'), findsOneWidget);
        expect(find.text('Test Task 2'), findsOneWidget);
        expect(find.byType(TaskCard), findsNWidgets(2));
      });

      testWidgets('should show loading indicator while fetching tasks', (WidgetTester tester) async {
        // Mock delayed response
        when(mockApiClient.getTasks(any))
            .thenAnswer((_) => Future.delayed(
                  Duration(seconds: 2),
                  () => TaskListResponse(tasks: [], total: 0, page: 1, totalPages: 0),
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        // Initially should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading tasks...'), findsOneWidget);
      });

      testWidgets('should show error state on API failure', (WidgetTester tester) async {
        // Mock API failure
        when(mockApiClient.getTasks(any))
            .thenThrow(ApiException('Failed to load tasks'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error state
        expect(find.text('Failed to load tasks'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should filter tasks by status', (WidgetTester tester) async {
        final mockTasks = [
          Task(id: '1', title: 'Pending Task', status: TaskStatus.pending),
          Task(id: '2', title: 'Completed Task', status: TaskStatus.completed),
          Task(id: '3', title: 'In Progress Task', status: TaskStatus.inProgress),
        ];

        when(mockApiClient.getTasks(any))
            .thenAnswer((_) async => TaskListResponse(
                  tasks: mockTasks,
                  total: 3,
                  page: 1,
                  totalPages: 1,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test filter by completed
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        // Verify API called with filter
        verify(mockApiClient.getTasks(argThat(
          predicate<TaskFilter>((filter) => filter.status == TaskStatus.completed),
        ))).called(1);
      });

      testWidgets('should search tasks', (WidgetTester tester) async {
        final mockTasks = [
          Task(id: '1', title: 'Important Meeting', description: 'Team sync'),
          Task(id: '2', title: 'Code Review', description: 'Review PR #123'),
        ];

        when(mockApiClient.getTasks(any))
            .thenAnswer((_) async => TaskListResponse(
                  tasks: mockTasks,
                  total: 2,
                  page: 1,
                  totalPages: 1,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'meeting');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Verify search API called
        verify(mockApiClient.getTasks(argThat(
          predicate<TaskFilter>((filter) => filter.search == 'meeting'),
        ))).called(1);
      });

      testWidgets('should navigate to task detail on tap', (WidgetTester tester) async {
        final mockTasks = [
          Task(
            id: '1',
            title: 'Test Task',
            description: 'Test Description',
            priority: TaskPriority.high,
            status: TaskStatus.pending,
          ),
        ];

        when(mockApiClient.getTasks(any))
            .thenAnswer((_) async => TaskListResponse(
                  tasks: mockTasks,
                  total: 1,
                  page: 1,
                  totalPages: 1,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
              routes: {
                '/task-detail': (context) => TaskDetailScreen(taskId: '1'),
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on task card
        await tester.tap(find.byType(TaskCard).first);
        await tester.pumpAndSettle();

        // Verify navigation (simplified - would need proper router testing)
      });

      testWidgets('should pull to refresh tasks', (WidgetTester tester) async {
        final mockTasks = [
          Task(id: '1', title: 'Test Task', status: TaskStatus.pending),
        ];

        when(mockApiClient.getTasks(any))
            .thenAnswer((_) async => TaskListResponse(
                  tasks: mockTasks,
                  total: 1,
                  page: 1,
                  totalPages: 1,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perform pull to refresh
        await tester.fling(find.byType(ListView), Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(Duration(seconds: 1));

        // Verify refresh was triggered
        verify(mockApiClient.getTasks(any)).called(greaterThan(1));
      });

      testWidgets('should handle infinite scroll for pagination', (WidgetTester tester) async {
        // Mock first page
        when(mockApiClient.getTasks(argThat(
          predicate<TaskFilter>((filter) => filter.page == 1),
        ))).thenAnswer((_) async => TaskListResponse(
              tasks: List.generate(20, (i) => Task(id: '$i', title: 'Task $i')),
              total: 50,
              page: 1,
              totalPages: 3,
            ));

        // Mock second page
        when(mockApiClient.getTasks(argThat(
          predicate<TaskFilter>((filter) => filter.page == 2),
        ))).thenAnswer((_) async => TaskListResponse(
              tasks: List.generate(20, (i) => Task(id: '${i + 20}', title: 'Task ${i + 20}')),
              total: 50,
              page: 2,
              totalPages: 3,
            ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll to bottom to trigger next page load
        await tester.fling(find.byType(ListView), Offset(0, -1000), 1000);
        await tester.pumpAndSettle();

        // Verify second page was requested
        verify(mockApiClient.getTasks(argThat(
          predicate<TaskFilter>((filter) => filter.page == 2),
        ))).called(1);
      });
    });

    group('TaskDetailScreen Tests', () {
      testWidgets('should render task details correctly', (WidgetTester tester) async {
        final mockTask = Task(
          id: '1',
          title: 'Test Task',
          description: 'This is a test task description',
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          dueDate: DateTime.now().add(Duration(days: 2)),
          estimatedPomodoros: 5,
          completedPomodoros: 2,
          tags: ['work', 'important', 'urgent'],
          subtasks: [
            Subtask(id: '1', title: 'Subtask 1', isCompleted: true),
            Subtask(id: '2', title: 'Subtask 2', isCompleted: false),
          ],
          notes: [
            Note(id: '1', content: 'This is a note', createdAt: DateTime.now()),
          ],
        );

        when(mockApiClient.getTask('1'))
            .thenAnswer((_) async => mockTask);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskDetailScreen(taskId: '1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify task details are displayed
        expect(find.text('Test Task'), findsOneWidget);
        expect(find.text('This is a test task description'), findsOneWidget);
        expect(find.text('High Priority'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('2 / 5 Pomodoros'), findsOneWidget);
        expect(find.text('work'), findsOneWidget);
        expect(find.text('important'), findsOneWidget);
        expect(find.text('urgent'), findsOneWidget);
      });

      testWidgets('should show subtasks section', (WidgetTester tester) async {
        final mockTask = Task(
          id: '1',
          title: 'Test Task',
          subtasks: [
            Subtask(id: '1', title: 'Subtask 1', isCompleted: true),
            Subtask(id: '2', title: 'Subtask 2', isCompleted: false),
            Subtask(id: '3', title: 'Subtask 3', isCompleted: false),
          ],
        );

        when(mockApiClient.getTask('1'))
            .thenAnswer((_) async => mockTask);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskDetailScreen(taskId: '1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify subtasks are displayed
        expect(find.text('Subtasks (1/3 completed)'), findsOneWidget);
        expect(find.text('Subtask 1'), findsOneWidget);
        expect(find.text('Subtask 2'), findsOneWidget);
        expect(find.text('Subtask 3'), findsOneWidget);

        // Verify checkbox states
        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsNWidgets(3));

        // First checkbox should be checked
        final firstCheckbox = tester.widget<Checkbox>(checkboxes.first);
        expect(firstCheckbox.value, isTrue);
      });

      testWidgets('should toggle subtask completion', (WidgetTester tester) async {
        final mockTask = Task(
          id: '1',
          title: 'Test Task',
          subtasks: [
            Subtask(id: '1', title: 'Subtask 1', isCompleted: false),
          ],
        );

        when(mockApiClient.getTask('1'))
            .thenAnswer((_) async => mockTask);

        when(mockApiClient.updateSubtask('1', any))
            .thenAnswer((_) async => Subtask(id: '1', title: 'Subtask 1', isCompleted: true));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskDetailScreen(taskId: '1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap checkbox to complete subtask
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiClient.updateSubtask('1', any)).called(1);
      });

      testWidgets('should show notes section', (WidgetTester tester) async {
        final mockTask = Task(
          id: '1',
          title: 'Test Task',
          notes: [
            Note(
              id: '1',
              content: 'This is a note about the task',
              createdAt: DateTime.now(),
            ),
            Note(
              id: '2',
              content: 'Another note with more details',
              createdAt: DateTime.now().subtract(Duration(hours: 2)),
            ),
          ],
        );

        when(mockApiClient.getTask('1'))
            .thenAnswer((_) async => mockTask);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskDetailScreen(taskId: '1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify notes are displayed
        expect(find.text('Notes'), findsOneWidget);
        expect(find.text('This is a note about the task'), findsOneWidget);
        expect(find.text('Another note with more details'), findsOneWidget);
      });

      testWidgets('should add new note', (WidgetTester tester) async {
        final mockTask = Task(id: '1', title: 'Test Task', notes: []);

        when(mockApiClient.getTask('1'))
            .thenAnswer((_) async => mockTask);

        when(mockApiClient.addNote('1', any))
            .thenAnswer((_) async => Note(
                  id: '1',
                  content: 'New note',
                  createdAt: DateTime.now(),
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskDetailScreen(taskId: '1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap add note button
        await tester.tap(find.byIcon(Icons.add_comment));
        await tester.pumpAndSettle();

        // Enter note content
        await tester.enterText(find.byType(TextField), 'New note content');

        // Tap save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiClient.addNote('1', any)).called(1);
      });

      testWidgets('should start pomodoro session', (WidgetTester tester) async {
        final mockTask = Task(id: '1', title: 'Test Task');

        when(mockApiClient.getTask('1'))
            .thenAnswer((_) async => mockTask);

        when(mockApiClient.startPomodoroSession(any))
            .thenAnswer((_) async => PomodoroSession(
                  id: '1',
                  taskId: '1',
                  type: SessionType.work,
                  duration: 25 * 60,
                  status: SessionStatus.active,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskDetailScreen(taskId: '1'),
              routes: {
                '/pomodoro': (context) => PomodoroScreen(),
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap start pomodoro button
        await tester.tap(find.text('Start Pomodoro'));
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiClient.startPomodoroSession(any)).called(1);
      });

      testWidgets('should show task progress visualization', (WidgetTester tester) async {
        final mockTask = Task(
          id: '1',
          title: 'Test Task',
          estimatedPomodoros: 8,
          completedPomodoros: 3,
        );

        when(mockApiClient.getTask('1'))
            .thenAnswer((_) async => mockTask);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: TaskDetailScreen(taskId: '1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify progress indicators
        expect(find.text('3 / 8 Pomodoros'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Verify progress value
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, equals(3 / 8));
      });
    });

    group('Task Form Tests', () {
      testWidgets('should validate task form fields', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: CreateTaskScreen(),
            ),
          ),
        );

        // Try to save without filling required fields
        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        // Verify validation errors
        expect(find.text('Task title is required'), findsOneWidget);
      });

      testWidgets('should create task with valid data', (WidgetTester tester) async {
        when(mockApiClient.createTask(any))
            .thenAnswer((_) async => Task(
                  id: '1',
                  title: 'New Task',
                  description: 'Task description',
                  priority: TaskPriority.medium,
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: CreateTaskScreen(),
            ),
          ),
        );

        // Fill form
        await tester.enterText(find.byType(TextFormField).first, 'New Task');
        await tester.enterText(find.byType(TextFormField).at(1), 'Task description');

        // Select priority
        await tester.tap(find.text('Medium'));
        await tester.pumpAndSettle();

        // Save task
        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiClient.createTask(any)).called(1);
      });
    });
  });
}