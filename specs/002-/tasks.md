# Tasks: Project Management System

**Input**: Design documents from `/home/suiyun/claude/genie/specs/002-/`
**Prerequisites**: plan.md (✅), research.md (✅), data-model.md (✅), contracts/ (✅)

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Tech stack: Go 1.21+ backend, Flutter 3.24.3 frontend
   → Structure: Mobile + API architecture (backend/, mobile/)
2. Load optional design documents ✅
   → data-model.md: 3 entities (Project NEW, Task MODIFIED, PomodoroSession MODIFIED)
   → contracts/openapi.yaml: 8 API endpoints (6 new, 2 modified)
   → quickstart.md: 8 test scenarios + integration flow
3. Generate tasks by category ✅
   → Setup: Migration, dependencies
   → Tests: 8 contract tests, 8 integration tests
   → Core: 3 models, 3 services, 6 handlers
   → Integration: DB, state management, UI
   → Polish: unit tests, docs, validation
4. Apply task rules ✅
   → [P] = parallel (different files, no dependencies)
   → TDD order: Tests before implementation
5. Number tasks sequentially (T001-T048) ✅
6. Generate dependency graph ✅
7. Create parallel execution examples ✅
8. Validate task completeness ✅
9. Return: SUCCESS (48 tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Backend**: `backend/` (Go with Gin + GORM)
- **Frontend**: `mobile/` (Flutter + standalone web)
- **Database**: PostgreSQL migrations in `backend/migrations/`
- **Tests**: Separate contract and integration test files

---

## Phase 3.1: Setup & Migration

- [x] **T001** Create database migration file `backend/migrations/002_add_projects.sql` with complete schema changes
- [x] **T002** [P] Update Go dependencies in `backend/go.mod` for project management features
- [x] **T003** [P] Update Flutter dependencies in `mobile/pubspec.yaml` if needed for new UI components
- [x] **T004** [P] Configure database connection and run migration in development environment

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Contract Tests (API Validation)
- [ ] **T005** [P] Contract test GET /v1/projects in `backend/tests/contract/project_list_test.go`
- [ ] **T006** [P] Contract test POST /v1/projects in `backend/tests/contract/project_create_test.go`
- [ ] **T007** [P] Contract test GET /v1/projects/{id} in `backend/tests/contract/project_get_test.go`
- [ ] **T008** [P] Contract test PUT /v1/projects/{id} in `backend/tests/contract/project_update_test.go`
- [ ] **T009** [P] Contract test DELETE /v1/projects/{id} in `backend/tests/contract/project_delete_test.go`
- [ ] **T010** [P] Contract test GET /v1/projects/{id}/statistics in `backend/tests/contract/project_stats_test.go`
- [ ] **T011** [P] Contract test POST /v1/projects/{id}/complete in `backend/tests/contract/project_complete_test.go`
- [ ] **T012** [P] Contract test POST /v1/tasks with project_id requirement in `backend/tests/contract/task_project_test.go`

### Integration Tests (User Story Validation)
- [ ] **T013** [P] Integration test "Default Inbox Creation" in `backend/tests/integration/inbox_creation_test.go`
- [ ] **T014** [P] Integration test "Custom Project Creation" in `backend/tests/integration/project_creation_test.go`
- [ ] **T015** [P] Integration test "Task-Project Association" in `backend/tests/integration/task_project_test.go`
- [ ] **T016** [P] Integration test "Project Statistics Calculation" in `backend/tests/integration/project_stats_test.go`
- [ ] **T017** [P] Integration test "Pomodoro Project Tracking" in `backend/tests/integration/pomodoro_project_test.go`
- [ ] **T018** [P] Integration test "Project Cascade Deletion" in `backend/tests/integration/project_deletion_test.go`
- [ ] **T019** [P] Integration test "Default Project Protection" in `backend/tests/integration/inbox_protection_test.go`
- [ ] **T020** [P] Integration test "Manual Project Completion" in `backend/tests/integration/project_completion_test.go`

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Data Models
- [ ] **T021** [P] Create Project model in `backend/internal/models/project.go` with GORM annotations
- [ ] **T022** [P] Modify Task model in `backend/internal/models/task.go` to add project_id field
- [ ] **T023** [P] Modify PomodoroSession model in `backend/internal/models/pomodoro_session.go` to add project_id field

### Repository Layer
- [ ] **T024** [P] Create ProjectRepository interface and implementation in `backend/internal/repositories/project_repo.go`
- [ ] **T025** Modify TaskRepository in `backend/internal/repositories/task_repo.go` to handle project associations
- [ ] **T026** Modify SessionRepository in `backend/internal/repositories/session_repo.go` to track project context

### Service Layer
- [ ] **T027** Create ProjectService with CRUD operations in `backend/internal/services/project_service.go`
- [ ] **T028** Modify TaskService in `backend/internal/services/task_service.go` to enforce project requirements
- [ ] **T029** Modify SessionService in `backend/internal/services/session_service.go` to track project context
- [ ] **T030** Add project statistics calculation methods to ProjectService

### API Handler Layer
- [ ] **T031** Create ProjectHandler with 6 endpoints in `backend/internal/handlers/project_handler.go`
- [ ] **T032** Modify TaskHandler in `backend/internal/handlers/task_handler.go` to require project_id
- [ ] **T033** Update API routing in `backend/main.go` to include project endpoints
- [ ] **T034** Add project context middleware for authorization

### Frontend Models (Flutter)
- [ ] **T035** [P] Create Project model in `mobile/lib/models/project.dart` with JSON serialization
- [ ] **T036** [P] Modify Task model in `mobile/lib/models/task.dart` to include projectId field
- [ ] **T037** [P] Modify PomodoroSession model in `mobile/lib/models/pomodoro_session.dart` to include projectId field

### Frontend Services (Flutter)
- [ ] **T038** Create ProjectService in `mobile/lib/services/project_service.dart` for CRUD operations
- [ ] **T039** Modify TaskService in `mobile/lib/services/task_service.dart` to enforce project selection
- [ ] **T040** Update ApiClient in `mobile/lib/services/api_client.dart` with project endpoints
- [ ] **T041** Create ProjectState singleton in `mobile/lib/providers/project_state.dart` for state management

## Phase 3.4: Integration & UI

### Backend Integration
- [ ] **T042** Connect ProjectService to PostgreSQL database and verify migration
- [ ] **T043** Add project initialization logic (create Inbox if missing) to startup
- [ ] **T044** Add request/response logging for project endpoints
- [ ] **T045** Add error handling and validation for project operations

### Frontend UI (Flutter)
- [ ] **T046** Create ProjectListScreen in `mobile/lib/screens/project_list_screen.dart`
- [ ] **T047** Create ProjectDetailScreen in `mobile/lib/screens/project_detail_screen.dart` with dashboard
- [ ] **T048** Modify TaskScreen in `mobile/lib/screens/task_screen.dart` to show project context
- [ ] **T049** Modify PomodoroTimerScreen in `mobile/lib/screens/pomodoro_timer_screen.dart` to show project breadcrumb
- [ ] **T050** Update bottom navigation in `mobile/lib/main.dart` to include projects tab

### Standalone Web App
- [ ] **T051** Add Project class to `mobile/build/web/index.html` with localStorage persistence
- [ ] **T052** Modify Task class in `mobile/build/web/index.html` to include projectId field
- [ ] **T053** Add project management UI section to `mobile/build/web/index.html`
- [ ] **T054** Update localStorage schema in `mobile/build/web/index.html` for projects

## Phase 3.5: Polish & Testing

### Unit Tests
- [ ] **T055** [P] Unit tests for Project model in `backend/tests/unit/project_model_test.go`
- [ ] **T056** [P] Unit tests for ProjectService in `backend/tests/unit/project_service_test.go`
- [ ] **T057** [P] Unit tests for Project model in `mobile/test/models/project_test.dart`
- [ ] **T058** [P] Unit tests for ProjectService in `mobile/test/services/project_service_test.dart`

### Performance & Validation
- [ ] **T059** Performance test project statistics query (<50ms p95)
- [ ] **T060** Load test project list endpoint (<200ms p95 with 1000 projects)
- [ ] **T061** Validate all quickstart scenarios pass end-to-end

### Documentation
- [ ] **T062** [P] Update README.md with project management features
- [ ] **T063** [P] Update ARCHITECTURE.md with project entity relationships
- [ ] **T064** [P] Create migration guide for existing users in `docs/migration-guide.md`

---

## Dependencies

### Critical Dependencies (Block all implementation)
- **Migration** (T001) → All backend models (T021-T023)
- **Tests** (T005-T020) → All implementation (T021-T054)

### Backend Dependencies
- **Models** (T021-T023) → **Repositories** (T024-T026) → **Services** (T027-T030) → **Handlers** (T031-T034)
- **T027** (ProjectService) blocks **T030** (statistics), **T031** (handlers)
- **T033** (routing) requires **T031** (ProjectHandler)

### Frontend Dependencies
- **Models** (T035-T037) → **Services** (T038-T041) → **UI** (T046-T050)
- **T041** (ProjectState) blocks **T046-T049** (UI screens)
- **T040** (ApiClient) blocks **T038** (ProjectService)

### Web App Dependencies
- **T051** (Project class) → **T053** (UI), **T054** (localStorage)
- **T052** (Task modification) → **T054** (schema update)

### Integration Dependencies
- **Backend** (T042-T045) requires **Services** (T027-T030)
- **UI** (T046-T050) requires **Services** (T038-T041)

---

## Parallel Execution Examples

### Phase 3.2: All Tests in Parallel
```bash
# Launch T005-T020 together (16 parallel tests):
Task: "Contract test GET /v1/projects in backend/tests/contract/project_list_test.go"
Task: "Contract test POST /v1/projects in backend/tests/contract/project_create_test.go"
Task: "Contract test GET /v1/projects/{id} in backend/tests/contract/project_get_test.go"
Task: "Contract test PUT /v1/projects/{id} in backend/tests/contract/project_update_test.go"
Task: "Contract test DELETE /v1/projects/{id} in backend/tests/contract/project_delete_test.go"
Task: "Contract test GET /v1/projects/{id}/statistics in backend/tests/contract/project_stats_test.go"
Task: "Contract test POST /v1/projects/{id}/complete in backend/tests/contract/project_complete_test.go"
Task: "Contract test POST /v1/tasks with project_id requirement in backend/tests/contract/task_project_test.go"
Task: "Integration test Default Inbox Creation in backend/tests/integration/inbox_creation_test.go"
Task: "Integration test Custom Project Creation in backend/tests/integration/project_creation_test.go"
Task: "Integration test Task-Project Association in backend/tests/integration/task_project_test.go"
Task: "Integration test Project Statistics in backend/tests/integration/project_stats_test.go"
Task: "Integration test Pomodoro Project Tracking in backend/tests/integration/pomodoro_project_test.go"
Task: "Integration test Project Cascade Deletion in backend/tests/integration/project_deletion_test.go"
Task: "Integration test Default Project Protection in backend/tests/integration/inbox_protection_test.go"
Task: "Integration test Manual Project Completion in backend/tests/integration/project_completion_test.go"
```

### Phase 3.3: Models in Parallel
```bash
# Launch T021-T023 together (3 parallel models):
Task: "Create Project model in backend/internal/models/project.go"
Task: "Modify Task model in backend/internal/models/task.go to add project_id"
Task: "Modify PomodoroSession model in backend/internal/models/pomodoro_session.go to add project_id"
```

### Phase 3.3: Frontend Models in Parallel
```bash
# Launch T035-T037 together (3 parallel Flutter models):
Task: "Create Project model in mobile/lib/models/project.dart"
Task: "Modify Task model in mobile/lib/models/task.dart to include projectId"
Task: "Modify PomodoroSession model in mobile/lib/models/pomodoro_session.dart to include projectId"
```

### Phase 3.5: Documentation in Parallel
```bash
# Launch T062-T064 together (3 parallel docs):
Task: "Update README.md with project management features"
Task: "Update ARCHITECTURE.md with project entity relationships"
Task: "Create migration guide for existing users in docs/migration-guide.md"
```

---

## Notes

### TDD Compliance
- **ALL** tests (T005-T020) MUST be written and FAILING before any implementation
- Each test should validate the exact contract/behavior expected
- Verify tests fail for the right reasons (missing implementation, not bugs)

### File Modifications
- **[P] tasks** = Different files, no conflicts possible
- **Sequential tasks** = Same file modifications, must be done in order
- **Example**: T022 and T025 both modify task-related files sequentially

### Database Requirements
- **T001** migration must complete successfully before any backend work
- **PostgreSQL triggers** for project_id synchronization included in migration
- **Rollback plan** provided in migration for safety

### State Management
- **Flutter**: Extend existing singleton pattern with ProjectState
- **Web**: Enhance localStorage schema for project persistence
- **Consistency**: Project context maintained across all components

---

## Validation Checklist
*GATE: Checked before task execution*

- [x] All contracts (8 endpoints) have corresponding tests (T005-T012)
- [x] All entities (3 models) have model tasks (T021-T023, T035-T037)
- [x] All tests (T005-T020) come before implementation (T021-T054)
- [x] Parallel tasks ([P]) are truly independent (different files)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] TDD order enforced: Tests → Models → Services → Handlers → UI
- [x] Critical dependencies identified and documented
- [x] Migration strategy preserves existing data
- [x] Both Flutter and Web implementations included

---

## Task Completion Tracking

**Setup**: 4 tasks (T001-T004)
**Tests**: 16 tasks (T005-T020)
**Backend Core**: 14 tasks (T021-T034)
**Frontend Core**: 7 tasks (T035-T041)
**Integration & UI**: 13 tasks (T042-T054)
**Polish**: 10 tasks (T055-T064)

**Total**: 64 tasks
**Parallel Opportunities**: 28 tasks marked [P]
**Critical Path**: Migration → Tests → Models → Services → Handlers → UI

---

**Tasks Status**: ✅ READY FOR EXECUTION

Execute in dependency order. Verify tests fail before implementing. Each task should be completable by an LLM with the provided file paths and specifications.