# Timer Precision Testing

This directory contains comprehensive tests for timer precision and accuracy in the Pomodoro Genie mobile application.

## Overview

The timer precision tests ensure that the Pomodoro timer maintains accuracy within ±1 second tolerance under various conditions, as required by the application specifications.

## Test Requirements

- **Precision Target**: ±1 second accuracy for all timer operations
- **Test Coverage**: All timer states (start, pause, resume, stop)
- **Stress Testing**: Performance under load and adverse conditions
- **Edge Cases**: Very short timers, long timers, rapid state changes

## Test Structure

```
mobile/test/timer/
├── timer_precision_test.dart      # Core precision testing
├── timer_stress_test.dart         # Stress and load testing
├── run_timer_tests.sh            # Test runner script
└── README.md                     # This file
```

## Test Categories

### 1. Basic Timer Precision (`timer_precision_test.dart`)

Tests fundamental timer accuracy:

- **Basic Countdown**: Verifies timer counts down with ±1s accuracy
- **Pause/Resume Precision**: Tests accuracy during pause/resume cycles
- **Rapid Start/Stop**: Validates precision with rapid operations
- **Multiple Concurrent Timers**: Ensures accuracy with multiple simultaneous timers
- **Background/Foreground Transitions**: Tests precision during app lifecycle changes

### 2. Timer Edge Cases

- **Very Short Timers**: 1-2 second timers with tighter tolerance
- **Long Timers**: 25+ minute timers with extended monitoring
- **System Time Changes**: Handling system clock adjustments
- **UI Update Precision**: Real-time display accuracy

### 3. Stress Testing (`timer_stress_test.dart`)

Tests timer behavior under adverse conditions:

- **Memory Pressure**: Timer accuracy during high memory usage
- **CPU Intensive Operations**: Precision during computational load
- **Rapid State Changes**: Frequent pause/resume cycles
- **Resource Exhaustion**: Behavior when system resources are limited

## Running Timer Tests

### Prerequisites

1. **Flutter Environment**: Flutter SDK 3.x+ installed
2. **Dependencies**: All pubspec.yaml dependencies installed
3. **Test Framework**: flutter_test and related testing packages

### Quick Start

```bash
# Run all timer precision tests
flutter test test/timer/

# Run specific test file
flutter test test/timer/timer_precision_test.dart

# Run with verbose output
flutter test --verbose test/timer/

# Run stress tests (takes longer)
flutter test test/timer/timer_stress_test.dart
```

### Using the Test Runner

```bash
# Make runner executable
chmod +x test/timer/run_timer_tests.sh

# Run all timer tests
./test/timer/run_timer_tests.sh

# Run only precision tests
./test/timer/run_timer_tests.sh --precision-only

# Run with performance monitoring
./test/timer/run_timer_tests.sh --monitor-performance

# Run stress tests
./test/timer/run_timer_tests.sh --stress-tests
```

## Test Configuration

### Precision Tolerances

Different test scenarios use different tolerance levels:

```dart
// Standard precision tests
const tolerance = Duration(seconds: 1);

// Short timer tests (more lenient)
const shortTimerTolerance = Duration(milliseconds: 500);

// Stress test tolerance (more lenient under load)
const stressTolerance = Duration(milliseconds: 1500);

// UI update tolerance
const uiUpdateTolerance = Duration(milliseconds: 200);
```

### Test Parameters

Key test parameters can be configured:

```dart
// Test durations
const shortTestDuration = Duration(seconds: 2);
const standardTestDuration = Duration(seconds: 5);
const longTestDuration = Duration(seconds: 10);

// Concurrent testing
const maxConcurrentTimers = 20;
const stressTestTimers = 5;

// Update intervals
const uiUpdateInterval = Duration(milliseconds: 100);
const monitoringInterval = Duration(milliseconds: 500);
```

## Test Scenarios

### 1. Normal Operation Tests

- Single timer start/stop precision
- Pause/resume accuracy
- Multiple timer coordination
- State transition timing

### 2. Background/Foreground Tests

- App lifecycle state changes
- Background timer continuation
- Foreground timer resumption
- Notification timing accuracy

### 3. Performance Tests

- Memory pressure scenarios
- CPU intensive background tasks
- Rapid state change handling
- Resource exhaustion recovery

### 4. Edge Case Tests

- Very short duration timers (< 5 seconds)
- Long duration timers (> 25 minutes)
- System time zone changes
- Network connectivity changes

## Precision Measurement

### Measurement Methodology

Timer precision is measured using:

1. **System Time Comparison**: Comparing timer duration with system clock
2. **Multiple Sample Analysis**: Statistical analysis across multiple runs
3. **Drift Detection**: Monitoring cumulative timing errors
4. **State Transition Timing**: Measuring pause/resume precision

### Statistical Analysis

Test results include:

- **Average Difference**: Mean deviation from expected timing
- **Maximum Difference**: Worst-case timing error
- **Standard Deviation**: Consistency of timing accuracy
- **95th Percentile**: Performance under typical conditions

### Expected Results

For passing tests:

```
Timer Precision Statistics:
  Runs: 10
  Average difference: 245ms
  Min difference: 12ms
  Max difference: 890ms
  95th Percentile: < 1000ms
```

## Troubleshooting

### Common Issues

1. **High Timer Drift**:
   - Check system performance during tests
   - Verify no background processes consuming CPU
   - Ensure stable test environment

2. **Inconsistent Results**:
   - Run tests multiple times for statistical significance
   - Check for Flutter engine version compatibility
   - Verify device/emulator performance

3. **Test Timeouts**:
   - Increase test timeout values for slower devices
   - Reduce concurrent timer counts for limited resources
   - Skip stress tests on low-performance devices

### Performance Optimization

1. **Timer Implementation**:
   - Use high-resolution timers when available
   - Minimize timer callback overhead
   - Optimize state management updates

2. **Test Environment**:
   - Run on consistent hardware
   - Close unnecessary applications
   - Use dedicated test devices

3. **Measurement Accuracy**:
   - Account for test framework overhead
   - Use appropriate timing granularity
   - Consider platform-specific timing differences

## Continuous Integration

### GitHub Actions Integration

```yaml
name: Timer Precision Tests
on: [push, pull_request]

jobs:
  timer-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Get dependencies
        run: flutter pub get
        working-directory: mobile

      - name: Run timer precision tests
        run: flutter test test/timer/ --coverage
        working-directory: mobile

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: mobile/coverage/lcov.info
```

### Performance Monitoring

Set up alerts for precision regressions:

1. **Precision Alerts**: Alert if average difference > 500ms
2. **Consistency Alerts**: Alert if standard deviation > 300ms
3. **Failure Rate Alerts**: Alert if > 5% of tests fail precision requirements

## Best Practices

### Test Design

1. **Realistic Scenarios**: Test actual usage patterns
2. **Statistical Significance**: Run multiple iterations
3. **Environmental Control**: Consistent test conditions
4. **Comprehensive Coverage**: All timer states and transitions

### Precision Targets

1. **Primary Target**: ±1 second for standard operations
2. **Stress Target**: ±1.5 seconds under load
3. **Short Timer Target**: ±500ms for < 5 second timers
4. **Long Timer Target**: ±2 seconds for > 25 minute timers

### Maintenance

1. **Regular Testing**: Run precision tests on every commit
2. **Performance Monitoring**: Track timing accuracy trends
3. **Platform Testing**: Verify accuracy across all target platforms
4. **Regression Detection**: Alert on precision degradation

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Dart Timer Class](https://api.dart.dev/stable/dart-async/Timer-class.html)
- [Performance Testing Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Time Precision in Mobile Apps](https://developer.android.com/guide/topics/resources/runtime-changes)