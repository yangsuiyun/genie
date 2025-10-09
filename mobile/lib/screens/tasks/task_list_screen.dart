import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../models/index.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/tasks/task_card.dart';
import '../../widgets/tasks/task_filter_bottom_sheet.dart';
import '../../widgets/tasks/task_search_delegate.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../utils/constants.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with TickerProviderStateMixin {
  static const _pageSize = 20;

  final PagingController<int, Task> _pagingController = PagingController(firstPageKey: 1);
  late TabController _tabController;

  // Filter state
  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;
  List<String> _selectedTags = [];
  String _searchQuery = '';
  TaskSortOption _sortOption = TaskSortOption.dueDate;
  bool _sortDescending = false;

  // Tab indices
  final List<TaskListTab> _tabs = [
    TaskListTab.all,
    TaskListTab.today,
    TaskListTab.upcoming,
    TaskListTab.completed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _clearFiltersAndRefresh();
    }
  }

  TaskListTab get _currentTab => _tabs[_tabController.index];

  Future<void> _fetchPage(int pageKey) async {
    try {
      final tasksNotifier = ref.read(tasksProvider.notifier);

      final result = await tasksNotifier.getTasks(
        page: pageKey,
        limit: _pageSize,
        status: _getStatusForTab(),
        priority: _selectedPriority,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortOption,
        sortDescending: _sortDescending,
        dueDateFilter: _getDueDateFilterForTab(),
      );

      final isLastPage = result.tasks.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(result.tasks);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(result.tasks, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  TaskStatus? _getStatusForTab() {
    switch (_currentTab) {
      case TaskListTab.all:
        return _selectedStatus;
      case TaskListTab.today:
      case TaskListTab.upcoming:
        return _selectedStatus ?? TaskStatus.pending;
      case TaskListTab.completed:
        return TaskStatus.completed;
    }
  }

  DateFilter? _getDueDateFilterForTab() {
    switch (_currentTab) {
      case TaskListTab.today:
        return DateFilter.today;
      case TaskListTab.upcoming:
        return DateFilter.upcoming;
      default:
        return null;
    }
  }

  void _clearFiltersAndRefresh() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedTags = [];
      _searchQuery = '';
    });
    _pagingController.refresh();
  }

  void _refreshTasks() {
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final user = ref.watch(authProvider).user;

    // Listen to task operations
    ref.listen<TasksState>(tasksProvider, (previous, next) {
      if (next.lastOperation != null) {
        switch (next.lastOperation!) {
          case TaskOperation.created:
          case TaskOperation.updated:
          case TaskOperation.deleted:
            _refreshTasks();
            break;
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (user != null)
              Text(
                'Welcome back, ${user.firstName}!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(
                  onSearchQueryChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _pagingController.refresh();
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          PopupMenuButton<TaskSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) {
              setState(() {
                if (_sortOption == option) {
                  _sortDescending = !_sortDescending;
                } else {
                  _sortOption = option;
                  _sortDescending = false;
                }
              });
              _pagingController.refresh();
            },
            itemBuilder: (context) => [
              _buildSortMenuItem(TaskSortOption.dueDate, 'Due Date'),
              _buildSortMenuItem(TaskSortOption.priority, 'Priority'),
              _buildSortMenuItem(TaskSortOption.createdAt, 'Created'),
              _buildSortMenuItem(TaskSortOption.updatedAt, 'Updated'),
              _buildSortMenuItem(TaskSortOption.title, 'Title'),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${tasksState.totalCount ?? 0})'),
            Tab(text: 'Today (${tasksState.todayCount ?? 0})'),
            Tab(text: 'Upcoming (${tasksState.upcomingCount ?? 0})'),
            Tab(text: 'Completed (${tasksState.completedCount ?? 0})'),
          ],
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: Column(
        children: [
          // Active Filters
          if (_hasActiveFilters()) _buildActiveFiltersChips(),

          // Task List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshTasks();
                // Also refresh task counts
                ref.read(tasksProvider.notifier).refreshCounts();
              },
              child: PagedListView<int, Task>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Task>(
                  itemBuilder: (context, task, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TaskCard(
                      task: task,
                      onTap: () => _navigateToTaskDetail(task),
                      onStatusChanged: (status) => _updateTaskStatus(task, status),
                      onPriorityChanged: (priority) => _updateTaskPriority(task, priority),
                      onDelete: () => _deleteTask(task),
                      onStartPomodoro: () => _startPomodoro(task),
                    ),
                  ),
                  firstPageErrorIndicatorBuilder: (context) => ErrorStateWidget(
                    error: _pagingController.error.toString(),
                    onRetry: _refreshTasks,
                  ),
                  noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(),
                  newPageErrorIndicatorBuilder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Error loading more tasks',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _refreshTasks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  firstPageProgressIndicatorBuilder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  newPageProgressIndicatorBuilder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTask(),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  PopupMenuItem<TaskSortOption> _buildSortMenuItem(TaskSortOption option, String label) {
    final isSelected = _sortOption == option;
    return PopupMenuItem<TaskSortOption>(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (isSelected)
            Icon(
              _sortDescending ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              size: 16,
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedPriority != null ||
        _selectedTags.isNotEmpty ||
        _searchQuery.isNotEmpty;
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Status: ${_selectedStatus!.displayName}'),
                onDeleted: () {
                  setState(() {
                    _selectedStatus = null;
                  });
                  _pagingController.refresh();
                },
              ),
            ),
          if (_selectedPriority != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Priority: ${_selectedPriority!.displayName}'),
                onDeleted: () {
                  setState(() {
                    _selectedPriority = null;
                  });
                  _pagingController.refresh();
                },
              ),
            ),
          ..._selectedTags.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Tag: $tag'),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                  _pagingController.refresh();
                },
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Search: "$_searchQuery"'),
                onDeleted: () {
                  setState(() {
                    _searchQuery = '';
                  });
                  _pagingController.refresh();
                },
              ),
            ),
          if (_hasActiveFilters())
            TextButton(
              onPressed: _clearFiltersAndRefresh,
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    switch (_currentTab) {
      case TaskListTab.all:
        return EmptyStateWidget(
          icon: Icons.task_alt,
          title: 'No tasks yet',
          message: 'Create your first task to get started with your productivity journey!',
          actionLabel: 'Create Task',
          onAction: _navigateToCreateTask,
        );
      case TaskListTab.today:
        return EmptyStateWidget(
          icon: Icons.today,
          title: 'No tasks for today',
          message: 'You\'re all caught up! Enjoy your free time or plan ahead.',
          actionLabel: 'Create Task',
          onAction: _navigateToCreateTask,
        );
      case TaskListTab.upcoming:
        return EmptyStateWidget(
          icon: Icons.schedule,
          title: 'No upcoming tasks',
          message: 'No tasks scheduled for the future. Great job staying on top of things!',
          actionLabel: 'Create Task',
          onAction: _navigateToCreateTask,
        );
      case TaskListTab.completed:
        return EmptyStateWidget(
          icon: Icons.check_circle_outline,
          title: 'No completed tasks',
          message: 'Complete some tasks to see your achievements here.',
        );
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskFilterBottomSheet(
        currentStatus: _selectedStatus,
        currentPriority: _selectedPriority,
        currentTags: _selectedTags,
      ),
    ).then((filters) {
      if (filters != null) {
        setState(() {
          _selectedStatus = filters['status'];
          _selectedPriority = filters['priority'];
          _selectedTags = List<String>.from(filters['tags'] ?? []);
        });
        _pagingController.refresh();
      }
    });
  }

  void _navigateToTaskDetail(Task task) {
    context.push('/tasks/${task.id}');
  }

  void _navigateToCreateTask() {
    context.push('/tasks/create').then((_) {
      // Refresh after creating a task
      _refreshTasks();
    });
  }

  void _updateTaskStatus(Task task, TaskStatus status) async {
    try {
      await ref.read(tasksProvider.notifier).updateTask(
        task.id,
        status: status,
        completedAt: status == TaskStatus.completed ? DateTime.now() : null,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task ${status.displayName.toLowerCase()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _updateTaskPriority(Task task, TaskPriority priority) async {
    try {
      await ref.read(tasksProvider.notifier).updateTask(
        task.id,
        priority: priority,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update priority: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _deleteTask(Task task) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(tasksProvider.notifier).deleteTask(task.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // Implement undo functionality if needed
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _startPomodoro(Task task) {
    context.push('/timer', extra: {'taskId': task.id});
  }
}

enum TaskListTab {
  all,
  today,
  upcoming,
  completed,
}

enum TaskSortOption {
  dueDate,
  priority,
  createdAt,
  updatedAt,
  title,
}

enum DateFilter {
  today,
  upcoming,
}