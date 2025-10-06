# Tasks: Project Code Review and Optimization

**Input**: Design documents from `/home/suiyun/claude/genie/specs/004-review/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Tech stack: Go 1.21+ (backend), Dart 3.5+ / Flutter 3.24.3 (frontend), HTML/CSS/JavaScript ES6+ (web app)
   → Libraries: Gin framework (Go), Flutter SDK, PostgreSQL 15, Redis 7, Docker Compose
   → Structure: Web application with backend + frontend/mobile
2. Load design documents ✅:
   → data-model.md: 5 entities (OptimizationTarget, OptimizationAction, PerformanceMetrics, ValidationResult, OptimizationProject)
   → contracts/: 1 file (optimization-validation.md)
   → research.md: 8 technical decisions
   → quickstart.md: 4 implementation phases
3. Generate tasks by category: Code optimization with TDD approach
4. Apply task rules: [P] for parallel optimization analysis tasks, sequential for file modifications
5. Number tasks sequentially (T001, T002...)
6. TDD approach: Contract validation before optimization implementation
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Based on plan.md structure:
- **Backend**: `backend/` for Go codebase optimization
- **Frontend**: `mobile/build/web/` for HTML/CSS/JS optimization
- **Flutter**: `mobile/lib/` for Dart code optimization
- **Validation**: `scripts/` for validation and testing scripts
- **Documentation**: `specs/004-review/` for optimization tracking

## Phase 3.1: Setup and Baseline Establishment
- [x] T001 Create optimization project structure per implementation plan
- [x] T002 Initialize optimization environment with Git branching and backup strategy
- [x] T003 [P] Configure validation tools and performance measurement scripts

**Details**:
- T001: Create directory structure for optimization tracking and backup files
- T002: Set up Git branch for optimization with rollback capability
- T003: Verify existing validation scripts and configure performance baseline tools

## Phase 3.2: Contract Validation Setup (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

### Contract Test Tasks (Based on contracts/ directory)
- [ ] T004 [P] Create functionality validation contract test from `contracts/optimization-validation.md`
- [ ] T005 [P] Create performance validation contract test from `contracts/optimization-validation.md`
- [ ] T006 [P] Create file analysis contract test from `contracts/optimization-validation.md`

**Details**:
- T004: Implement OptimizationValidator.validateFunctionality() contract test
- T005: Implement OptimizationValidator.validatePerformance() contract test
- T006: Implement CodeAnalyzer.analyzeFile() contract test

**Expected Status**: All contract tests FAIL (no optimization implementation exists yet)

## Phase 3.3: Baseline Analysis and Measurement

### Baseline Analysis Tasks (Based on data-model.md entities)
- [ ] T007 [P] Analyze HTML/CSS/JS file structure in `mobile/build/web/index.html`
- [ ] T008 [P] Analyze Go backend code structure in `backend/` directory
- [ ] T009 [P] Analyze Flutter code structure in `mobile/lib/` directory
- [ ] T010 [P] Create OptimizationProject entity tracking in `specs/004-review/optimization-project.json`
- [ ] T011 [P] Create OptimizationTarget entities for each file requiring optimization

**Details**:
- T007: Measure file size, line count, function count, CSS rules, duplicate patterns
- T008: Analyze Go files for duplicate code, complexity, organization opportunities
- T009: Analyze Flutter/Dart files for widget reuse, service consolidation opportunities
- T010: Initialize optimization project tracking with baseline metrics
- T011: Create OptimizationTarget records for primary targets (HTML, Go files, Flutter files)

### Performance Baseline Tasks
- [ ] T012 Capture performance baseline using `scripts/validate-quickstart-performance.sh`
- [ ] T013 Capture structure baseline using `scripts/validate-quickstart-structure.sh`
- [ ] T014 Capture functionality baseline using `scripts/validate-quickstart-functionality.sh`
- [ ] T015 Create performance metrics baseline in `specs/004-review/baseline-metrics.json`

**Details**:
- T012-T014: Run existing validation scripts to establish pre-optimization baselines
- T015: Store PerformanceMetrics entities for all metrics (load time, memory, execution, bundle size)

## Phase 3.4: HTML/CSS/JS Optimization (Primary Target)

### Target: `mobile/build/web/index.html` (4200+ lines)

#### CSS Optimization Tasks
- [ ] T016 Create backup of `mobile/build/web/index.html` as `mobile/build/web/index.html.backup`
- [ ] T017 Extract and consolidate duplicate CSS color variables in `mobile/build/web/index.html`
- [ ] T018 Consolidate duplicate CSS layout rules in `mobile/build/web/index.html`
- [ ] T019 Merge similar CSS media queries in `mobile/build/web/index.html`
- [ ] T020 Remove unused CSS rules in `mobile/build/web/index.html`
- [ ] T021 Validate CSS optimization preserves all visual appearance

**Details**:
- T016: Create backup for rollback capability
- T017: Consolidate --primary-color, --surface-color, and other duplicate variable definitions
- T018: Merge grid/flexbox layouts with similar patterns
- T019: Combine responsive media queries for better organization
- T020: Remove CSS rules not referenced in HTML
- T021: Visual comparison and cross-browser testing

#### JavaScript Optimization Tasks
- [ ] T022 Extract common utility functions in `mobile/build/web/index.html`
- [ ] T023 Consolidate duplicate event handlers in `mobile/build/web/index.html`
- [ ] T024 Remove dead code paths in `mobile/build/web/index.html`
- [ ] T025 Optimize function complexity (≤10 cyclomatic complexity) in `mobile/build/web/index.html`
- [ ] T026 Validate JavaScript optimization preserves all functionality

**Details**:
- T022: Extract common localStorage, timer, validation functions
- T023: Merge similar click handlers and form validation
- T024: Remove unreachable code and unused functions
- T025: Refactor complex functions to meet constitutional limits
- T026: Functional testing of all user interactions

#### HTML Structure Optimization Tasks
- [ ] T027 Remove redundant wrapper elements in `mobile/build/web/index.html`
- [ ] T028 Consolidate similar HTML patterns in `mobile/build/web/index.html`
- [ ] T029 Simplify nested element structures in `mobile/build/web/index.html`
- [ ] T030 Optimize element hierarchy for performance in `mobile/build/web/index.html`
- [ ] T031 Validate HTML optimization preserves all functionality and accessibility

**Details**:
- T027: Remove unnecessary div wrappers and container elements
- T028: Extract repeated HTML patterns into reusable structures
- T029: Flatten overly nested DOM structures
- T030: Optimize DOM tree for faster rendering
- T031: Accessibility testing and functionality validation

## Phase 3.5: Go Backend Optimization (Secondary Target)

### Go Code Structure Optimization
- [ ] T032 [P] Analyze duplicate patterns in `backend/internal/models/` directory
- [ ] T033 [P] Analyze duplicate patterns in `backend/internal/services/` directory
- [ ] T034 [P] Analyze duplicate patterns in `backend/internal/handlers/` directory
- [ ] T035 Consolidate duplicate struct fields across `backend/internal/models/*.go`
- [ ] T036 Extract common error handling patterns in `backend/internal/handlers/*.go`
- [ ] T037 Simplify service interfaces in `backend/internal/services/*.go`
- [ ] T038 Optimize import statements across all `backend/**/*.go` files
- [ ] T039 Validate Go optimization preserves all API functionality

**Details**:
- T032-T034: Parallel analysis of different Go packages for optimization opportunities
- T035: Consolidate similar struct definitions and field patterns
- T036: Create common error handling utilities
- T037: Simplify and consolidate service layer interfaces
- T038: Remove unused imports and optimize import organization
- T039: API testing and behavioral validation

## Phase 3.6: Flutter Code Optimization (Tertiary Target)

### Flutter/Dart Code Optimization
- [ ] T040 [P] Analyze widget reuse opportunities in `mobile/lib/main.dart`
- [ ] T041 [P] Analyze service consolidation opportunities in `mobile/lib/services/`
- [ ] T042 Extract common widget patterns from `mobile/lib/main.dart`
- [ ] T043 Consolidate service implementations in `mobile/lib/services/*.dart`
- [ ] T044 Simplify state management in `mobile/lib/main.dart`
- [ ] T045 Remove unused imports across all `mobile/lib/**/*.dart` files
- [ ] T046 Validate Flutter optimization preserves all app functionality

**Details**:
- T040-T041: Parallel analysis of Flutter code for optimization opportunities
- T042: Extract reusable widgets from the 1927-line main.dart file
- T043: Consolidate similar service patterns and implementations
- T044: Optimize state management without changing behavior
- T045: Clean up import statements across all Dart files
- T046: Flutter app testing and functionality validation

## Phase 3.7: Performance Validation and Optimization

### Performance Testing Tasks
- [ ] T047 Measure post-optimization performance using `scripts/validate-quickstart-performance.sh`
- [ ] T048 Compare performance metrics against baseline using `specs/004-review/baseline-metrics.json`
- [ ] T049 [P] Cross-browser performance testing (Chrome, Firefox, Safari, Edge)
- [ ] T050 [P] Mobile device performance testing (iOS Safari, Chrome Mobile)
- [ ] T051 Generate performance improvement report in `specs/004-review/performance-report.md`

**Details**:
- T047: Run performance validation on optimized code
- T048: Calculate improvements in load time, memory usage, execution efficiency, bundle size
- T049-T050: Parallel testing across different browsers and devices
- T051: Document performance gains and any regressions

### Functionality Validation Tasks
- [ ] T052 Run comprehensive functionality testing using `scripts/validate-quickstart-functionality.sh`
- [ ] T053 Test all user workflows (project creation, task management, Pomodoro timer, settings)
- [ ] T054 Validate data persistence and localStorage functionality
- [ ] T055 Test responsive design across all breakpoints (768px, 1024px)
- [ ] T056 Validate accessibility features and keyboard navigation

**Details**:
- T052: Run automated functionality validation
- T053: Manual testing of all major user flows
- T054: Test data persistence and state management
- T055: Responsive design validation
- T056: Accessibility compliance verification

## Phase 3.8: Final Validation and Documentation

### Optimization Completion Tasks
- [ ] T057 Update OptimizationTarget entities with final optimization status
- [ ] T058 Create final OptimizationAction records for all changes made
- [ ] T059 Generate comprehensive optimization report in `specs/004-review/optimization-report.md`
- [ ] T060 Update project documentation with optimization changes
- [ ] T061 Create rollback instructions in `specs/004-review/rollback-guide.md`

**Details**:
- T057: Mark all targets as VALIDATED in optimization tracking
- T058: Document all optimization actions taken with before/after metrics
- T059: Comprehensive report showing all improvements and validations
- T060: Update relevant project documentation
- T061: Instructions for rolling back any optimization if needed

### Quality Assurance Tasks
- [ ] T062 [P] Run Go linting and formatting validation (`gofmt`, `go vet`)
- [ ] T063 [P] Run Flutter analysis and formatting validation (`flutter analyze`)
- [ ] T064 [P] Validate all tests pass (Go: `go test ./...`, Flutter: `flutter test`)
- [ ] T065 Verify all constitutional compliance requirements met
- [ ] T066 Create optimization success criteria checklist

**Details**:
- T062-T064: Parallel validation of code quality across all platforms
- T065: Constitutional compliance verification (TDD, code quality, UX, performance, documentation)
- T066: Final checklist confirming all optimization goals achieved

## Dependencies

### Critical Path
```
T001-T003 (Setup) → T004-T006 (Contract Tests) → T007-T015 (Baseline) → T016-T031 (HTML) → T032-T039 (Go) → T040-T046 (Flutter) → T047-T066 (Validation)
```

### Parallel Execution Opportunities
```
Parallel Group 1: T004, T005, T006 (Contract tests - different validation interfaces)
Parallel Group 2: T007, T008, T009 (Analysis - different codebases)
Parallel Group 3: T010, T011 (Entity creation - different tracking files)
Parallel Group 4: T032, T033, T034 (Go analysis - different packages)
Parallel Group 5: T040, T041 (Flutter analysis - different components)
Parallel Group 6: T049, T050 (Cross-platform testing - different devices)
Parallel Group 7: T062, T063, T064 (Quality validation - different platforms)
```

### Sequential Dependencies
```
T016 (Backup) → T017-T020 (CSS optimization) → T021 (CSS validation)
T022-T025 (JS optimization) → T026 (JS validation)
T027-T030 (HTML optimization) → T031 (HTML validation)
T047 (Performance measurement) → T048 (Comparison) → T051 (Report)
T052-T056 (Functionality validation) → T057-T061 (Documentation)
```

## Execution Commands

### Parallel Task Execution Examples
```bash
# Execute contract tests in parallel
Task: "Create functionality validation contract test from contracts/optimization-validation.md"
Task: "Create performance validation contract test from contracts/optimization-validation.md"
Task: "Create file analysis contract test from contracts/optimization-validation.md"

# Execute analysis tasks in parallel
Task: "Analyze HTML/CSS/JS file structure in mobile/build/web/index.html"
Task: "Analyze Go backend code structure in backend/ directory"
Task: "Analyze Flutter code structure in mobile/lib/ directory"

# Execute quality validation in parallel
Task: "Run Go linting and formatting validation (gofmt, go vet)"
Task: "Run Flutter analysis and formatting validation (flutter analyze)"
Task: "Validate all tests pass (Go: go test ./..., Flutter: flutter test)"
```

### Sequential Execution
```bash
# Critical path execution
Task T001 && Task T002 && Task T003    # Setup
Task T004 && Task T005 && Task T006    # Contract validation
Task T016 && Task T017 && Task T018    # CSS optimization sequence
# ... followed by parallel groups where applicable
```

## Success Criteria

### Optimization Completeness
- [ ] All duplicate code removed from HTML/CSS/JS (per clarification requirement)
- [ ] Code organization and structure improved across all platforms
- [ ] All performance metrics maintained or improved (load time, memory, execution, bundle size)
- [ ] Zero functional risk tolerance maintained (optimization only where no functional risk exists)

### Validation Completeness
- [ ] All contract tests pass (functionality, performance, file analysis)
- [ ] All functionality preserved exactly as before optimization
- [ ] Performance baseline met or exceeded across all metrics
- [ ] Cross-browser and mobile compatibility maintained

### Quality Standards
- [ ] Constitutional compliance verified (TDD, code quality, UX, performance, documentation)
- [ ] All linting and formatting standards met
- [ ] Code complexity limits satisfied (≤10 cyclomatic complexity, ≤50 lines per function)
- [ ] All tests pass across Go and Flutter codebases

### Documentation Standards
- [ ] Comprehensive optimization report generated
- [ ] All changes documented with before/after metrics
- [ ] Rollback instructions provided
- [ ] Success criteria checklist completed

**Estimated Total Time**: 25-35 hours across all tasks
**Parallel Execution Reduction**: ~40% time savings using parallel task groups
**Critical Path Time**: ~20 hours for sequential dependencies

This task list provides comprehensive, executable instructions for optimizing the Pomodoro Genie codebase while maintaining strict functionality preservation and following TDD principles.