# Data Model: 番茄工作法任务与时间管理应用

**Generated**: 2025-10-03
**Branch**: `001-`
**Source**: Extracted from [spec.md](./spec.md) Key Entities section

## Core Entities

### User
Represents a person using the application across multiple devices.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `email` (String, Unique): Email address for authentication
- `password_hash` (String): Securely hashed password
- `created_at` (Timestamp): Account creation time
- `updated_at` (Timestamp): Last modification time
- `is_verified` (Boolean): Email verification status
- `preferences` (JSON): User preferences object

**User Preferences Schema**:
```json
{
  "pomodoro": {
    "work_duration": 1500,      // seconds (default: 25 minutes)
    "short_break_duration": 300, // seconds (default: 5 minutes)
    "long_break_duration": 900,  // seconds (default: 15 minutes)
    "long_break_interval": 4     // after N work sessions
  },
  "notifications": {
    "sound_enabled": true,
    "push_enabled": true,
    "reminder_timing": 900      // seconds before due date (default: 15 min)
  },
  "theme": {
    "mode": "system"            // "light" | "dark" | "system"
  }
}
```

**Relationships**:
- One-to-Many with Task
- One-to-Many with PomodoroSession
- One-to-Many with Report

**Validation Rules**:
- Email must be valid format and unique
- Password must be hashed before storage
- Preferences must conform to schema

### Task
Represents a unit of work with Pomodoro timer integration.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `user_id` (UUID, Foreign Key): Owner reference
- `title` (String, Required): Task title (max 200 chars)
- `description` (Text, Optional): Detailed description
- `due_date` (Timestamp, Optional): When task is due
- `due_time` (Time, Optional): Specific time if due_date set
- `is_completed` (Boolean): Completion status
- `created_at` (Timestamp): Creation time
- `updated_at` (Timestamp): Last modification time
- `completed_at` (Timestamp, Optional): Completion time
- `recurrence_rule_id` (UUID, Optional, Foreign Key): Recurrence pattern
- `parent_task_id` (UUID, Optional, Foreign Key): For subtasks
- `sync_version` (Integer): For conflict resolution
- `last_modified_device` (String): Device ID for last-write-wins

**Relationships**:
- Many-to-One with User
- One-to-Many with Task (subtasks)
- Many-to-One with Task (parent)
- One-to-Many with Note
- One-to-Many with PomodoroSession
- Many-to-One with RecurrenceRule
- One-to-Many with Reminder

**Validation Rules**:
- Title is required and non-empty
- Due_time requires due_date to be set
- Subtasks cannot have their own subtasks (max 2 levels)
- Completed tasks cannot be modified except completion status

**State Transitions**:
- Created → In Progress (when first Pomodoro starts)
- In Progress → Completed (when marked complete)
- Completed → In Progress (if reopened)

### Subtask
Simplified task representation for breaking down larger tasks.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `parent_task_id` (UUID, Foreign Key): Parent task reference
- `title` (String, Required): Subtask title (max 100 chars)
- `is_completed` (Boolean): Completion status
- `created_at` (Timestamp): Creation time
- `updated_at` (Timestamp): Last modification time
- `order_index` (Integer): Display order within parent

**Relationships**:
- Many-to-One with Task (parent)

**Validation Rules**:
- Title is required and non-empty
- Order_index must be unique within parent task

### PomodoroSession
Records a timed work session linked to a specific task.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `user_id` (UUID, Foreign Key): Session owner
- `task_id` (UUID, Foreign Key): Associated task
- `started_at` (Timestamp): Session start time
- `ended_at` (Timestamp, Optional): Session end time (null if active)
- `planned_duration` (Integer): Intended duration in seconds
- `actual_duration` (Integer, Optional): Actual duration if completed
- `session_type` (Enum): "work" | "short_break" | "long_break"
- `status` (Enum): "active" | "completed" | "interrupted" | "paused"
- `interruption_count` (Integer): Number of pauses during session
- `created_at` (Timestamp): Record creation time

**Relationships**:
- Many-to-One with User
- Many-to-One with Task

**Validation Rules**:
- Planned_duration must be positive
- Only one active session per user at a time
- Ended_at must be after started_at when set
- Actual_duration calculated from timestamps when session completes

**State Transitions**:
- Created → Active (when timer starts)
- Active → Paused (when user pauses)
- Paused → Active (when user resumes)
- Active/Paused → Completed (when timer finishes naturally)
- Active/Paused → Interrupted (when user stops early)

### Note
Text content attached to tasks for progress tracking.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `task_id` (UUID, Foreign Key): Associated task
- `content` (Text, Required): Plain text content (max 1000 chars)
- `created_at` (Timestamp): Note creation time
- `updated_at` (Timestamp): Last modification time

**Relationships**:
- Many-to-One with Task

**Validation Rules**:
- Content is required and non-empty
- Plain text only (no rich formatting)
- Maximum 1000 characters

### Reminder
Notification trigger for task due dates.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `task_id` (UUID, Foreign Key): Associated task
- `remind_at` (Timestamp): When to send reminder
- `is_sent` (Boolean): Whether reminder was delivered
- `created_at` (Timestamp): Reminder creation time
- `notification_type` (Enum): "push" | "email" | "both"

**Relationships**:
- Many-to-One with Task

**Validation Rules**:
- Remind_at must be before task due_date
- Cannot create reminder for tasks without due_date

**State Transitions**:
- Created → Pending (scheduled for delivery)
- Pending → Sent (after notification delivered)
- Sent → (terminal state)

### RecurrenceRule
Defines repetition patterns for recurring tasks.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `user_id` (UUID, Foreign Key): Rule owner
- `frequency` (Enum): "daily" | "weekly" | "monthly" | "custom"
- `interval` (Integer): Every N units (for custom frequency)
- `days_of_week` (Integer Array, Optional): For weekly recurrence (0=Sunday)
- `day_of_month` (Integer, Optional): For monthly recurrence
- `end_date` (Date, Optional): When recurrence stops
- `max_occurrences` (Integer, Optional): Maximum instances to create
- `created_at` (Timestamp): Rule creation time

**Relationships**:
- Many-to-One with User
- One-to-Many with Task

**Validation Rules**:
- Interval must be positive for custom frequency
- Days_of_week valid for weekly frequency only
- Day_of_month valid for monthly frequency only
- Either end_date or max_occurrences can be set, not both

### Report
Aggregated analytics data for productivity tracking.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `user_id` (UUID, Foreign Key): Report owner
- `period_start` (Date): Report period start
- `period_end` (Date): Report period end
- `report_type` (Enum): "daily" | "weekly" | "monthly" | "custom"
- `sessions_completed` (Integer): Total Pomodoro sessions
- `tasks_completed` (Integer): Total tasks finished
- `total_focus_time` (Integer): Total seconds in work sessions
- `generated_at` (Timestamp): Report generation time
- `metrics` (JSON): Detailed metrics object

**Metrics Schema**:
```json
{
  "productivity_score": 85,           // 0-100 based on goals
  "average_session_length": 1487,     // seconds
  "interruption_rate": 0.12,          // percentage
  "task_completion_rate": 0.78,       // percentage
  "focus_time_by_day": [              // array of daily totals
    {"date": "2025-10-01", "seconds": 5400},
    {"date": "2025-10-02", "seconds": 4800}
  ],
  "top_productive_hours": [14, 15, 16], // hours of day (24h format)
  "session_distribution": {
    "work": 45,
    "short_break": 12,
    "long_break": 8
  }
}
```

**Relationships**:
- Many-to-One with User

**Validation Rules**:
- Period_end must be after period_start
- Metrics must conform to schema
- Reports can be regenerated (not immutable)

## Database Indexes

**Performance Indexes**:
- `users.email` (unique)
- `tasks.user_id, tasks.created_at` (user task lists)
- `tasks.due_date` (reminder processing)
- `pomodoro_sessions.user_id, pomodoro_sessions.started_at` (user sessions)
- `notes.task_id` (task notes)
- `reminders.remind_at, reminders.is_sent` (notification processing)

**Sync Indexes**:
- `tasks.updated_at` (sync ordering)
- `tasks.sync_version` (conflict resolution)

## Sync Strategy

**Last-Write-Wins Implementation**:
1. Each modification increments `sync_version`
2. `updated_at` timestamp captures modification time
3. `last_modified_device` tracks originating device
4. Conflicts resolved by most recent `updated_at`
5. Deleted items marked with `deleted_at` timestamp (soft delete)

**Offline Queue**:
- Pending changes stored locally with operation type
- Batch sync on reconnection with conflict resolution
- Failed syncs retried with exponential backoff

This data model supports all functional requirements from the specification while maintaining ACID compliance and efficient sync across devices.