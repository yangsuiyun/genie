# E2E Testing with Maestro

This directory contains end-to-end tests for the Pomodoro Genie mobile application using [Maestro](https://maestro.mobile.dev/).

## Prerequisites

1. **Install Maestro**:
   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```

2. **Android Setup** (for Android testing):
   - Install Android SDK
   - Start an emulator or connect a physical device
   - Verify with: `adb devices`

3. **iOS Setup** (for iOS testing):
   - Install Xcode
   - Start iOS Simulator
   - Verify with: `xcrun simctl list`

4. **App Installation**:
   - Build and install the Pomodoro Genie app on your test device
   - Ensure the app can be launched

## Test Structure

```
test/e2e/
├── auth_flow.yaml                    # Authentication tests
├── task_management_flow.yaml         # Task CRUD operations
├── pomodoro_flow.yaml                # Timer functionality
├── reports_and_analytics_flow.yaml   # Reports and analytics
├── settings_and_sync_flow.yaml       # Settings and sync
├── maestro.yaml                      # Main configuration
├── run_tests.sh                      # Test runner script
├── shared/
│   ├── setup_app.yaml               # Basic app setup
│   └── setup_authenticated.yaml     # Authenticated user setup
└── README.md                        # This file
```

## Running Tests

### Quick Start

```bash
# Run all tests
./run_tests.sh

# Run specific test suite
./run_tests.sh --suite auth_flow.yaml

# Run tests with specific tag
./run_tests.sh --tag critical

# Run on specific device
./run_tests.sh --device emulator-5554

# Run in parallel (faster)
./run_tests.sh --parallel
```

### Manual Maestro Commands

```bash
# Run a single test file
maestro test auth_flow.yaml

# Run with specific device
maestro test --device emulator-5554 auth_flow.yaml

# Run with output
maestro test --output ./reports auth_flow.yaml
```

## Test Scenarios Covered

### 1. Authentication Flow (`auth_flow.yaml`)
- User registration with validation
- Login with valid/invalid credentials
- Password visibility toggle
- Forgot password flow
- Form validation testing

### 2. Task Management (`task_management_flow.yaml`)
- Task creation and editing
- Subtask management
- Task filtering and search
- Task completion workflow
- Task deletion

### 3. Pomodoro Timer (`pomodoro_flow.yaml`)
- Basic timer functionality
- Pause/resume operations
- Session completion
- Timer settings configuration
- Background timer behavior
- Session history

### 4. Reports and Analytics (`reports_and_analytics_flow.yaml`)
- Daily, weekly, monthly reports
- Productivity analytics
- Category breakdown
- Goal tracking
- Report export
- Comparison reports

### 5. Settings and Sync (`settings_and_sync_flow.yaml`)
- User preferences
- Notification settings
- Data synchronization
- Account management
- Privacy settings
- Cross-device sync

## Test Configuration

### Environment Variables
Tests use the following environment variables (defined in `maestro.yaml`):
- `APP_ID`: com.pomodoro.genie
- `TEST_EMAIL`: test@example.com
- `TEST_PASSWORD`: testpassword123
- `API_BASE_URL`: http://localhost:3000

### Performance Thresholds
- App launch time: < 3 seconds
- Screen transitions: < 1 second
- API responses: < 2 seconds
- Sync operations: < 5 seconds

## Custom Commands

The test suite includes reusable commands defined in `maestro.yaml`:

```yaml
commands:
  - name: "login"
    # Performs standard login flow

  - name: "create_test_task"
    # Creates a task with specified title and description

  - name: "start_pomodoro"
    # Starts a pomodoro session for specified task
```

## Test Data

Test data is defined in `maestro.yaml` and includes:
- Test user accounts
- Sample tasks with various priorities
- Performance benchmarks

## Troubleshooting

### Common Issues

1. **App not found**:
   - Ensure the app is installed: `adb shell pm list packages | grep pomodoro`
   - Check APP_ID matches your app's package name

2. **Device not detected**:
   - Android: Run `adb devices` to verify connection
   - iOS: Run `xcrun simctl list` to see available simulators

3. **Tests failing unexpectedly**:
   - Check if backend server is running
   - Verify network connectivity
   - Clear app data between test runs

4. **Element not found**:
   - Use `maestro studio` to inspect UI elements
   - Update selectors in test files if UI changed

### Debugging

```bash
# Run Maestro Studio for interactive debugging
maestro studio

# Enable verbose logging
maestro test --verbose auth_flow.yaml

# Take screenshot for debugging
maestro test --screenshot auth_flow.yaml
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Android Emulator
        # Add emulator setup steps
      - name: Install Maestro
        run: curl -Ls "https://get.maestro.mobile.dev" | bash
      - name: Run E2E Tests
        run: ./mobile/test/e2e/run_tests.sh --headless
```

## Best Practices

1. **Test Independence**: Each test should be able to run independently
2. **Test Data**: Use consistent test data defined in configuration
3. **Timeouts**: Set appropriate timeouts for different operations
4. **Clean State**: Reset app state between test suites
5. **Element Selection**: Use stable element identifiers (IDs over text)
6. **Error Handling**: Include proper assertions and error messages

## Contributing

When adding new tests:

1. Follow the existing naming convention (`*_flow.yaml`)
2. Include proper setup using shared flows
3. Add assertions for all critical user interactions
4. Update this README if adding new test categories
5. Test on both Android and iOS if applicable

## Resources

- [Maestro Documentation](https://maestro.mobile.dev/)
- [Maestro CLI Reference](https://maestro.mobile.dev/cli/)
- [Maestro Testing Best Practices](https://maestro.mobile.dev/best-practices/)