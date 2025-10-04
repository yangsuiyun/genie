# Tasks: 番茄工作法任务与时间管理应用

**Input**: Design documents from `/home/suiyun/claude/genie/specs/001-/`
**Prerequisites**: plan.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

## Tech Stack Summary
- **Frontend**: Flutter (Dart 3.5+) for mobile/web + Tauri (Rust 1.75+) for desktop
- **Backend**: Go 1.21+ with Gin framework
- **Database**: Supabase (PostgreSQL) with real-time subscriptions
- **State**: Riverpod (Flutter), local storage (Hive/SQLite/IndexedDB)
- **Testing**: flutter_test+patrol, testify+httptest, Maestro, Playwright

## Project Structure
```
backend/                    # Go + Gin API server
mobile/                     # Flutter (iOS/Android/Web)
desktop/                    # Tauri application
shared/                     # Shared protocol buffers and types
```

## Phase 3.1: Setup & Infrastructure

- [x] **T001** Create monorepo project structure with backend/, mobile/, desktop/, shared/ directories
- [x] **T002** Initialize backend Go module with Gin, Supabase client dependencies in backend/go.mod
- [x] **T003** [P] Initialize Flutter project with Riverpod, Hive, FCM dependencies in mobile/pubspec.yaml
- [x] **T004** [P] Initialize Tauri project with Rust dependencies in desktop/src-tauri/Cargo.toml
- [x] **T005** [P] Configure gofmt, golangci-lint for backend in backend/.golangci.yml
- [x] **T006** [P] Configure dart_code_metrics, very_good_analysis for Flutter in mobile/analysis_options.yaml
- [x] **T007** Configure Supabase local development with Docker in docker-compose.yml
- [x] **T008** [P] Setup shared protocol buffers definition in shared/proto/

## Phase 3.2: Contract Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [x] **T009** [P] Contract test POST /auth/register in backend/tests/contract/auth_register_test.go
- [x] **T010** [P] Contract test POST /auth/login in backend/tests/contract/auth_login_test.go
- [x] **T011** [P] Contract test GET /tasks in backend/tests/contract/tasks_list_test.go
- [x] **T012** [P] Contract test POST /tasks in backend/tests/contract/tasks_create_test.go
- [x] **T013** [P] Contract test PUT /tasks/{taskId} in backend/tests/contract/tasks_update_test.go
- [x] **T014** [P] Contract test POST /pomodoro/sessions in backend/tests/contract/pomodoro_start_test.go
- [x] **T015** [P] Contract test PUT /pomodoro/sessions/{sessionId} in backend/tests/contract/pomodoro_update_test.go
- [x] **T016** [P] Contract test GET /reports in backend/tests/contract/reports_generate_test.go

## Phase 3.3: Integration Tests (Quickstart Scenarios)
**CRITICAL: These must FAIL before implementation**

- [x] **T017** [P] Integration test: Complete Pomodoro workflow in backend/tests/integration/pomodoro_workflow_test.go
- [x] **T018** [P] Integration test: Task management & reminders in backend/tests/integration/task_management_test.go
- [x] **T019** [P] Integration test: Cross-device sync simulation in backend/tests/integration/sync_test.go
- [x] **T020** [P] Integration test: Reports & analytics generation in backend/tests/integration/reports_test.go
- [x] **T021** [P] Integration test: Recurring tasks creation in backend/tests/integration/recurring_tasks_test.go

## Phase 3.4: Data Models (ONLY after tests are failing)

- [x] **T022** [P] User model with preferences schema in backend/internal/models/user.go
- [x] **T023** [P] Task model with relationships in backend/internal/models/task.go
- [x] **T024** [P] Subtask model in backend/internal/models/subtask.go
- [x] **T025** [P] PomodoroSession model with state transitions in backend/internal/models/pomodoro_session.go
- [x] **T026** [P] Note model in backend/internal/models/note.go
- [x] **T027** [P] Reminder model in backend/internal/models/reminder.go
- [x] **T028** [P] RecurrenceRule model in backend/internal/models/recurrence_rule.go
- [x] **T029** [P] Report model with metrics schema in backend/internal/models/report.go

## Phase 3.5: Services Layer

- [x] **T030** AuthService with email/password + JWT in backend/internal/services/auth.go
- [x] **T031** UserService with CRUD operations in backend/internal/services/user.go
- [x] **T032** TaskService with subtask management in backend/internal/services/task.go
- [x] **T033** PomodoroService with timer logic in backend/internal/services/pomodoro.go
- [x] **T034** SyncService with last-write-wins in backend/internal/services/sync.go
- [x] **T035** NotificationService with FCM integration in backend/internal/services/notification.go
- [x] **T036** ReportService with analytics generation in backend/internal/services/report.go

## Phase 3.6: API Endpoints Implementation

- [x] **T037** POST /auth/register endpoint in backend/internal/handlers/auth.go
- [x] **T038** POST /auth/login endpoint in backend/internal/handlers/auth.go
- [x] **T039** GET /tasks with pagination in backend/internal/handlers/tasks.go
- [x] **T040** POST /tasks creation in backend/internal/handlers/tasks.go
- [x] **T041** PUT /tasks/{taskId} update in backend/internal/handlers/tasks.go
- [x] **T042** POST /pomodoro/sessions start in backend/internal/handlers/pomodoro.go
- [x] **T043** PUT /pomodoro/sessions/{sessionId} update in backend/internal/handlers/pomodoro.go
- [x] **T044** GET /reports generation in backend/internal/handlers/reports.go

## Phase 3.7: Database Integration

- [x] **T045** Supabase connection setup in backend/internal/config/database.go
- [x] **T046** Database migrations for all models in backend/migrations/
- [x] **T047** Real-time subscriptions setup in backend/internal/config/realtime.go
- [x] **T048** Database query optimization and indexes in backend/migrations/indexes.sql

## Phase 3.8: Flutter Mobile Application

- [x] **T049** [P] Authentication screens (login/register) in mobile/lib/screens/auth/
- [x] **T050** [P] Task list screen with infinite scroll in mobile/lib/screens/tasks/task_list_screen.dart
- [x] **T051** [P] Task detail screen with subtasks in mobile/lib/screens/tasks/task_detail_screen.dart
- [x] **T052** [P] Pomodoro timer screen with notifications in mobile/lib/screens/timer/pomodoro_screen.dart
- [x] **T053** [P] Reports screen with charts in mobile/lib/screens/reports/reports_screen.dart
- [x] **T054** [P] Settings screen with preferences in mobile/lib/screens/settings/settings_screen.dart
- [x] **T055** API client with offline queue in mobile/lib/services/api_client.dart
- [x] **T056** Local storage with Hive in mobile/lib/services/local_storage.dart
- [x] **T057** Sync service with conflict resolution in mobile/lib/services/sync_service.dart
- [x] **T058** Push notification handling in mobile/lib/services/notification_service.dart
- [x] **T059** Riverpod providers setup in mobile/lib/providers/

## Phase 3.9: Desktop Application (Tauri)

- [x] **T060** [P] Tauri main window setup in desktop/src-tauri/src/main.rs
- [x] **T061** [P] System tray integration in desktop/src-tauri/src/tray.rs
- [x] **T062** [P] Native notifications in desktop/src-tauri/src/notifications.rs
- [x] **T063** [P] Local storage APIs in desktop/src-tauri/src/storage.rs
- [x] **T064** [P] Auto-startup configuration in desktop/src-tauri/src/startup.rs

## Phase 3.10: Cross-Platform Integration

- [x] **T065** Shared protocol buffer definitions in shared/proto/api.proto
- [x] **T066** Validation schemas in backend/internal/validators/
- [x] **T067** Error handling middleware in backend/internal/middleware/error.go
- [x] **T068** Rate limiting middleware in backend/internal/middleware/rate_limit.go
- [x] **T069** CORS configuration in backend/internal/middleware/cors.go
- [x] **T070** Authentication middleware in backend/internal/middleware/auth.go

## Phase 3.11: Testing & Polish

- [x] **T071** [P] Unit tests for all services using testify in backend/tests/unit/
- [x] **T072** [P] Flutter widget tests in mobile/test/widget/
- [x] **T073** [P] E2E tests with Maestro in mobile/test/e2e/
- [x] **T074** [P] Performance testing for <150ms API responses in backend/tests/performance/
- [x] **T075** [P] Timer precision testing (±1s accuracy) in mobile/test/timer/
- [x] **T076** [P] Memory usage validation (<100MB) in backend/tests/performance/
- [x] **T077** [P] API documentation generation using Swagger in backend/docs/
- [x] **T078** [P] README with Go quickstart instructions in root README.md
- [x] **T079** Code duplication removal and refactoring across all modules
- [x] **T080** Manual testing execution following quickstart.md scenarios

## Dependencies

**Setup Dependencies**:
- T001 → T002, T003, T004 (project structure before individual projects)
- T007 → T045 (Supabase setup before database connection)

**TDD Dependencies**:
- T009-T021 (all tests) MUST complete before T022-T080 (implementation)
- Tests MUST FAIL initially to validate TDD approach

**Model Dependencies**:
- T022-T029 (models) → T030-T036 (services)
- T030-T036 (services) → T037-T044 (endpoints)

**Integration Dependencies**:
- T045-T048 (database) → T037-T044 (endpoints)
- T055-T059 (Flutter services) → T049-T054 (Flutter UI)
- T060-T064 (Tauri core) → T063 (storage integration)

**Polish Dependencies**:
- All implementation (T022-T070) → Testing (T071-T080)

## Parallel Execution Examples

**Phase 3.1 Setup** (after T001):
```bash
# Launch T003, T004, T005, T006, T008 in parallel:
Task: "Initialize Flutter project with Riverpod, Hive, FCM dependencies in mobile/pubspec.yaml"
Task: "Initialize Tauri project with Rust dependencies in desktop/src-tauri/Cargo.toml"
Task: "Configure gofmt, golangci-lint for backend in backend/.golangci.yml"
Task: "Configure dart_code_metrics, very_good_analysis for Flutter in mobile/analysis_options.yaml"
Task: "Setup shared protocol buffers definition in shared/proto/"
```

**Phase 3.2 Contract Tests** (all parallel):
```bash
# Launch T009-T016 together:
Task: "Contract test POST /auth/register in backend/tests/contract/auth_register_test.go"
Task: "Contract test POST /auth/login in backend/tests/contract/auth_login_test.go"
Task: "Contract test GET /tasks in backend/tests/contract/tasks_list_test.go"
Task: "Contract test POST /tasks in backend/tests/contract/tasks_create_test.go"
Task: "Contract test PUT /tasks/{taskId} in backend/tests/contract/tasks_update_test.go"
Task: "Contract test POST /pomodoro/sessions in backend/tests/contract/pomodoro_start_test.go"
Task: "Contract test PUT /pomodoro/sessions/{sessionId} in backend/tests/contract/pomodoro_update_test.go"
Task: "Contract test GET /reports in backend/tests/contract/reports_generate_test.go"
```

**Phase 3.4 Models** (all parallel after tests fail):
```bash
# Launch T022-T029 together:
Task: "User model with preferences schema in backend/internal/models/user.go"
Task: "Task model with relationships in backend/internal/models/task.go"
Task: "Subtask model in backend/internal/models/subtask.go"
Task: "PomodoroSession model with state transitions in backend/internal/models/pomodoro_session.go"
Task: "Note model in backend/internal/models/note.go"
Task: "Reminder model in backend/internal/models/reminder.go"
Task: "RecurrenceRule model in backend/internal/models/recurrence_rule.go"
Task: "Report model with metrics schema in backend/internal/models/report.go"
```

## Validation Checklist
- [x] All contracts have corresponding tests (T009-T016)
- [x] All entities have model tasks (T022-T029)
- [x] All tests come before implementation (Phase 3.2-3.3 before 3.4+)
- [x] Parallel tasks truly independent (different files, marked [P])
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] TDD ordering enforced (tests → models → services → endpoints)
- [x] Cross-platform architecture addressed (Flutter + Tauri + Backend)
- [x] Performance targets covered (T074-T076)

## Success Criteria
- All contract tests pass after implementation
- Integration tests validate quickstart scenarios
- Performance targets met (<150ms API, <100ms UI, ±1s timer, <100MB memory)
- Cross-platform functionality on iOS, Android, Windows, macOS, Web
- Real-time sync working with offline queue
- Push notifications delivered on all platforms
- TDD principles followed throughout implementation
- Go backend demonstrates superior performance and lower memory usage