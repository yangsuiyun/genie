# Data Model: Code Review and Optimization

**Created**: 2025-10-06
**Purpose**: Define entities and data structures for code optimization process

## Core Entities

### OptimizationTarget
Represents a file or code section that requires optimization.

**Fields**:
- `id`: String - Unique identifier (file path + section)
- `filePath`: String - Absolute path to the file
- `type`: Enum - FILE, FUNCTION, CSS_BLOCK, HTML_SECTION
- `sizeBytes`: Integer - Current size in bytes
- `lineCount`: Integer - Number of lines
- `complexity`: Integer - Cyclomatic complexity (for functions)
- `duplicateCount`: Integer - Number of duplicate instances found
- `lastModified`: DateTime - File modification timestamp
- `status`: Enum - PENDING, IN_PROGRESS, OPTIMIZED, VALIDATED

**Relationships**:
- Has many `OptimizationActions`
- Has many `PerformanceMetrics`
- Belongs to `OptimizationProject`

**Validation Rules**:
- `filePath` must exist in filesystem
- `sizeBytes` must be > 0
- `complexity` must be >= 1 for functions, null for other types
- `status` transitions: PENDING → IN_PROGRESS → OPTIMIZED → VALIDATED

### OptimizationAction
Represents a specific optimization operation performed.

**Fields**:
- `id`: String - Unique identifier
- `targetId`: String - Reference to OptimizationTarget
- `actionType`: Enum - REMOVE_DUPLICATE, EXTRACT_FUNCTION, CONSOLIDATE_CSS, SIMPLIFY_STRUCTURE, IMPROVE_ORGANIZATION
- `description`: String - Human-readable description of action
- `codeBefor`: Text - Original code content
- `codeAfter`: Text - Optimized code content
- `bytesSaved`: Integer - Reduction in file size
- `linesSaved`: Integer - Reduction in line count
- `functionalRisk`: Enum - NONE, LOW, MEDIUM, HIGH
- `appliedAt`: DateTime - When optimization was applied
- `validatedAt`: DateTime - When functionality was validated
- `status`: Enum - PLANNED, APPLIED, VALIDATED, ROLLED_BACK

**Relationships**:
- Belongs to `OptimizationTarget`
- Has many `ValidationResults`

**Validation Rules**:
- `functionalRisk` must be NONE (per clarification requirements)
- `bytesSaved` must be >= 0
- `codeAfter` must be different from `codeBefore`
- Cannot apply if target is not IN_PROGRESS

### PerformanceMetrics
Stores performance measurements before and after optimization.

**Fields**:
- `id`: String - Unique identifier
- `targetId`: String - Reference to OptimizationTarget
- `metricType`: Enum - LOAD_TIME, MEMORY_USAGE, EXECUTION_EFFICIENCY, BUNDLE_SIZE
- `baselineValue`: Float - Value before optimization
- `currentValue`: Float - Value after optimization
- `unit`: String - Measurement unit (ms, MB, KB, score)
- `improvementPercent`: Float - Calculated improvement percentage
- `measurementMethod`: String - How the metric was obtained
- `measuredAt`: DateTime - When measurement was taken
- `isValid`: Boolean - Whether measurement is considered reliable

**Relationships**:
- Belongs to `OptimizationTarget`

**Validation Rules**:
- `baselineValue` must be > 0
- `currentValue` must be >= 0
- `improvementPercent` calculated as (baseline - current) / baseline * 100
- `metricType` must align with clarification requirements (all metrics equal priority)

### ValidationResult
Records validation tests to ensure functionality preservation.

**Fields**:
- `id`: String - Unique identifier
- `actionId`: String - Reference to OptimizationAction
- `testType`: Enum - FUNCTIONALITY, PERFORMANCE, VISUAL, ACCESSIBILITY, CROSS_BROWSER
- `testName`: String - Name of specific test
- `expectedResult`: Text - What should happen
- `actualResult`: Text - What actually happened
- `passed`: Boolean - Whether test passed
- `evidence`: Text - Screenshots, logs, or other evidence
- `executedAt`: DateTime - When test was run
- `executedBy`: String - Test execution method (manual, automated)

**Relationships**:
- Belongs to `OptimizationAction`

**Validation Rules**:
- All validation tests must pass before optimization is considered complete
- `testType` FUNCTIONALITY is mandatory for all optimizations
- Evidence required for VISUAL and ACCESSIBILITY tests

### OptimizationProject
Root entity managing the overall optimization effort.

**Fields**:
- `id`: String - Project identifier (branch name)
- `name`: String - Human-readable project name
- `startDate`: DateTime - When optimization started
- `targetCompletionDate`: DateTime - Planned completion
- `actualCompletionDate`: DateTime - Actual completion (null if in progress)
- `totalTargets`: Integer - Number of files/sections to optimize
- `completedTargets`: Integer - Number completed
- `totalBytesSaved`: Integer - Total size reduction achieved
- `status`: Enum - PLANNING, IN_PROGRESS, COMPLETED, VALIDATED

**Relationships**:
- Has many `OptimizationTargets`
- Has one `ProjectMetrics`

**Validation Rules**:
- `completedTargets` must be <= `totalTargets`
- Cannot mark COMPLETED unless all targets are VALIDATED
- `actualCompletionDate` required when status is COMPLETED

## State Transitions

### OptimizationTarget States
```
PENDING → IN_PROGRESS → OPTIMIZED → VALIDATED
   ↓           ↓            ↓
 (skip)    (rollback)   (rollback)
   ↓           ↓            ↓
VALIDATED ← PENDING ← PENDING
```

### OptimizationAction States
```
PLANNED → APPLIED → VALIDATED
   ↓         ↓         ↓
(cancel)  (rollback) (pass)
   ↓         ↓
CANCELLED ← ROLLED_BACK
```

## Derived Calculations

### Optimization Progress
- **Completion Percentage**: `completedTargets / totalTargets * 100`
- **Size Reduction**: `sum(bytesSaved) for all completed actions`
- **Risk Assessment**: `count(actions where functionalRisk > NONE)` (should be 0)

### Performance Improvements
- **Overall Load Time**: Weighted average of LOAD_TIME metrics
- **Memory Efficiency**: Total MEMORY_USAGE reduction
- **Bundle Optimization**: Total BUNDLE_SIZE reduction
- **Execution Gains**: Average EXECUTION_EFFICIENCY improvement

## Data Persistence Strategy

### Primary Storage
- **JSON files**: For optimization metadata and tracking
- **Git history**: For code change tracking and rollback capability
- **Performance logs**: For metric baseline and progression

### Backup Strategy
- **Pre-optimization snapshots**: Full backup before any changes
- **Incremental backups**: After each optimization action
- **Rollback capability**: Ability to restore any previous state

## Data Validation

### Integrity Constraints
- All foreign key relationships must be valid
- Performance metrics must have both baseline and current values
- Validation results must exist for all applied optimizations
- File paths must exist and be accessible

### Business Rules
- No optimization can be applied without prior validation test setup
- All duplicate code must be removed (per clarification)
- All performance metrics must be maintained or improved
- All functionality must be preserved (verified through validation)

## Integration Points

### Existing Systems
- **Git repository**: Source of truth for code changes
- **Validation scripts**: Performance and structure testing
- **Build system**: For bundle size and compilation metrics
- **Browser APIs**: For runtime performance measurement

### External Dependencies
- **File system**: Access to source code files
- **Development tools**: Linters, formatters, analyzers
- **Testing frameworks**: For automated validation
- **Performance tools**: For metric collection

This data model supports the comprehensive optimization requirements while ensuring functionality preservation and risk mitigation through structured validation processes.