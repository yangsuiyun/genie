<!--
Sync Impact Report:
Version: 0.0.0 → 1.0.0
Modified Principles: N/A (initial constitution)
Added Sections:
  - I. Test-Driven Development (TDD)
  - II. Code Quality Standards
  - III. User Experience Consistency
  - IV. Performance Requirements
  - V. Documentation Excellence
  - Development Workflow
  - Quality Gates
Removed Sections: N/A
Templates Requiring Updates:
  ✅ .specify/templates/plan-template.md - Constitution Check section references validated
  ✅ .specify/templates/spec-template.md - Requirements alignment confirmed
  ✅ .specify/templates/tasks-template.md - Task categorization aligned with principles
  ✅ .claude/commands/plan.md - Constitution reference validated
  ✅ .claude/commands/analyze.md - Constitution authority validated
Follow-up TODOs: None
-->

# Genie Project Constitution

## Core Principles

### I. Test-Driven Development (TDD)

**TDD is NON-NEGOTIABLE**. Every feature MUST follow the Red-Green-Refactor cycle:

- Tests MUST be written before implementation
- Tests MUST fail initially (Red phase)
- Implementation MUST make tests pass (Green phase)
- Code MUST be refactored for quality (Refactor phase)
- User approval of test scenarios MUST precede implementation
- No production code without corresponding tests
- Contract tests MUST be created for all API endpoints before implementation
- Integration tests MUST validate user stories end-to-end

**Rationale**: TDD ensures correctness by design, prevents regression, and serves as living documentation. It forces clear specification of expected behavior before implementation complexity obscures intent.

### II. Code Quality Standards

**Code quality is enforced through automated and manual checks**:

- MUST maintain consistent formatting via automated tools (e.g., Prettier, Black, gofmt)
- MUST pass linting without warnings (ESLint, Pylint, RuboCop, etc.)
- MUST achieve minimum 80% code coverage for unit tests
- MUST eliminate code duplication (DRY principle) - max 5% duplication ratio
- MUST limit cyclomatic complexity to ≤10 per function
- MUST use meaningful names (no single-letter variables except loop counters)
- MUST include inline comments for non-obvious logic
- MUST follow language-specific idioms and best practices
- SHOULD prefer composition over inheritance
- SHOULD limit function length to ≤50 lines
- SHOULD limit file length to ≤500 lines

**Rationale**: Consistent quality standards reduce cognitive load, prevent bugs, and make codebases maintainable across team changes. Automated enforcement removes subjective debates.

### III. User Experience Consistency

**User experience MUST be predictable, accessible, and polished**:

- MUST maintain consistent UI patterns across all screens/pages
- MUST support keyboard navigation for all interactive elements
- MUST meet WCAG 2.1 Level AA accessibility standards minimum
- MUST provide loading states for async operations >300ms
- MUST display user-friendly error messages (no raw stack traces)
- MUST preserve user input on validation errors
- MUST support responsive design for mobile, tablet, desktop
- MUST include empty states with guidance when no data exists
- MUST provide confirmation for destructive actions
- SHOULD include progress indicators for multi-step flows
- SHOULD support dark mode where applicable
- SHOULD maintain sub-second perceived performance for critical paths

**Rationale**: Consistency reduces user learning curves and builds trust. Accessibility is both ethical and legally required. Professional polish differentiates products.

### IV. Performance Requirements

**Performance targets are defined per feature domain and enforced**:

- API endpoints MUST respond in <200ms at p95 (excluding external dependencies)
- UI interactions MUST respond in <100ms (perceived, including optimistic updates)
- Database queries MUST execute in <50ms at p95
- Page load time MUST be <2s on 4G connection (measured via Lighthouse)
- Memory usage MUST stay <200MB for client apps, <500MB for server processes
- MUST implement pagination for collections >100 items
- MUST use connection pooling for database/external service calls
- MUST implement caching strategies for frequently accessed data
- MUST profile and optimize hot paths (>10% execution time)
- SHOULD implement lazy loading for non-critical resources
- SHOULD use CDN for static assets

**Rationale**: Performance directly impacts user satisfaction and operational costs. Setting explicit targets prevents "death by a thousand cuts" degradation.

### V. Documentation Excellence

**Documentation MUST be treated as first-class deliverable**:

- MUST maintain up-to-date README with quickstart instructions
- MUST document all public APIs with request/response examples
- MUST include architecture diagrams for complex systems
- MUST document environment variables and configuration options
- MUST maintain CHANGELOG following semantic versioning
- MUST write JSDoc/docstrings for all public functions
- MUST include troubleshooting guides for common errors
- MUST provide runnable examples in documentation
- SHOULD include sequence diagrams for multi-step flows
- SHOULD maintain decision records (ADRs) for architectural choices

**Rationale**: Documentation is force multiplier for onboarding, debugging, and knowledge transfer. Poor documentation creates single points of failure in teams.

## Development Workflow

**Feature Development Lifecycle**:

1. **Specification Phase** (`/specify` command):
   - Product requirements captured in spec.md
   - User stories with acceptance criteria defined
   - Functional and non-functional requirements enumerated
   - All ambiguities marked with `[NEEDS CLARIFICATION]`

2. **Clarification Phase** (`/clarify` command):
   - Underspecified areas identified
   - Targeted questions asked
   - Answers integrated back into spec.md

3. **Planning Phase** (`/plan` command):
   - Technical approach researched and documented
   - Data models and API contracts designed
   - Contract tests generated (must fail)
   - Architecture validated against constitution

4. **Task Generation Phase** (`/tasks` command):
   - Implementation tasks generated from design
   - TDD ordering enforced (tests before implementation)
   - Dependencies and parallelization identified

5. **Analysis Phase** (`/analyze` command):
   - Cross-artifact consistency validated
   - Constitution compliance verified
   - Coverage gaps identified

6. **Implementation Phase** (`/implement` command):
   - Tasks executed in dependency order
   - Tests remain green throughout
   - Code reviewed against quality standards

**Branch Strategy**:
- Feature branches named `###-feature-name` (issue number + description)
- Commits must reference feature branch in message
- No direct commits to main/master

**Code Review Requirements**:
- MUST have at least one reviewer approval
- MUST pass all CI checks (tests, linting, coverage)
- MUST include screenshot/video for UI changes
- SHOULD be <400 lines changed for effective review

## Quality Gates

**Constitution Compliance Checks** (enforced at planning phase):

- [ ] **TDD Adherence**: Contract tests exist and fail before implementation
- [ ] **Code Quality**: Linting and formatting configured
- [ ] **UX Consistency**: Accessibility requirements addressed
- [ ] **Performance Targets**: Explicit performance constraints documented
- [ ] **Documentation**: API contracts and quickstart guide present

**Pre-Merge Checks** (enforced via CI):

- [ ] All tests pass (unit, integration, contract)
- [ ] Code coverage ≥80%
- [ ] Linting passes with zero warnings
- [ ] Performance benchmarks within targets
- [ ] Documentation updated

**Violation Handling**:
- Constitutional violations MUST be documented in plan.md Complexity Tracking table
- Justification MUST explain why simpler alternatives are insufficient
- Temporary violations MUST include remediation timeline
- Repeated violations trigger architecture review

## Governance

**Amendment Process**:
1. Propose change with rationale in issue/PR
2. Document impact on existing features
3. Require approval from 2+ team members
4. Update dependent templates and documentation
5. Increment constitution version semantically
6. Communicate changes to all contributors

**Version Semantics**:
- **MAJOR**: Backward-incompatible principle removals or redefinitions
- **MINOR**: New principles added or materially expanded guidance
- **PATCH**: Clarifications, wording fixes, non-semantic refinements

**Compliance Reviews**:
- Constitution alignment checked in `/analyze` command
- Violations reported as CRITICAL severity
- All PRs must pass constitution checks before merge

**Living Document**:
- This constitution is a living template
- Improvements accepted via standard amendment process
- Version history maintained in sync impact reports

**Version**: 1.0.0 | **Ratified**: 2025-10-02 | **Last Amended**: 2025-10-02