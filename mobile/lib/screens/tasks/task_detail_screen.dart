import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/index.dart';
import '../../models/subtask.dart';
import '../../models/note.dart';
import '../../models/pomodoro_session.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/subtasks_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../widgets/tasks/task_priority_selector.dart';
import '../../widgets/tasks/task_status_selector.dart';
import '../../widgets/tasks/task_tags_input.dart';
import '../../widgets/tasks/subtask_list_item.dart';
import '../../widgets/notes/note_list_item.dart';
import '../../widgets/pomodoro/session_summary_card.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_button.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../utils/date_utils.dart';
import '../../utils/validators.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedPomodorosController = TextEditingController();

  // Form state
  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;
  List<String> _selectedTags = [];
  DateTime? _selectedDueDate;
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;

  // Subtask creation
  final _subtaskController = TextEditingController();
  bool _isAddingSubtask = false;

  // Note creation
  final _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load task data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).getTask(widget.taskId);
      ref.read(subtasksProvider.notifier).getSubtasks(widget.taskId);
      ref.read(notesProvider.notifier).getTaskNotes(widget.taskId);
      ref.read(pomodoroProvider.notifier).getTaskSessions(widget.taskId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedPomodorosController.dispose();
    _subtaskController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeFormData(Task task) {
    if (!_isEditing) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _estimatedPomodorosController.text = task.estimatedPomodoros.toString();
      _selectedStatus = task.status;
      _selectedPriority = task.priority;
      _selectedTags = List.from(task.tags);
      _selectedDueDate = task.dueDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(tasksProvider);
    final task = taskState.tasks.where((t) => t.id == widget.taskId).firstOrNull;

    if (task == null && !taskState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Not Found')),
        body: const ErrorStateWidget(
          error: 'Task not found',
        ),
      );
    }

    if (task != null) {
      _initializeFormData(task);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          title: Text(_isEditing ? 'Edit Task' : 'Task Details'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
            if (_isEditing) ...[
              TextButton(
                onPressed: _hasUnsavedChanges ? _cancelEditing : null,
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _saveTask,
                child: const Text('Save'),
              ),
            ],
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'duplicate':
                    _duplicateTask(task!);
                    break;
                  case 'delete':
                    _deleteTask(task!);
                    break;
                  case 'share':
                    _shareTask(task!);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicate'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.info_outline),
                text: 'Details',
              ),
              Tab(
                icon: const Icon(Icons.checklist),
                text: 'Subtasks',
              ),
              Tab(
                icon: const Icon(Icons.note),
                text: 'Notes',
              ),
              Tab(
                icon: const Icon(Icons.timer),
                text: 'Sessions',
              ),
            ],
          ),
        ),
        body: task == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(task),
                  _buildSubtasksTab(),
                  _buildNotesTab(),
                  _buildSessionsTab(),
                ],
              ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildDetailsTab(Task task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        onChanged: () {
          if (_isEditing) {
            setState(() {
              _hasUnsavedChanges = true;
            });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            if (!_isEditing) _buildProgressCard(task),

            const SizedBox(height: 16),

            // Title
            CustomTextField(
              controller: _titleController,
              label: 'Title',
              enabled: _isEditing,
              validator: Validators.required,
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              enabled: _isEditing,
              maxLines: 4,
              minLines: 3,
            ),

            const SizedBox(height: 16),

            // Status and Priority Row
            Row(
              children: [
                Expanded(
                  child: TaskStatusSelector(
                    selectedStatus: _selectedStatus,
                    enabled: _isEditing,
                    onStatusChanged: (status) {
                      setState(() {
                        _selectedStatus = status;
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TaskPrioritySelector(
                    selectedPriority: _selectedPriority,
                    enabled: _isEditing,
                    onPriorityChanged: (priority) {
                      setState(() {
                        _selectedPriority = priority;
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Due Date
            InkWell(
              onTap: _isEditing ? _selectDueDate : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: const OutlineInputBorder(),
                  enabled: _isEditing,
                  suffixIcon: _isEditing
                      ? IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDueDate,
                        )
                      : const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDueDate != null
                      ? DateUtils.formatDate(_selectedDueDate!)
                      : 'No due date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _selectedDueDate != null
                        ? null
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estimated Pomodoros
            CustomTextField(
              controller: _estimatedPomodorosController,
              label: 'Estimated Pomodoros',
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return null;
                final number = int.tryParse(value!);
                if (number == null || number < 1) {
                  return 'Enter a valid number greater than 0';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Tags
            TaskTagsInput(
              selectedTags: _selectedTags,
              enabled: _isEditing,
              onTagsChanged: (tags) {
                setState(() {
                  _selectedTags = tags;
                  _hasUnsavedChanges = true;
                });
              },
            ),

            const SizedBox(height: 16),

            // Metadata (read-only)
            if (!_isEditing) _buildMetadataSection(task),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Task task) {
    final completedSubtasks = ref.watch(subtasksProvider)
        .subtasks
        .where((s) => s.taskId == task.id && s.status == SubtaskStatus.completed)
        .length;
    final totalSubtasks = ref.watch(subtasksProvider)
        .subtasks
        .where((s) => s.taskId == task.id)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Overall Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Progress',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: task.progressPercentage / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${task.progressPercentage.toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Subtasks',
                    '$completedSubtasks / $totalSubtasks',
                    Icons.checklist,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pomodoros',
                    '${task.actualPomodoros} / ${task.estimatedPomodoros}',
                    Icons.timer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow('Created', DateUtils.formatDateTime(task.createdAt)),
            _buildMetadataRow('Last Updated', DateUtils.formatDateTime(task.updatedAt)),
            if (task.completedAt != null)
              _buildMetadataRow('Completed', DateUtils.formatDateTime(task.completedAt!)),
            if (task.syncVersion > 1)
              _buildMetadataRow('Sync Version', task.syncVersion.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksTab() {
    final subtasksState = ref.watch(subtasksProvider);
    final subtasks = subtasksState.subtasks
        .where((s) => s.taskId == widget.taskId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Column(
      children: [
        // Add Subtask
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subtaskController,
                  decoration: InputDecoration(
                    hintText: 'Add a subtask...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSubtask,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSubtask(),
                ),
              ),
            ],
          ),
        ),

        // Subtasks List
        Expanded(
          child: subtasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subtasks yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Break down this task into smaller steps',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subtasks.length,
                  onReorder: _reorderSubtasks,
                  itemBuilder: (context, index) {
                    final subtask = subtasks[index];
                    return SubtaskListItem(
                      key: ValueKey(subtask.id),
                      subtask: subtask,
                      onStatusChanged: (status) => _updateSubtaskStatus(subtask, status),
                      onTitleChanged: (title) => _updateSubtaskTitle(subtask, title),
                      onDelete: () => _deleteSubtask(subtask),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    final notesState = ref.watch(notesProvider);
    final notes = notesState.notes
        .where((n) => n.taskId == widget.taskId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        // Add Note
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _noteController.text.isNotEmpty ? _clearNote : null,
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addNote,
                    child: const Text('Add Note'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notes List
        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add notes to capture thoughts and ideas',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteListItem(
                      note: note,
                      onTap: () => _editNote(note),
                      onDelete: () => _deleteNote(note),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    final pomodoroState = ref.watch(pomodoroProvider);
    final sessions = pomodoroState.sessions
        .where((s) => s.taskId == widget.taskId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sessions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pomodoro sessions yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a pomodoro session to track your work time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _startPomodoro(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Pomodoro'),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return SessionSummaryCard(
                session: session,
                onTap: () => _viewSessionDetail(session),
              );
            },
          );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1: // Subtasks tab
        return FloatingActionButton(
          onPressed: () {
            // Focus the subtask input field
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: const Icon(Icons.add),
        );
      case 2: // Notes tab
        return FloatingActionButton(
          onPressed: () {
            // Focus the note input field
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: const Icon(Icons.add),
        );
      case 3: // Sessions tab
        return FloatingActionButton.extended(
          onPressed: _startPomodoro,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Pomodoro'),
        );
      default:
        return null;
    }
  }

  // Event Handlers

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  void _cancelEditing() {
    final task = ref.read(tasksProvider).tasks
        .where((t) => t.id == widget.taskId)
        .firstOrNull;

    if (task != null) {
      _initializeFormData(task);
      setState(() {
        _isEditing = false;
        _hasUnsavedChanges = false;
      });
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(tasksProvider.notifier).updateTask(
        widget.taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        status: _selectedStatus,
        priority: _selectedPriority,
        tags: _selectedTags,
        dueDate: _selectedDueDate,
        estimatedPomodoros: int.tryParse(_estimatedPomodorosController.text) ?? 1,
      );

      setState(() {
        _isEditing = false;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
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

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
        _hasUnsavedChanges = true;
      });
    }
  }

  void _duplicateTask(Task task) async {
    try {
      await ref.read(tasksProvider.notifier).duplicateTask(task.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task duplicated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate task: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _deleteTask(Task task) async {
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
          context.pop(); // Go back to task list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
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

  void _shareTask(Task task) {
    // Implement task sharing functionality
    // This could generate a shareable link or export task details
  }

  // Subtask handlers
  void _addSubtask() async {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;

    try {
      final subtasks = ref.read(subtasksProvider).subtasks
          .where((s) => s.taskId == widget.taskId)
          .toList();

      await ref.read(subtasksProvider.notifier).createSubtask(
        taskId: widget.taskId,
        title: title,
        orderIndex: subtasks.length,
      );

      _subtaskController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add subtask: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _updateSubtaskStatus(Subtask subtask, SubtaskStatus status) async {
    try {
      await ref.read(subtasksProvider.notifier).updateSubtask(
        subtask.id,
        status: status,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update subtask: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _updateSubtaskTitle(Subtask subtask, String title) async {
    try {
      await ref.read(subtasksProvider.notifier).updateSubtask(
        subtask.id,
        title: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update subtask: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _deleteSubtask(Subtask subtask) async {
    try {
      await ref.read(subtasksProvider.notifier).deleteSubtask(subtask.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete subtask: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _reorderSubtasks(int oldIndex, int newIndex) async {
    final subtasks = ref.read(subtasksProvider).subtasks
        .where((s) => s.taskId == widget.taskId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final subtask = subtasks.removeAt(oldIndex);
    subtasks.insert(newIndex, subtask);

    // Update order indices
    for (int i = 0; i < subtasks.length; i++) {
      try {
        await ref.read(subtasksProvider.notifier).updateSubtask(
          subtasks[i].id,
          orderIndex: i,
        );
      } catch (e) {
        // Handle error
      }
    }
  }

  // Note handlers
  void _addNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(notesProvider.notifier).createNote(
        taskId: widget.taskId,
        content: content,
      );

      _noteController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add note: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _clearNote() {
    _noteController.clear();
  }

  void _editNote(Note note) {
    // Navigate to note edit screen
    context.push('/notes/${note.id}/edit');
  }

  void _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
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
        await ref.read(notesProvider.notifier).deleteNote(note.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete note: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  // Pomodoro handlers
  void _startPomodoro() {
    context.push('/timer', extra: {'taskId': widget.taskId});
  }

  void _viewSessionDetail(PomodoroSession session) {
    context.push('/sessions/${session.id}');
  }
}