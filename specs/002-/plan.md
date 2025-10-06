# Implementation Plan: Project Management System

**Branch**: `002-` | **Date**: 2025-10-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/home/suiyun/claude/genie/specs/002-/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path ✅
   → Loaded: Project Management System specification
2. Fill Technical Context ✅
   → Project Type: web (Flutter frontend + Go backend)
   → Structure Decision: Mobile + API architecture
3. Fill Constitution Check section ✅
4. Evaluate Constitution Check section ✅
   → No violations detected
   → Update Progress Tracking: Initial Constitution Check ✅
5. Execute Phase 0 → research.md ✅
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, CLAUDE.md ✅
7. Re-evaluate Constitution Check section ✅
   → No new violations
   → Update Progress Tracking: Post-Design Constitution Check ✅
8. Plan Phase 2 → Task generation approach described ✅
9. STOP - Ready for /tasks command ✅
```

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

This feature adds a project management layer to the existing Pomodoro Genie application, shifting the architecture from task-first to project-first. Projects become the primary organizational unit, with tasks as children and Pomodoro sessions as execution tools for individual tasks.

**Key Changes**:
- Add Project entity as parent container for Tasks
- Enforce mandatory task-project relationship (no orphan tasks)
- Auto-create default "Inbox" project for new users
- Track Pomodoro statistics at both task and project levels
- Implement project-first navigation with breadcrumb hierarchy
- Support manual project completion independent of task status

## Technical Context

**Language/Version**:
- Backend: Go 1.21+
- Frontend: Flutter 3.24.3 (Dart 3.5+)
- Web: Standalone HTML/CSS/JS (existing)

**Primary Dependencies**:
- Backend: Gin framework, GORM (PostgreSQL ORM), Redis
- Frontend: Flutter Material Design 3, singleton state management
- Testing: Go testing package, Flutter test framework

**Storage**:
- PostgreSQL 15 (configured, ready for integration)
- Redis 7 (caching layer, configured)
- localStorage (Web app, already functional)

**Testing**:
- Backend: Go `testing` package with `testify`
- Frontend: Flutter `test` and `flutter_test` packages
- Contract: OpenAPI validation

**Target Platform**:
- Backend: Linux server (Docker containerized)
- Frontend: Flutter Web, iOS, Android
- Deployment: Docker Compose + Nginx

**Project Type**: mobile + API (Flutter app + Go backend)

**Performance Goals**:
- API response time: <200ms p95
- UI interactions: <100ms perceived latency
- Database queries: <50ms p95
- Support: 10,000+ concurrent users

**Constraints**:
- Tasks MUST belong to projects (no orphans)
- Flat project structure (no nesting)
- Default "Inbox" project cannot be deleted
- Manual project completion only
- Cascade deletion of tasks when project deleted

**Scale/Scope**:
- Expected: 10,000 users
- ~50 projects per user average
- ~200 tasks per user average
- ~1,000 Pomodoro sessions per user per month

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### TDD Adherence
- ✅ Contract tests will be generated for all new endpoints
- ✅ Integration tests will validate user stories end-to-end
- ✅ Tests will fail initially (no implementation exists)
- ✅ Implementation follows tests

### Code Quality Standards
- ✅ Go code formatted with `gofmt`
- ✅ Flutter code follows Dart style guide
- ✅ Linting configured (golint, flutter analyze)
- ✅ Target: 80%+ code coverage
- ✅ Meaningful names enforced in design

### UX Consistency
- ✅ Material Design 3 maintained
- ✅ Responsive design for mobile/tablet/desktop
- ✅ Loading states for async operations
- ✅ Empty states for new/empty projects
- ✅ Confirmation for destructive actions (project deletion)
- ✅ Breadcrumb navigation for context

### Performance Requirements
- ✅ API endpoints <200ms p95 target documented
- ✅ Database queries optimized with indexes
- ✅ Pagination for project/task lists (>100 items)
- ✅ Caching strategy for frequently accessed data

### Documentation Excellence
- ✅ API contracts in OpenAPI format
- ✅ Data model documented with relationships
- ✅ Quickstart guide for testing
- ✅ CLAUDE.md updated with new entities

**Initial Constitution Check**: ✅ PASS (no violations)

## Project Structure

### Documentation (this feature)
```
specs/002-/
├── plan.md              # This file (/plan command output)
├── spec.md              # Feature specification (input)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   ├── openapi.yaml     # OpenAPI 3.0 spec
│   └── tests/           # Contract test files
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
backend/
├── internal/
│   ├── models/
│   │   ├── project.go          # NEW: Project model
│   │   ├── task.go             # MODIFIED: Add project_id FK
│   │   └── pomodoro_session.go # MODIFIED: Add project_id FK
│   ├── services/
│   │   ├── project_service.go  # NEW: Project CRUD + stats
│   │   ├── task_service.go     # MODIFIED: Enforce project requirement
│   │   └── session_service.go  # MODIFIED: Track project context
│   ├── handlers/
│   │   └── project_handler.go  # NEW: Project API endpoints
│   └── repositories/
│       └── project_repo.go     # NEW: Project data access
├── migrations/
│   └── 002_add_projects.sql    # NEW: Database migration
└── tests/
    ├── contract/
    │   └── project_api_test.go # NEW: Contract tests
    └── integration/
        └── project_flow_test.go # NEW: Integration tests

mobile/
├── lib/
│   ├── models/
│   │   ├── project.dart        # NEW: Project model
│   │   ├── task.dart           # MODIFIED: Add projectId field
│   │   └── pomodoro_session.dart # MODIFIED: Add projectId field
│   ├── services/
│   │   ├── project_service.dart # NEW: Project management
│   │   ├── task_service.dart   # MODIFIED: Enforce project association
│   │   └── api_client.dart     # MODIFIED: Add project endpoints
│   ├── screens/
│   │   ├── project_list_screen.dart # NEW: Project list view
│   │   ├── project_detail_screen.dart # NEW: Project dashboard
│   │   ├── task_screen.dart    # MODIFIED: Show project context
│   │   └── pomodoro_timer_screen.dart # MODIFIED: Show project breadcrumb
│   └── providers/
│       └── project_state.dart  # NEW: Project state management
└── test/
    ├── models/
    │   └── project_test.dart   # NEW: Project model tests
    └── services/
        └── project_service_test.dart # NEW: Service tests

mobile/build/web/
└── index.html                  # MODIFIED: Add project management to standalone web app
```

**Structure Decision**: This is a mobile + API architecture. The backend provides RESTful APIs in Go, while the frontend is built with Flutter (supporting web, iOS, Android). The standalone web app (index.html) exists as a separate fully-functional implementation that will also be updated to include project management.

## Phase 0: Outline & Research

*See [research.md](./research.md) for full research outputs*

### Research Topics Completed:

1. **Project-Task Relationship Patterns**
   - Decision: One-to-many with mandatory FK constraint
   - Rationale: Enforces data integrity, prevents orphans, simplifies queries
   - Alternatives: Optional FK (rejected - allows inconsistent state)

2. **Cascade Deletion Strategy**
   - Decision: ON DELETE CASCADE for project → tasks
   - Rationale: Maintains referential integrity, prevents orphaned tasks
   - Alternatives: Soft delete (deferred to future enhancement)

3. **Default Project Implementation**
   - Decision: Database-level default + application-level initialization
   - Rationale: Guarantees existence even in edge cases
   - Implementation: Migration creates "Inbox", app checks on startup

4. **Project Statistics Aggregation**
   - Decision: Real-time calculation with optional caching
   - Rationale: Always accurate, cache for performance if needed
   - Alternatives: Pre-computed columns (rejected - stale data risk)

5. **State Management Pattern (Flutter)**
   - Decision: Extend existing singleton pattern with ProjectState
   - Rationale: Consistency with current architecture, low migration cost
   - Alternatives: Provider/Bloc (rejected - major refactor required)

6. **Database Migration Strategy**
   - Decision: Add nullable project_id, backfill to Inbox, make NOT NULL
   - Rationale: Zero-downtime migration, preserves existing data
   - Steps: Create projects table → Create Inbox → Backfill tasks → Add constraint

**Output**: research.md complete ✅

## Phase 1: Design & Contracts

### 1. Data Model (`data-model.md`)

**Entities**:

- **Project**
  - id: UUID (PK)
  - name: String (unique, required)
  - description: String (optional)
  - is_default: Boolean (default false)
  - is_completed: Boolean (default false)
  - created_at: Timestamp
  - updated_at: Timestamp
  - Relationships: has_many Tasks

- **Task** (modified)
  - project_id: UUID (FK, required, indexed)
  - Relationships: belongs_to Project

- **PomodoroSession** (modified)
  - project_id: UUID (FK, required, indexed)
  - Relationships: belongs_to Project (through Task)

**Database Constraints**:
- `projects.name` UNIQUE INDEX
- `projects.is_default` UNIQUE PARTIAL INDEX WHERE is_default = true
- `tasks.project_id` FK with ON DELETE CASCADE
- `pomodoro_sessions.project_id` FK with ON DELETE CASCADE

### 2. API Contracts (`contracts/openapi.yaml`)

**New Endpoints**:

```yaml
/v1/projects:
  GET:    List all projects (paginated)
  POST:   Create new project

/v1/projects/{id}:
  GET:    Get project details with statistics
  PUT:    Update project
  DELETE: Delete project (cascade tasks)

/v1/projects/{id}/tasks:
  GET:    List tasks for project (filtered)
  POST:   Create task in project

/v1/projects/{id}/statistics:
  GET:    Get project statistics (tasks, pomodoros, time)

/v1/projects/{id}/complete:
  POST:   Mark project as complete/incomplete
```

**Modified Endpoints**:

```yaml
/v1/tasks:
  POST:   REQUIRES project_id in body

/v1/pomodoro/start:
  POST:   REQUIRES task_id (project_id inferred)
```

### 3. Contract Tests (`contracts/tests/`)

All tests generated and FAILING (no implementation yet):
- `project_api_test.go`: Tests all project endpoints
- `task_project_association_test.go`: Tests project requirement
- `project_statistics_test.go`: Tests stats calculations

### 4. Integration Tests

User story tests (FAILING):
- `project_creation_flow_test.go`: Test inbox creation + custom projects
- `task_project_flow_test.go`: Test task creation with project
- `pomodoro_project_flow_test.go`: Test Pomodoro with project context

### 5. Quickstart Guide (`quickstart.md`)

Step-by-step test execution guide for validating the feature end-to-end.

### 6. Agent Context Update

Updated CLAUDE.md with:
- Project entity documentation
- Modified Task/PomodoroSession relationships
- Recent changes log
- Implementation status update (65% → 70% after this feature)

**Post-Design Constitution Check**: ✅ PASS (no new violations)

**Phase 1 Output**: ✅ Complete
- data-model.md
- contracts/openapi.yaml
- contracts/tests/*.go
- quickstart.md
- CLAUDE.md updated

## Phase 2: Task Planning Approach

*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:

1. Load `.specify/templates/tasks-template.md` as base template
2. Generate tasks from Phase 1 design artifacts in TDD order:

**Data Layer Tasks** (Backend):
- Create migration file 002_add_projects.sql [P]
- Create Project model (internal/models/project.go) [P]
- Modify Task model to add project_id FK [depends on migration]
- Modify PomodoroSession model to add project_id FK [depends on migration]
- Create ProjectRepository interface and implementation [P]

**Service Layer Tasks** (Backend):
- Create ProjectService with CRUD operations [depends on ProjectRepository]
- Modify TaskService to enforce project requirement [depends on Task model]
- Modify SessionService to track project context [depends on PomodoroSession model]
- Add project statistics calculation methods [depends on ProjectService]

**API Layer Tasks** (Backend):
- Create contract tests for /v1/projects endpoints [P]
- Create ProjectHandler with 6 endpoints [depends on ProjectService]
- Modify TaskHandler to require project_id [depends on TaskService]
- Update API routing to include project endpoints [depends on ProjectHandler]

**Data Layer Tasks** (Frontend/Flutter):
- Create Project model (lib/models/project.dart) [P]
- Modify Task model to include projectId field [P]
- Modify PomodoroSession model to include projectId field [P]
- Create ProjectService for CRUD operations [depends on Project model]

**Service Layer Tasks** (Frontend/Flutter):
- Modify TaskService to enforce project selection [depends on ProjectService]
- Update ApiClient with project endpoints [depends on ProjectService]
- Create ProjectState singleton for state management [depends on ProjectService]
- Add project initialization logic (create Inbox if needed) [depends on ProjectService]

**UI Layer Tasks** (Frontend/Flutter):
- Create ProjectListScreen [depends on ProjectState]
- Create ProjectDetailScreen with dashboard [depends on ProjectState]
- Modify TaskScreen to show project context [depends on ProjectState]
- Modify PomodoroTimerScreen to show project breadcrumb [depends on ProjectState]
- Add project selector widget [P]
- Update bottom navigation to include projects [depends on ProjectListScreen]

**Web App Tasks** (Standalone):
- Add Project class to index.html [P]
- Modify Task class to include projectId [P]
- Add project management UI section [depends on Project class]
- Update localStorage schema for projects [depends on Project class]
- Modify Pomodoro timer to show project context [depends on localStorage update]

**Integration Tasks**:
- Write integration test: new user → auto-create Inbox → create task [depends on all services]
- Write integration test: create project → add tasks → track pomodoros [depends on all services]
- Write integration test: delete project → cascade delete tasks [depends on all services]
- Write integration test: complete project with pending tasks [depends on all services]

**Documentation Tasks**:
- Update README.md with project management features [P]
- Update ARCHITECTURE.md with project entity [P]
- Create migration guide for existing users [P]

**Ordering Strategy**:
- TDD order: All contract/integration tests before implementations
- Dependency order: Migration → Models → Repositories → Services → Handlers → UI
- Parallel execution marked [P] for independent file creation
- Backend and Frontend data layers can run in parallel
- UI layers depend on service layers

**Estimated Output**: 45-50 numbered, dependency-ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks.md following constitutional principles)
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

*No constitutional violations detected - this section is empty*

## Progress Tracking

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved (5 clarifications in spec)
- [x] Complexity deviations documented (none)

---
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
