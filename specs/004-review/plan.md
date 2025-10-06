
# Implementation Plan: Project Code Review and Optimization

**Branch**: `004-review` | **Date**: 2025-10-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-review/spec.md`

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
Comprehensive code review and optimization of the Pomodoro Genie project to maintain functionality while streamlining code quality. Focus on all performance metrics (load time, memory usage, execution efficiency, bundle size), removing all duplicate code, improving organization and structure, and applying optimization only where no functional risk exists.

## Technical Context
**Language/Version**: Go 1.21+ (backend), Dart 3.5+ / Flutter 3.24.3 (frontend), HTML/CSS/JavaScript ES6+ (web app)
**Primary Dependencies**: Gin framework (Go), Flutter SDK, PostgreSQL 15, Redis 7, Docker Compose
**Storage**: PostgreSQL (configured), Redis cache (configured), localStorage (web), Flutter local services
**Testing**: Go testing (`go test`), Flutter testing (`flutter test`), validation scripts (bash)
**Target Platform**: Linux server (backend), Web browsers (frontend), mobile platforms (Flutter)
**Project Type**: web - determines source structure (backend + frontend/mobile)
**Performance Goals**: <2s load time, <200MB memory, <500KB individual assets, 60fps animations
**Constraints**: Preserve all existing functionality, maintain cross-browser compatibility, offline-capable web app
**Scale/Scope**: 4200+ line HTML file, Go backend with 15+ models, Flutter app with multiple screens

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### TDD Adherence
- [x] **Contract tests approach**: Validation scripts already exist for performance, structure, functionality
- [x] **Test-first strategy**: Tests will verify code optimization preserves functionality
- [x] **Red-Green-Refactor**: Optimization tests fail initially, implementation makes them pass

### Code Quality Standards
- [x] **Linting/formatting**: Go (gofmt), Flutter (flutter analyze), HTML/CSS/JS validation
- [x] **Coverage target**: >80% for critical code paths being optimized
- [x] **DRY principle**: Aligned with requirement to remove duplicate code
- [x] **Complexity limits**: ≤10 cyclomatic complexity, ≤50 lines per function

### UX Consistency
- [x] **Preserve UI patterns**: FR-002 maintains current UI behavior and appearance
- [x] **Accessibility**: FR-009 maintains accessibility features
- [x] **Responsive design**: FR-008 preserves responsive design behavior
- [x] **Error handling**: FR-012 maintains proper error handling

### Performance Requirements
- [x] **Load time**: <2s aligned with constitutional <2s requirement
- [x] **Memory usage**: <200MB target for web app
- [x] **Response time**: Maintain existing performance levels
- [x] **Optimization focus**: All metrics (load time, memory, execution, bundle size)

### Documentation Excellence
- [x] **Preserve valuable docs**: FR-015 preserves documentation and comments where valuable
- [x] **Code organization**: FR-011 improves code organization and structure
- [x] **Change documentation**: This plan documents optimization approach

**RESULT**: ✅ PASS - No constitutional violations detected

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
backend/
├── cmd/                    # Application entry points
├── internal/
│   ├── models/            # Data models (User, Task, Session, etc.)
│   ├── services/          # Business logic services
│   ├── handlers/          # HTTP handlers
│   └── middleware/        # Middleware components
├── tests/                 # Go tests
├── main.go               # Main API entry
└── go.mod                # Go dependencies

mobile/
├── lib/
│   ├── main.dart         # Flutter app entry (1927 lines)
│   ├── settings.dart     # Settings system
│   ├── models/           # Dart models
│   ├── services/         # Flutter services
│   └── screens/          # UI screens
├── build/web/
│   └── index.html        # Standalone web app (4200+ lines)
├── test/                 # Flutter tests
└── pubspec.yaml          # Flutter dependencies

scripts/                  # Validation and build scripts
docs/                     # Feature documentation
specs/                    # Feature specifications
```

**Structure Decision**: Web application with Go backend and Flutter frontend that also builds to standalone web. The optimization will focus on the 4200+ line standalone web app (`mobile/build/web/index.html`) as the primary target, with secondary optimization of Go backend and Flutter code structure.

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
- Each optimization target (HTML, Go, Flutter) → analysis task [P]
- Each optimization type → contract test task [P]
- Each quickstart phase → implementation task sequence
- Validation tasks for functionality and performance preservation

**Specific Task Categories**:
1. **Analysis Tasks** [P]: Baseline measurement, duplicate detection, complexity analysis
2. **Contract Tests** [P]: Validation script creation, performance test setup
3. **HTML Optimization**: CSS consolidation, JavaScript optimization, structure simplification
4. **Backend Optimization**: Go code deduplication, structure improvement
5. **Frontend Optimization**: Flutter code consolidation, widget extraction
6. **Validation Tasks**: Functionality testing, performance verification, cross-browser testing

**Ordering Strategy**:
- TDD order: Analysis and tests before optimization implementation
- Dependency order: Baseline → HTML → Backend → Flutter → Final validation
- Mark [P] for parallel execution (independent analysis and contract tasks)
- Sequential for optimization phases to avoid conflicts

**Risk Mitigation**:
- Each optimization phase has rollback task
- Validation after each major change
- Git checkpoint before each phase

**Estimated Output**: 35-40 numbered, ordered tasks in tasks.md

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
- [x] Complexity deviations documented (none required)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
