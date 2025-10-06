# Data Model: Project Management System

**Feature**: 002- Project Management System
**Date**: 2025-10-05

## Entity Relationship Diagram

```
┌─────────────────────────┐
│       User              │
│  (existing entity)      │
└───────────┬─────────────┘
            │
            │ has_many
            ▼
┌─────────────────────────┐
│       Project           │◄──── NEW ENTITY
│─────────────────────────│
│ id: UUID (PK)           │
│ user_id: UUID (FK)      │
│ name: String(255)       │
│ description: Text       │
│ is_default: Boolean     │
│ is_completed: Boolean   │
│ created_at: Timestamp   │
│ updated_at: Timestamp   │
└───────────┬─────────────┘
            │
            │ has_many
            ▼
┌─────────────────────────┐
│        Task             │
│ (modified entity)       │
│─────────────────────────│
│ id: UUID (PK)           │
│ project_id: UUID (FK) ◄─┼─ NEW FIELD (required)
│ user_id: UUID (FK)      │
│ name: String(255)       │
│ description: Text       │
│ priority: Integer       │
│ is_completed: Boolean   │
│ due_date: Timestamp?    │
│ estimated_pomodoros: Int│
│ completed_pomodoros: Int│
│ created_at: Timestamp   │
│ updated_at: Timestamp   │
└───────────┬─────────────┘
            │
            │ has_many
            ▼
┌─────────────────────────┐
│   PomodoroSession       │
│ (modified entity)       │
│─────────────────────────│
│ id: UUID (PK)           │
│ task_id: UUID (FK)      │
│ project_id: UUID (FK) ◄─┼─ NEW FIELD (required)
│ user_id: UUID (FK)      │
│ start_time: Timestamp   │
│ end_time: Timestamp?    │
│ duration: Integer       │
│ session_type: Enum      │
│ is_completed: Boolean   │
│ created_at: Timestamp   │
└─────────────────────────┘
```

## Entities

### Project (NEW)

**Purpose**: Represents a collection of related tasks working towards a common goal.

**Attributes**:

| Field         | Type         | Constraints                  | Description                                  |
|---------------|--------------|------------------------------|----------------------------------------------|
| id            | UUID         | PRIMARY KEY                  | Unique project identifier                    |
| user_id       | UUID         | NOT NULL, FK(users.id)       | Owner of the project                         |
| name          | VARCHAR(255) | NOT NULL, INDEX              | Project name (unique per user)               |
| description   | TEXT         | NULL                         | Optional project description                 |
| is_default    | BOOLEAN      | NOT NULL, DEFAULT false      | True for "Inbox" project                     |
| is_completed  | BOOLEAN      | NOT NULL, DEFAULT false      | User-controlled completion status            |
| created_at    | TIMESTAMP    | NOT NULL, DEFAULT NOW()      | Creation timestamp                           |
| updated_at    | TIMESTAMP    | NOT NULL, DEFAULT NOW()      | Last update timestamp                        |

**Relationships**:
- `belongs_to` User (via user_id)
- `has_many` Tasks (via tasks.project_id)
- `has_many` PomodoroSessions (via pomodoro_sessions.project_id)

**Business Rules**:
1. Project name must be unique per user
2. Only ONE project per user can have `is_default = true`
3. Default project ("Inbox") cannot be deleted
4. Default project CAN be renamed
5. Project completion is manual (independent of task completion)
6. Deleting a project cascades to all tasks and sessions

**Indexes**:
```sql
CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE UNIQUE INDEX idx_projects_user_name ON projects(user_id, name);
CREATE UNIQUE INDEX idx_projects_is_default ON projects(user_id, is_default) WHERE is_default = true;
```

**Validation Rules**:
- `name`: 1-255 characters, no leading/trailing whitespace
- `description`: Max 2000 characters (optional)
- `is_default`: Exactly one per user
- `is_completed`: Can be toggled regardless of task status

---

### Task (MODIFIED)

**Purpose**: Represents an individual work item that belongs to a project.

**New/Modified Attributes**:

| Field       | Type | Constraints            | Description                  | Change   |
|-------------|------|------------------------|------------------------------|----------|
| project_id  | UUID | NOT NULL, FK, INDEX    | Parent project reference     | **NEW**  |

**Relationships**:
- `belongs_to` Project (via project_id) - **NEW, MANDATORY**
- `belongs_to` User (via user_id) - existing
- `has_many` PomodoroSessions (via sessions.task_id) - existing

**Business Rules**:
1. Every task MUST belong to exactly one project (no orphans)
2. Cannot create task without specifying project_id
3. Can move task between projects (change project_id)
4. Deleted when parent project is deleted (CASCADE)
5. Tasks in completed projects remain fully editable

**Modified Indexes**:
```sql
-- New index
CREATE INDEX idx_tasks_project_id ON tasks(project_id);

-- Composite index for common query
CREATE INDEX idx_tasks_project_completed ON tasks(project_id, is_completed);
```

**Modified Validation**:
- `project_id`: REQUIRED, must reference existing project owned by same user

---

### PomodoroSession (MODIFIED)

**Purpose**: Represents a focused work period on a specific task within a project.

**New/Modified Attributes**:

| Field       | Type | Constraints         | Description                | Change   |
|-------------|------|---------------------|----------------------------|----------|
| project_id  | UUID | NOT NULL, FK, INDEX | Associated project         | **NEW**  |

**Relationships**:
- `belongs_to` Task (via task_id) - existing
- `belongs_to` Project (via project_id) - **NEW**
- `belongs_to` User (via user_id) - existing

**Business Rules**:
1. `project_id` is automatically derived from `task.project_id` when session created
2. If task is moved to another project, session's project_id updates automatically (via trigger)
3. Deleted when parent project is deleted (CASCADE)
4. Must be linked to both task AND project

**Modified Indexes**:
```sql
-- New index for project-based queries
CREATE INDEX idx_sessions_project_id ON pomodoro_sessions(project_id);

-- Composite for statistics
CREATE INDEX idx_sessions_project_completed ON pomodoro_sessions(project_id, is_completed);
```

**Database Trigger** (maintain project_id consistency):
```sql
CREATE OR REPLACE FUNCTION sync_session_project_id()
RETURNS TRIGGER AS $$
BEGIN
  -- Auto-set project_id from task when inserting
  IF TG_OP = 'INSERT' THEN
    SELECT project_id INTO NEW.project_id
    FROM tasks WHERE id = NEW.task_id;
  END IF;

  -- Update project_id if task is moved to different project
  IF TG_OP = 'UPDATE' AND OLD.task_id != NEW.task_id THEN
    SELECT project_id INTO NEW.project_id
    FROM tasks WHERE id = NEW.task_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_session_project_id
  BEFORE INSERT OR UPDATE ON pomodoro_sessions
  FOR EACH ROW EXECUTE FUNCTION sync_session_project_id();
```

---

## Database Constraints

### Foreign Keys

```sql
-- Project relationships
ALTER TABLE projects
  ADD CONSTRAINT fk_projects_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Task relationships (modified)
ALTER TABLE tasks
  ADD CONSTRAINT fk_tasks_project
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

-- Session relationships (modified)
ALTER TABLE pomodoro_sessions
  ADD CONSTRAINT fk_sessions_project
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
```

### Unique Constraints

```sql
-- One default project per user
CREATE UNIQUE INDEX idx_projects_is_default
  ON projects(user_id, is_default)
  WHERE is_default = true;

-- Unique project name per user
CREATE UNIQUE INDEX idx_projects_user_name
  ON projects(user_id, name);
```

### Check Constraints

```sql
-- Project name length
ALTER TABLE projects
  ADD CONSTRAINT chk_project_name_length
  CHECK (LENGTH(TRIM(name)) >= 1 AND LENGTH(name) <= 255);

-- Description length
ALTER TABLE projects
  ADD CONSTRAINT chk_project_description_length
  CHECK (description IS NULL OR LENGTH(description) <= 2000);
```

---

## Computed/Virtual Fields

These fields are calculated on-demand, not stored:

### Project Statistics

```go
type ProjectStatistics struct {
    TotalTasks         int       `json:"total_tasks"`
    CompletedTasks     int       `json:"completed_tasks"`
    PendingTasks       int       `json:"pending_tasks"`
    CompletionPercent  float64   `json:"completion_percent"`
    TotalPomodoros     int       `json:"total_pomodoros"`
    TotalTimeSeconds   int       `json:"total_time_seconds"`
    TotalTimeFormatted string    `json:"total_time_formatted"`
    AveragePomodoroSec int       `json:"avg_pomodoro_duration_sec"`
    LastActivityAt     time.Time `json:"last_activity_at"`
}
```

**Calculation Query**:
```sql
SELECT
  p.id,
  p.name,
  p.description,
  p.is_completed,
  COUNT(DISTINCT t.id) as total_tasks,
  COUNT(DISTINCT CASE WHEN t.is_completed THEN t.id END) as completed_tasks,
  COUNT(DISTINCT CASE WHEN NOT t.is_completed THEN t.id END) as pending_tasks,
  CASE
    WHEN COUNT(DISTINCT t.id) = 0 THEN 0
    ELSE ROUND(100.0 * COUNT(DISTINCT CASE WHEN t.is_completed THEN t.id END) / COUNT(DISTINCT t.id), 2)
  END as completion_percent,
  COUNT(DISTINCT ps.id) as total_pomodoros,
  COALESCE(SUM(ps.duration), 0) as total_time_seconds,
  MAX(ps.end_time) as last_activity_at
FROM projects p
LEFT JOIN tasks t ON t.project_id = p.id
LEFT JOIN pomodoro_sessions ps ON ps.project_id = p.id AND ps.is_completed = true
WHERE p.user_id = $1 AND p.id = $2
GROUP BY p.id, p.name, p.description, p.is_completed;
```

---

## Migration Plan

### Migration File: `002_add_projects.sql`

```sql
-- ============================================
-- Migration 002: Add Project Management
-- ============================================

BEGIN;

-- Step 1: Create projects table
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_projects_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_project_name_length CHECK (LENGTH(TRIM(name)) >= 1 AND LENGTH(name) <= 255),
  CONSTRAINT chk_project_description_length CHECK (description IS NULL OR LENGTH(description) <= 2000)
);

-- Step 2: Create indexes
CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE UNIQUE INDEX idx_projects_user_name ON projects(user_id, name);
CREATE UNIQUE INDEX idx_projects_is_default ON projects(user_id, is_default) WHERE is_default = true;

-- Step 3: Create default "Inbox" project for all existing users
INSERT INTO projects (user_id, name, description, is_default, is_completed)
SELECT
  u.id,
  'Inbox',
  'Default project for tasks',
  true,
  false
FROM users u
WHERE NOT EXISTS (
  SELECT 1 FROM projects p WHERE p.user_id = u.id AND p.is_default = true
);

-- Step 4: Add project_id to tasks (nullable first)
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS project_id UUID;

-- Step 5: Backfill all existing tasks to user's Inbox project
UPDATE tasks t
SET project_id = p.id
FROM projects p
WHERE p.user_id = t.user_id
  AND p.is_default = true
  AND t.project_id IS NULL;

-- Step 6: Make project_id NOT NULL
ALTER TABLE tasks ALTER COLUMN project_id SET NOT NULL;

-- Step 7: Add FK constraint for tasks
ALTER TABLE tasks
  ADD CONSTRAINT fk_tasks_project
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

-- Step 8: Create task indexes
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_project_completed ON tasks(project_id, is_completed);

-- Step 9: Add project_id to pomodoro_sessions
ALTER TABLE pomodoro_sessions ADD COLUMN IF NOT EXISTS project_id UUID;

-- Step 10: Backfill sessions from their task's project
UPDATE pomodoro_sessions ps
SET project_id = t.project_id
FROM tasks t
WHERE t.id = ps.task_id
  AND ps.project_id IS NULL;

-- Step 11: Make session project_id NOT NULL
ALTER TABLE pomodoro_sessions ALTER COLUMN project_id SET NOT NULL;

-- Step 12: Add FK constraint for sessions
ALTER TABLE pomodoro_sessions
  ADD CONSTRAINT fk_sessions_project
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

-- Step 13: Create session indexes
CREATE INDEX idx_sessions_project_id ON pomodoro_sessions(project_id);
CREATE INDEX idx_sessions_project_completed ON pomodoro_sessions(project_id, is_completed);

-- Step 14: Create trigger to sync session project_id when task moves
CREATE OR REPLACE FUNCTION sync_session_project_id()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT project_id INTO NEW.project_id
    FROM tasks WHERE id = NEW.task_id;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.task_id != NEW.task_id THEN
    SELECT project_id INTO NEW.project_id
    FROM tasks WHERE id = NEW.task_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_session_project_id
  BEFORE INSERT OR UPDATE ON pomodoro_sessions
  FOR EACH ROW EXECUTE FUNCTION sync_session_project_id();

-- Step 15: Prevent default project deletion
CREATE OR REPLACE FUNCTION prevent_default_project_deletion()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_default = true THEN
    RAISE EXCEPTION 'Cannot delete default project';
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_default_project_deletion
  BEFORE DELETE ON projects
  FOR EACH ROW EXECUTE FUNCTION prevent_default_project_deletion();

-- Step 16: Update updated_at trigger for projects
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMIT;
```

### Rollback Plan

```sql
BEGIN;

-- Remove triggers
DROP TRIGGER IF EXISTS trg_update_projects_updated_at ON projects;
DROP TRIGGER IF EXISTS trg_prevent_default_project_deletion ON projects;
DROP TRIGGER IF EXISTS trg_sync_session_project_id ON pomodoro_sessions;

-- Drop functions
DROP FUNCTION IF EXISTS prevent_default_project_deletion();
DROP FUNCTION IF EXISTS sync_session_project_id();

-- Remove session constraints
ALTER TABLE pomodoro_sessions DROP CONSTRAINT IF EXISTS fk_sessions_project;
ALTER TABLE pomodoro_sessions ALTER COLUMN project_id DROP NOT NULL;
DROP INDEX IF EXISTS idx_sessions_project_completed;
DROP INDEX IF EXISTS idx_sessions_project_id;
ALTER TABLE pomodoro_sessions DROP COLUMN IF EXISTS project_id;

-- Remove task constraints
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS fk_tasks_project;
ALTER TABLE tasks ALTER COLUMN project_id DROP NOT NULL;
DROP INDEX IF EXISTS idx_tasks_project_completed;
DROP INDEX IF EXISTS idx_tasks_project_id;
ALTER TABLE tasks DROP COLUMN IF EXISTS project_id;

-- Remove projects table
DROP INDEX IF EXISTS idx_projects_is_default;
DROP INDEX IF EXISTS idx_projects_user_name;
DROP INDEX IF EXISTS idx_projects_user_id;
DROP TABLE IF EXISTS projects;

COMMIT;
```

---

## Sample Data

```sql
-- User 1 projects
INSERT INTO projects (id, user_id, name, description, is_default) VALUES
('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000001', 'Inbox', 'Default tasks', true),
('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000001', 'Website Redesign', 'Q4 2025 redesign project', false),
('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000001', 'Mobile App', 'iOS and Android app', false);

-- Tasks assigned to projects
INSERT INTO tasks (id, user_id, project_id, name, priority, is_completed) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Quick task', 1, false),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '00000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Design mockups', 3, true),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '00000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Implement header', 2, false);
```

---

## Data Integrity Rules

### Application-Level Validation

**On Project Creation**:
1. Validate user owns user_id from JWT token
2. Check project name uniqueness for user
3. Prevent creating second `is_default=true` project
4. Sanitize name and description (no XSS)

**On Project Deletion**:
1. Prevent deletion if `is_default=true`
2. Confirm cascades will delete N tasks and M sessions
3. Require explicit user confirmation
4. Log deletion for audit trail

**On Task Creation**:
1. Validate project_id exists and belongs to user
2. Ensure project_id is provided (no null)
3. Automatically set task's user_id to match project's user_id

**On Session Creation**:
1. Automatically derive project_id from task.project_id
2. Validate task exists and belongs to user
3. Ensure consistency between task.project_id and session.project_id

---

## Performance Optimization

### Query Patterns

**Most Common Queries**:

1. **List user's projects with stats**:
```sql
SELECT p.*,
       COUNT(t.id) as task_count,
       COUNT(CASE WHEN t.is_completed THEN 1 END) as completed_count
FROM projects p
LEFT JOIN tasks t ON t.project_id = p.id
WHERE p.user_id = $1
GROUP BY p.id
ORDER BY p.created_at DESC
LIMIT 20 OFFSET $2;
```

2. **Get project dashboard**:
```sql
SELECT * FROM get_project_statistics($user_id, $project_id);
```

3. **List tasks for project**:
```sql
SELECT * FROM tasks
WHERE project_id = $1 AND user_id = $2
ORDER BY is_completed, priority DESC, created_at DESC;
```

### Caching Strategy

**Redis Cache Keys**:
- `user:{user_id}:projects:list` - Project list (TTL: 5 min)
- `project:{project_id}:stats` - Project statistics (TTL: 1 min)
- `user:{user_id}:default_project` - Default project ID (TTL: 1 hour)

**Cache Invalidation**:
- Invalidate on project create/update/delete
- Invalidate on task create/update/delete/move
- Invalidate on session complete

---

**Data Model Status**: ✅ COMPLETE

All entities, relationships, constraints, and migration plan defined.
