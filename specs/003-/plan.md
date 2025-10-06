
# Implementation Plan: Frontend Project-First UI Design Documentation

**Branch**: `003-` | **Date**: 2025-10-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/home/suiyun/claude/genie/specs/003-/spec.md`

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
This feature focuses on creating comprehensive design documentation for the Pomodoro Genie frontend that establishes a project-first UI architecture. The documentation will specify left sidebar navigation, task-to-Pomodoro interaction flows, and responsive design patterns using wireframes and technical specifications to guide frontend implementation.

## Technical Context
**Language/Version**: HTML/CSS/JavaScript (ES6+), Markdown documentation
**Primary Dependencies**: CSS Grid/Flexbox, Web APIs (LocalStorage), Markdown processors
**Storage**: File-based documentation system (Markdown, wireframes)
**Testing**: Documentation completeness validation, wireframe consistency checks
**Target Platform**: Web browsers (desktop/mobile), documentation viewers
**Project Type**: web - frontend documentation with existing backend integration
**Performance Goals**: Documentation load <2s, wireframe rendering <1s
**Constraints**: Must integrate with existing Go backend API, responsive design required
**Scale/Scope**: 20+ UI components, 5+ interaction flows, 3+ responsive breakpoints

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **TDD Adherence**: Documentation validation tests exist and fail before implementation ✅ (N/A - documentation feature)
- [x] **Code Quality**: Markdown linting and formatting configured ✅ PASS
- [x] **UX Consistency**: Accessibility requirements addressed ✅ PASS (basic keyboard navigation specified)
- [x] **Performance Targets**: Explicit performance constraints documented ✅ PASS (doc load <2s)
- [x] **Documentation**: API contracts and quickstart guide present ✅ COMPLETE (contracts/, quickstart.md created)

## Project Structure

### Documentation (this feature)
```
specs/003-/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Web application structure (frontend documentation with backend integration)
docs/
├── frontend-design.md   # Already exists - comprehensive design doc
├── wireframes/          # Wireframe assets and diagrams
├── components/          # UI component specifications
└── flows/               # Interaction flow documentation

mobile/
├── build/web/           # Current web app implementation
│   └── index.html       # Target for redesign
├── lib/                 # Flutter implementation (secondary)
└── web/                 # Flutter web assets

backend/
├── internal/            # Existing Go API (integration target)
│   ├── models/          # Project management models
│   ├── handlers/        # API endpoints to integrate
│   └── services/        # Business logic services
└── INTEGRATION_GUIDE.md # Backend integration documentation
```

**Structure Decision**: Web application documentation targeting existing frontend implementation with backend API integration. Primary deliverable is design documentation in `docs/` with wireframes and component specs to guide the redesign of `mobile/build/web/index.html`.

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
- Generate documentation creation tasks from contracts and data model
- Create component specification tasks from design requirements [P]
- Generate wireframe creation tasks for UI layouts [P]
- Create validation script tasks for contract compliance
- Generate quickstart validation tasks for implementation testing

**Ordering Strategy**:
- Documentation-first: Contracts and specs before implementation guides
- Component-based: Individual component specs can be created in parallel [P]
- Validation last: Contract tests after all documentation complete
- Integration verification: Backend API alignment validation

**Estimated Output**: 15-20 numbered, ordered tasks in tasks.md

**Task Categories Expected**:
1. Documentation structure creation (3-4 tasks)
2. Component specification writing (8-10 tasks) [P]
3. Wireframe creation (2-3 tasks) [P]
4. Contract validation implementation (2-3 tasks)
5. Integration testing documentation (1-2 tasks)

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
- [x] Phase 0: Research complete (/plan command) ✅
- [x] Phase 1: Design complete (/plan command) ✅
- [x] Phase 2: Task planning complete (/plan command - describe approach only) ✅
- [x] Phase 3: Tasks generated (/tasks command) ✅
- [x] Phase 4: Implementation complete ✅ (Core deliverables)
- [ ] Phase 5: Validation passed (In progress)

**Gate Status**:
- [x] Initial Constitution Check: PASS ✅
- [x] Post-Design Constitution Check: PASS ✅
- [x] All NEEDS CLARIFICATION resolved ✅
- [x] Complexity deviations documented ✅ (N/A - no violations)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
