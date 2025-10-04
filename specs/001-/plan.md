
# Implementation Plan: 番茄工作法任务与时间管理应用

**Branch**: `001-` | **Date**: 2025-10-03 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/home/suiyun/claude/genie/specs/001-/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
A cross-platform Pomodoro task and time management application supporting iOS, Android, Windows, macOS, and Web. Users can create tasks with subtasks, use customizable Pomodoro timers with push notifications, set reminders, add notes, view productivity reports, and sync data across devices using last-write-wins conflict resolution. Authentication via email/password.

## Technical Context
**Language/Version**: Dart 3.5+ (Flutter), Go 1.21+ (Backend), Rust 1.75+ (Tauri)
**Primary Dependencies**: Flutter SDK, Gin/Fiber (backend), Supabase (database+realtime), Riverpod (state), FCM (notifications), Tauri (desktop)
**Storage**: Supabase (PostgreSQL+realtime), Hive+SQLite (Flutter local), IndexedDB (web local), Tauri storage (desktop)
**Testing**: flutter_test+patrol (Flutter), testify+httptest (backend), Maestro (mobile E2E), Playwright (web/desktop E2E)
**Target Platform**: iOS 15+, Android 8+, Windows 10+, macOS 11+, modern web browsers (Chrome, Firefox, Safari, Edge)
**Project Type**: mobile + web (requires backend API, mobile apps, desktop apps, web frontend)
**Performance Goals**: Timer precision ±1s, API response <200ms p95, UI interactions <100ms, offline-capable, push notifications delivered within 5s
**Constraints**: <200ms API latency p95, <200MB client memory, offline-first architecture, background timer execution, cross-platform code reuse >70%
**Scale/Scope**: Initial 10k users, 50+ screens across platforms, 100k+ tasks, 1M+ Pomodoro sessions, 5-year data retention

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development (TDD)
- [x] Tests will be written before implementation
- [x] Contract tests planned for all API endpoints
- [x] Integration tests planned for user stories
- [x] User approval of test scenarios will precede implementation

### II. Code Quality Standards
- [x] Automated formatting will be configured (Prettier/ESLint for web, platform-specific for mobile)
- [x] Linting will be configured with zero-warning policy
- [x] 80% minimum code coverage target set
- [x] Complexity limits will be enforced (≤10 cyclomatic complexity)

### III. User Experience Consistency
- [x] Consistent UI patterns required across all platforms
- [x] Keyboard navigation support planned
- [x] WCAG 2.1 Level AA accessibility target
- [x] Loading states for async operations >300ms
- [x] User-friendly error messages
- [x] Responsive design for all screen sizes
- [x] Confirmation for destructive actions (task deletion)

### IV. Performance Requirements
- [x] API endpoints <200ms at p95 (matches constitution)
- [x] UI interactions <100ms (matches constitution)
- [x] Pagination for task lists >100 items
- [x] Caching strategy planned for sync data
- [x] Background timer execution requires profiling

### V. Documentation Excellence
- [x] README with quickstart will be created
- [x] API documentation with examples planned
- [x] Architecture diagrams planned for sync and notification systems
- [x] CHANGELOG will follow semantic versioning

**PASS**: All constitutional requirements addressed in plan. No violations detected.

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
backend/                    # API server (REST/GraphQL)
├── src/
│   ├── models/            # Data models (User, Task, PomodoroSession, etc.)
│   ├── services/          # Business logic (TaskService, TimerService, SyncService)
│   ├── api/               # API routes and controllers
│   ├── auth/              # Authentication (email/password, JWT)
│   ├── notifications/     # Push notification service
│   └── sync/              # Conflict resolution, last-write-wins
└── tests/
    ├── contract/          # API contract tests
    ├── integration/       # End-to-end API tests
    └── unit/              # Service and model unit tests

mobile/                     # React Native or Flutter
├── src/
│   ├── screens/           # UI screens (Tasks, Timer, Reports, Settings)
│   ├── components/        # Reusable UI components
│   ├── services/          # API client, local storage, sync
│   ├── models/            # Local data models
│   ├── state/             # State management (Redux/MobX/Riverpod)
│   └── utils/             # Timer logic, notifications
├── ios/                   # iOS-specific (native modules, config)
├── android/               # Android-specific (native modules, config)
└── tests/
    ├── integration/       # User flow tests
    └── unit/              # Component and service tests

web/                        # Web frontend (React/Vue/Svelte)
├── src/
│   ├── pages/             # Page components
│   ├── components/        # Reusable components
│   ├── services/          # API client, local storage
│   ├── state/             # State management
│   └── utils/             # Timer, notifications (Web Push API)
└── tests/
    ├── integration/       # E2E tests (Playwright/Cypress)
    └── unit/              # Component tests

desktop/                    # Electron or Tauri (optional, may reuse web)
├── src/
│   ├── main/              # Main process (native integrations)
│   └── renderer/          # Renderer process (reuses web/)
└── tests/

shared/                     # Shared code across platforms
├── types/                 # TypeScript types/interfaces
├── validation/            # Validation schemas
└── constants/             # Shared constants
```

**Structure Decision**: Multi-platform monorepo structure with separate backend API, mobile app (React Native/Flutter), web frontend, and optional desktop app. Shared types and validation logic in `shared/` directory. Backend handles authentication, data persistence, sync, and push notifications. Clients implement offline-first architecture with local storage and sync on reconnect.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

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
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
