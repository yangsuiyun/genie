# Research: Project Management System

**Feature**: 002- Project Management System
**Date**: 2025-10-05

## Research Questions & Findings

### 1. Project-Task Relationship Patterns

**Question**: How should the project-task relationship be implemented in the database?

**Research Summary**:
- Evaluated three common patterns:
  1. Optional FK (tasks.project_id NULL allowed)
  2. Mandatory FK (tasks.project_id NOT NULL)
  3. Many-to-many (junction table)

**Decision**: One-to-many with mandatory FK constraint

**Rationale**:
- Enforces business rule: "tasks MUST belong to projects"
- Database-level validation prevents orphans at source
- Simplifies queries (no JOIN needed for basic task retrieval)
- Better performance than many-to-many for this use case
- Aligns with clarified requirement: no orphan tasks allowed

**Alternatives Considered**:
- **Optional FK**: Rejected because it allows inconsistent state (orphan tasks possible)
- **Many-to-many**: Rejected because tasks belong to exactly ONE project (no sharing needed)

**Implementation Notes**:
```sql
ALTER TABLE tasks
  ADD COLUMN project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE;
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
```

---

### 2. Cascade Deletion Strategy

**Question**: What should happen to tasks/sessions when a project is deleted?

**Research Summary**:
- Investigated three deletion strategies:
  1. ON DELETE CASCADE (hard delete)
  2. ON DELETE SET NULL (orphan handling)
  3. Soft delete (mark as deleted)

**Decision**: ON DELETE CASCADE for project → tasks → sessions

**Rationale**:
- Matches clarified requirement: "cascade deletion enforced"
- Maintains referential integrity automatically
- Simpler application logic (no manual cleanup needed)
- Prevents accumulation of orphaned data
- Database handles cleanup atomically (ACID guarantees)

**Alternatives Considered**:
- **SET NULL**: Rejected per clarified requirement (no orphans allowed)
- **Soft delete**: Deferred to future enhancement (adds complexity, not MVP requirement)

**Implementation Notes**:
```sql
-- Projects table
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- ... other fields
);

-- Tasks with cascade
ALTER TABLE tasks
  ADD CONSTRAINT fk_tasks_project
  FOREIGN KEY (project_id)
  REFERENCES projects(id) ON DELETE CASCADE;

-- Sessions with cascade
ALTER TABLE pomodoro_sessions
  ADD CONSTRAINT fk_sessions_project
  FOREIGN KEY (project_id)
  REFERENCES projects(id) ON DELETE CASCADE;
```

---

### 3. Default Project Implementation

**Question**: How to guarantee default "Inbox" project exists for all users?

**Research Summary**:
- Examined two initialization approaches:
  1. Database-level DEFAULT constraint
  2. Application-level creation on first use
  3. Migration-created global default
  4. Hybrid: Migration + app-level check

**Decision**: Hybrid approach (database migration + application verification)

**Rationale**:
- Migration creates "Inbox" project with `is_default=true` flag
- Application checks on startup and recreates if missing (defensive)
- Handles edge cases: database reset, accidental deletion prevention
- Unique partial index ensures only ONE default project exists
- Works for both new and existing installations

**Alternatives Considered**:
- **App-only**: Rejected (race condition risk, no guarantee on database reset)
- **Migration-only**: Rejected (no recovery from accidental deletion)

**Implementation Notes**:
```sql
-- Migration: Create default project
INSERT INTO projects (id, name, description, is_default, is_completed)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Inbox',
  'Default project for uncategorized tasks',
  true,
  false
);

-- Unique constraint: Only one default allowed
CREATE UNIQUE INDEX idx_projects_is_default
  ON projects(is_default)
  WHERE is_default = true;

-- Prevent deletion trigger
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
```

**Application Logic** (Go):
```go
func EnsureDefaultProject(db *gorm.DB) error {
    var count int64
    db.Model(&Project{}).Where("is_default = ?", true).Count(&count)
    if count == 0 {
        inbox := Project{
            ID: uuid.MustParse("00000000-0000-0000-0000-000000000001"),
            Name: "Inbox",
            Description: "Default project for uncategorized tasks",
            IsDefault: true,
        }
        return db.Create(&inbox).Error
    }
    return nil
}
```

---

### 4. Project Statistics Aggregation

**Question**: Should project statistics be pre-computed or calculated on demand?

**Research Summary**:
- Evaluated three caching strategies:
  1. Real-time calculation (no cache)
  2. Pre-computed columns (updated via triggers)
  3. Application-level cache (Redis)
  4. Hybrid: Calculate + optional Redis cache

**Decision**: Real-time calculation with optional Redis caching

**Rationale**:
- Guarantees accuracy (no stale data)
- Simple implementation (standard SQL aggregation)
- Performance acceptable for expected load (<10k projects per user)
- Redis cache added later if performance metrics show need
- Aligns with "optimize when needed" principle

**Alternatives Considered**:
- **Pre-computed columns**: Rejected (trigger complexity, potential stale data)
- **Cache-only**: Rejected (accuracy risk, invalidation complexity)

**Implementation Notes**:
```sql
-- Real-time stats query (fast with proper indexes)
SELECT
  p.id,
  p.name,
  COUNT(t.id) as total_tasks,
  COUNT(CASE WHEN t.is_completed THEN 1 END) as completed_tasks,
  COUNT(ps.id) as total_pomodoros,
  SUM(ps.duration) as total_time_seconds
FROM projects p
LEFT JOIN tasks t ON t.project_id = p.id
LEFT JOIN pomodoro_sessions ps ON ps.project_id = p.id
WHERE p.user_id = $1
GROUP BY p.id, p.name;
```

**Indexes for Performance**:
```sql
CREATE INDEX idx_tasks_project_completed ON tasks(project_id, is_completed);
CREATE INDEX idx_sessions_project ON pomodoro_sessions(project_id);
```

---

### 5. State Management Pattern (Flutter)

**Question**: How to integrate project state into existing singleton pattern?

**Research Summary**:
- Reviewed current architecture: PomodoroState, AppSettings singletons
- Evaluated three approaches:
  1. Extend existing TaskService singleton
  2. Create new ProjectState singleton
  3. Migrate to Provider/Bloc

**Decision**: Create new ProjectState singleton (matches existing pattern)

**Rationale**:
- Consistency with current architecture (low learning curve)
- Minimal refactoring needed (no breaking changes)
- Clear separation of concerns (Project vs Task vs Pomodoro)
- Future-proof: Can migrate all to Provider later if needed

**Alternatives Considered**:
- **Extend TaskService**: Rejected (violates single responsibility)
- **Provider/Bloc**: Rejected (major refactor, out of scope for this feature)

**Implementation Pattern** (Dart):
```dart
class ProjectState {
  static final ProjectState _instance = ProjectState._internal();
  factory ProjectState() => _instance;
  ProjectState._internal();

  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  Project? _currentProject;

  List<Project> get projects => List.unmodifiable(_projects);
  Project? get currentProject => _currentProject;

  Future<void> loadProjects() async {
    _projects = await _projectService.getAllProjects();
    notifyListeners();
  }

  Future<void> selectProject(String projectId) async {
    _currentProject = _projects.firstWhere((p) => p.id == projectId);
    notifyListeners();
  }

  // ... other methods
}
```

---

### 6. Database Migration Strategy

**Question**: How to migrate existing tasks to require project_id?

**Research Summary**:
- Challenge: Existing tasks have no project_id
- Must avoid downtime and data loss
- Evaluated migration approaches:
  1. Add nullable column + manual backfill
  2. Add NOT NULL with default + backfill + remove default
  3. Multi-step: NULL → backfill → NOT NULL

**Decision**: Three-step migration with zero downtime

**Rationale**:
- Preserves all existing data (no loss)
- Zero downtime (no table locks)
- Rollback-safe (each step reversible)
- Automatic backfill to default "Inbox" project

**Migration Steps**:

**Step 1**: Create projects table + default Inbox
```sql
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_default BOOLEAN DEFAULT false,
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default Inbox for all users
INSERT INTO projects (id, user_id, name, description, is_default)
SELECT
  gen_random_uuid(),
  u.id,
  'Inbox',
  'Default project for tasks',
  true
FROM users u;
```

**Step 2**: Add nullable project_id + backfill
```sql
-- Add column (nullable first)
ALTER TABLE tasks ADD COLUMN project_id UUID;

-- Backfill: Assign all tasks to user's Inbox project
UPDATE tasks t
SET project_id = p.id
FROM projects p
WHERE p.user_id = t.user_id AND p.is_default = true;

-- Verify: Check no tasks left without project
SELECT COUNT(*) FROM tasks WHERE project_id IS NULL;
-- Should be 0
```

**Step 3**: Make NOT NULL + add constraints
```sql
-- Make NOT NULL (safe now, all tasks have project_id)
ALTER TABLE tasks ALTER COLUMN project_id SET NOT NULL;

-- Add FK constraint
ALTER TABLE tasks
  ADD CONSTRAINT fk_tasks_project
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

-- Add index
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
```

**Rollback Plan**:
- Step 3 rollback: DROP constraint, ALTER column DROP NOT NULL
- Step 2 rollback: DROP column project_id
- Step 1 rollback: DROP TABLE projects

---

## Technology Stack Confirmation

**Backend**:
- Go 1.21+ (confirmed in go.mod)
- Gin web framework (existing)
- GORM v2 with PostgreSQL driver (existing)
- PostgreSQL 15 (Docker, configured)
- Redis 7 (Docker, configured)

**Frontend**:
- Flutter 3.24.3 / Dart 3.5+ (confirmed in pubspec.yaml)
- Material Design 3 (existing)
- Singleton state pattern (existing in PomodoroState)

**Testing**:
- Backend: Go `testing` + `testify/assert`
- Frontend: `flutter_test` package
- Contract: Custom OpenAPI validator

**Deployment**:
- Docker Compose for orchestration
- Nginx as reverse proxy
- PostgreSQL + Redis in containers

---

## Best Practices Applied

### Database Design
- ✅ Use UUIDs for primary keys (distributed system ready)
- ✅ Add `created_at`/`updated_at` timestamps for audit trail
- ✅ Use partial unique indexes for conditional uniqueness
- ✅ Cascade deletes for referential integrity
- ✅ Index foreign keys for query performance

### API Design
- ✅ RESTful resource naming (/v1/projects)
- ✅ Pagination for collections (prevent memory issues)
- ✅ Filter/sort query parameters
- ✅ HTTP status codes match semantics (404, 409, etc.)
- ✅ Consistent error response format

### Flutter Architecture
- ✅ Separate models, services, screens layers
- ✅ Singleton pattern for state (existing pattern)
- ✅ Material Design 3 components
- ✅ Responsive design (mobile/tablet/desktop)
- ✅ Loading states + error handling

### Testing Strategy
- ✅ TDD: Write tests first, then implementation
- ✅ Contract tests validate API spec compliance
- ✅ Integration tests validate user stories
- ✅ Unit tests for business logic
- ✅ 80%+ coverage target

---

## Performance Considerations

**Database**:
- Index all foreign keys (project_id on tasks, sessions)
- Partial index for is_default (only one per user)
- Analyze query plans for statistics queries
- Connection pooling (existing configuration)

**API**:
- Pagination: Default 20 items, max 100
- Cache project lists in Redis (5 min TTL)
- Batch operations where possible
- Gzip compression for responses

**Frontend**:
- Lazy load project details (fetch on demand)
- Local cache with cache invalidation
- Optimistic UI updates (instant feedback)
- Debounce search inputs

---

## Security Considerations

**Authorization**:
- User can only access their own projects
- Middleware validates user_id from JWT token
- Row-level security via WHERE user_id = $authenticated_user

**Validation**:
- Project name: 1-255 chars, no SQL injection
- Description: Max 2000 chars, sanitized
- Prevent default project deletion (DB trigger)
- Rate limiting on project creation (max 100/hour)

**Data Integrity**:
- FK constraints prevent orphans
- Unique constraints prevent duplicates
- NOT NULL constraints prevent invalid state
- Transaction boundaries for multi-step operations

---

## Unknowns Resolved

All "NEEDS CLARIFICATION" items from Technical Context have been researched and decided:

1. ✅ **Language/Version**: Confirmed Go 1.21+, Flutter 3.24.3
2. ✅ **Dependencies**: Confirmed Gin, GORM, PostgreSQL, Redis
3. ✅ **Storage**: PostgreSQL with migration strategy defined
4. ✅ **Testing**: Go testing + Flutter test confirmed
5. ✅ **Performance**: Targets set (<200ms API, <100ms UI, <50ms DB)
6. ✅ **Constraints**: All business rules clarified and implementable
7. ✅ **Scale**: Capacity planning for 10k users documented

---

**Research Status**: ✅ COMPLETE

All unknowns resolved. Ready to proceed to Phase 1: Design & Contracts.
