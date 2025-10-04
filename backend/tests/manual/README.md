# Manual Testing Suite for Pomodoro Genie

This directory contains a comprehensive manual testing framework for validating the Pomodoro Genie application across all platforms and features.

## Overview

The manual testing suite validates the application against the quickstart scenarios defined in `specs/001-/quickstart.md`. It ensures that all user stories and functional requirements are met before production deployment.

## Test Structure

```
backend/tests/manual/
├── README.md                    # This documentation
├── Makefile                     # Test orchestration and automation
├── execution_plan.md            # Detailed test execution checklist
├── validate_scenarios.sh        # Shell script for automated validation
├── test_runner.go              # Go-based test runner (programmatic)
├── run_tests.go                # Test execution controller
└── test_report_generator.go    # Comprehensive report generation
```

## Quick Start

### Prerequisites

1. **System Requirements**:
   - Go 1.21+ installed
   - curl and jq utilities
   - Backend server running on localhost:3000

2. **Environment Setup**:
   ```bash
   export BACKEND_URL="http://localhost:3000/v1"
   export TEST_EMAIL="test@example.com"
   export TEST_PASSWORD="TestPassword123!"
   ```

### Running Tests

```bash
# Run complete test suite
make test-all

# Run individual scenarios
make test-scenario-1  # Pomodoro Workflow
make test-scenario-2  # Task Management
make test-scenario-3  # Cross-Device Sync
make test-scenario-4  # Reports & Analytics
make test-scenario-5  # Recurring Tasks

# Performance validation only
make test-performance

# Generate HTML report
make generate-report

# Quick smoke test
make smoke-test
```

## Test Scenarios

### Scenario 1: Complete Pomodoro Workflow
**Validates**: FR-001 through FR-008

**Key Tests**:
- ✅ User authentication and session management
- ✅ Task creation with subtasks
- ✅ Pomodoro session start/stop functionality
- ✅ Timer precision (±1 second accuracy)
- ✅ Background execution and notifications
- ✅ Session completion recording

**Success Criteria**:
- Timer runs for exactly 25 minutes
- Push notification delivered on completion
- Session recorded with correct duration
- Task shows completed Pomodoro count

### Scenario 2: Task Management & Reminders
**Validates**: FR-010 through FR-020

**Key Tests**:
- ✅ Task creation with due dates and priorities
- ✅ Subtask management and progress tracking
- ✅ Reminder notification scheduling
- ✅ Task completion workflow
- ✅ Data persistence and synchronization

**Success Criteria**:
- Reminders sent at scheduled time
- Subtasks can be managed independently
- Task completion updates all related data
- Progress tracking functions correctly

### Scenario 3: Cross-Device Sync
**Validates**: FR-029 through FR-033

**Key Tests**:
- ✅ Real-time synchronization across devices
- ✅ Conflict resolution (last-write-wins)
- ✅ Offline functionality and queue management
- ✅ Data consistency validation
- ✅ Multi-platform compatibility

**Success Criteria**:
- Changes sync within 5 seconds
- Offline changes sync on reconnection
- Conflicts resolved by timestamp
- Data consistency maintained

### Scenario 4: Reports & Analytics
**Validates**: FR-024 through FR-028

**Key Tests**:
- ✅ Report generation (weekly/monthly)
- ✅ Metrics calculation accuracy
- ✅ Data visualization functionality
- ✅ Historical data access
- ✅ Export functionality

**Success Criteria**:
- Accurate session counting
- Correct time calculations
- Charts display properly
- Historical data accessible

### Scenario 5: Recurring Tasks
**Validates**: FR-016 through FR-018

**Key Tests**:
- ✅ Recurrence pattern creation
- ✅ Automatic instance generation
- ✅ Series modification handling
- ✅ End date and cleanup logic
- ✅ Individual vs. series operations

**Success Criteria**:
- New instances created automatically
- Single modifications don't affect series
- Series deletion removes future instances
- Recurrence rules respected

## Performance Validation

### API Response Times
**Target**: <150ms at p95

Monitored endpoints:
- `POST /auth/login` - User authentication
- `GET /tasks` - Task listing
- `POST /tasks` - Task creation
- `POST /pomodoro/sessions` - Session start
- `GET /reports` - Report generation

### Timer Precision
**Target**: ±1 second accuracy

Test cases:
- 5-second precision test
- 1-minute precision test
- 25-minute full session test
- Background execution test

### Memory Usage
**Target**: <100MB sustained usage

Validation includes:
- Memory leak detection
- Garbage collection efficiency
- Sustained load handling
- Peak usage monitoring

## Test Environment

### Backend Configuration
- **URL**: http://localhost:3000/v1
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT tokens
- **Rate Limiting**: Enabled for security testing

### Test Data
- **Test User**: test@example.com
- **Sample Tasks**: Various priorities and due dates
- **Test Sessions**: Multiple Pomodoro sessions
- **Mock Notifications**: FCM test tokens

### Platform Coverage
- **Mobile**: iOS and Android (Flutter)
- **Web**: Chrome, Firefox, Safari
- **Desktop**: Windows, macOS, Linux (Tauri)

## Automation Features

### Shell Script Automation
The `validate_scenarios.sh` script provides:
- Automated backend health checks
- User authentication management
- Comprehensive scenario validation
- Performance metric collection
- JSON response parsing and validation

### Go Test Runner
The `test_runner.go` provides:
- Programmatic test execution
- Detailed timing and performance metrics
- Comprehensive error handling
- Structured result reporting
- Integration with CI/CD pipelines

### Makefile Orchestration
The `Makefile` provides:
- One-command test execution
- Environment validation
- Report generation
- Load and stress testing
- Development mode with auto-restart

## Report Generation

### HTML Reports
Comprehensive HTML reports include:
- Executive summary with pass/fail status
- Detailed scenario breakdowns
- Performance analysis charts
- Issue identification and recommendations
- Environment information

### JSON Reports
Machine-readable JSON reports for:
- CI/CD integration
- Automated analysis
- Historical trend tracking
- Custom tooling integration

## CI/CD Integration

### Pipeline Integration
```yaml
# Example GitHub Actions integration
- name: Run Manual Tests
  run: |
    cd backend/tests/manual
    make ci-test
```

### Exit Codes
- `0`: All tests passed
- `1`: Some tests failed
- `2`: Environment setup failed

## Development Workflow

### Pre-commit Testing
```bash
# Quick validation before commits
make smoke-test
```

### Feature Development
```bash
# Run specific scenario during development
make test-scenario-1

# Watch mode for continuous testing
make watch-test
```

### Performance Monitoring
```bash
# Load testing with multiple users
make load-test

# Stress testing for extended duration
make stress-test

# Memory leak detection
make memory-test
```

## Security Testing

### Vulnerability Checks
- SQL injection prevention
- XSS protection validation
- Rate limiting enforcement
- Authentication bypass attempts
- Input sanitization verification

### Security Test Commands
```bash
# Run security validation
make security-test

# Cross-platform compatibility
make cross-platform-test
```

## Troubleshooting

### Common Issues

1. **Backend Not Accessible**
   ```bash
   # Check backend status
   curl http://localhost:3000/v1/health

   # Start backend if needed
   make run-backend
   ```

2. **Authentication Failures**
   ```bash
   # Verify test user credentials
   echo $TEST_EMAIL $TEST_PASSWORD

   # Check user registration
   curl -X POST http://localhost:3000/v1/auth/register \
        -H "Content-Type: application/json" \
        -d '{"email":"test@example.com","password":"TestPassword123!","name":"Test User"}'
   ```

3. **Missing Dependencies**
   ```bash
   # Install required tools
   sudo apt-get install curl jq  # Ubuntu/Debian
   brew install curl jq          # macOS
   ```

### Debug Mode
```bash
# Enable verbose output
export VERBOSE=true
make test-all
```

### Log Analysis
```bash
# View latest test logs
tail -f reports/test_execution_*.log

# Search for specific errors
grep -i error reports/test_execution_*.log
```

## Best Practices

### Test Data Management
- Use isolated test accounts
- Clean up test data after execution
- Avoid conflicts with production data
- Reset state between test runs

### Performance Testing
- Run tests on consistent hardware
- Monitor system resources during tests
- Account for network latency variations
- Use representative test data volumes

### Validation Criteria
- All scenarios must pass completely
- Performance targets must be met
- No critical security vulnerabilities
- Cross-platform functionality verified

## Contributing

### Adding New Test Scenarios
1. Add scenario to `validate_scenarios.sh`
2. Update `execution_plan.md` checklist
3. Add Makefile target for the scenario
4. Update this documentation

### Modifying Validation Criteria
1. Update target values in scripts
2. Modify success criteria documentation
3. Update CI/CD pipeline configurations
4. Communicate changes to team

## Maintenance

### Regular Updates
- Review and update test scenarios monthly
- Validate against new feature requirements
- Update performance targets as needed
- Refresh test data and credentials

### Tool Versions
- Keep curl and jq updated
- Maintain Go version compatibility
- Update shell script syntax as needed
- Validate cross-platform compatibility

---

This manual testing suite ensures comprehensive validation of the Pomodoro Genie application before production deployment. All scenarios must pass to meet quality standards and user experience requirements.