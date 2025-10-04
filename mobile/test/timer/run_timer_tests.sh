#!/bin/bash

# Pomodoro Genie Timer Precision Test Runner
# Usage: ./run_timer_tests.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_DIR="$SCRIPT_DIR/reports"
LOG_DIR="$REPORT_DIR/logs"

# Default values
RUN_PRECISION_TESTS=true
RUN_STRESS_TESTS=true
MONITOR_PERFORMANCE=false
VERBOSE=false
COVERAGE=false
DEVICE=""
TIMEOUT="5m"

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --precision-only        Run only precision tests"
    echo "  --stress-only           Run only stress tests"
    echo "  --monitor-performance   Monitor performance metrics during tests"
    echo "  --coverage              Generate coverage report"
    echo "  --device DEVICE         Target specific device"
    echo "  --timeout DURATION      Test timeout [default: 5m]"
    echo "  -v, --verbose           Verbose output"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run all timer tests"
    echo "  $0 --precision-only     # Run only precision tests"
    echo "  $0 --stress-only --verbose"
    echo "  $0 --coverage --device flutter-test"
}

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --precision-only)
            RUN_PRECISION_TESTS=true
            RUN_STRESS_TESTS=false
            shift
            ;;
        --stress-only)
            RUN_PRECISION_TESTS=false
            RUN_STRESS_TESTS=true
            shift
            ;;
        --monitor-performance)
            MONITOR_PERFORMANCE=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --device)
            DEVICE="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Setup directories
setup_directories() {
    log "Setting up report directories..."
    mkdir -p "$REPORT_DIR"
    mkdir -p "$LOG_DIR"

    # Clean previous reports
    rm -rf "${REPORT_DIR}"/*
    mkdir -p "$LOG_DIR"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        error "Flutter is not installed. Please install Flutter SDK."
        exit 1
    fi

    # Check Flutter version
    flutter_version=$(flutter --version | head -n1 | awk '{print $2}')
    log "Flutter version: $flutter_version"

    # Check if we're in the mobile directory
    if [[ ! -f "$MOBILE_DIR/pubspec.yaml" ]]; then
        error "pubspec.yaml not found. Make sure you're running from the mobile directory."
        exit 1
    fi

    # Get dependencies
    cd "$MOBILE_DIR"
    if ! flutter pub get; then
        error "Failed to get Flutter dependencies"
        exit 1
    fi

    success "Prerequisites check passed"
}

# Check device availability
check_device() {
    if [[ -n "$DEVICE" ]]; then
        log "Checking device: $DEVICE"
        if ! flutter devices | grep -q "$DEVICE"; then
            error "Device '$DEVICE' not found"
            flutter devices
            exit 1
        fi
    else
        log "Using default device"
        flutter devices
    fi
}

# Run precision tests
run_precision_tests() {
    if [[ "$RUN_PRECISION_TESTS" != "true" ]]; then
        return 0
    fi

    log "Running timer precision tests..."

    local test_args=""
    if [[ "$VERBOSE" == "true" ]]; then
        test_args="$test_args --verbose"
    fi
    if [[ "$COVERAGE" == "true" ]]; then
        test_args="$test_args --coverage"
    fi
    if [[ -n "$DEVICE" ]]; then
        test_args="$test_args --device-id $DEVICE"
    fi

    local output_file="$LOG_DIR/precision_tests.log"

    log "Test command: flutter test test/timer/timer_precision_test.dart $test_args"

    if timeout "$TIMEOUT" flutter test test/timer/timer_precision_test.dart $test_args 2>&1 | tee "$output_file"; then
        success "Timer precision tests passed"
        return 0
    else
        error "Timer precision tests failed"
        return 1
    fi
}

# Run stress tests
run_stress_tests() {
    if [[ "$RUN_STRESS_TESTS" != "true" ]]; then
        return 0
    fi

    log "Running timer stress tests..."

    local test_args=""
    if [[ "$VERBOSE" == "true" ]]; then
        test_args="$test_args --verbose"
    fi
    if [[ -n "$DEVICE" ]]; then
        test_args="$test_args --device-id $DEVICE"
    fi

    local output_file="$LOG_DIR/stress_tests.log"

    log "Test command: flutter test test/timer/timer_stress_test.dart $test_args"

    if timeout "$TIMEOUT" flutter test test/timer/timer_stress_test.dart $test_args 2>&1 | tee "$output_file"; then
        success "Timer stress tests passed"
        return 0
    else
        error "Timer stress tests failed"
        return 1
    fi
}

# Monitor performance during tests
monitor_performance() {
    if [[ "$MONITOR_PERFORMANCE" != "true" ]]; then
        return
    fi

    log "Starting performance monitoring..."

    local monitor_output="$LOG_DIR/performance_monitor.log"

    # Monitor system resources
    (
        echo "Timestamp,CPU%,Memory(MB),Battery%" > "$monitor_output"
        while true; do
            # Get system stats (simplified for demo)
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            cpu_usage="N/A"
            memory_usage="N/A"
            battery_level="N/A"

            # On macOS, could use: top -l 1 -n 0 | grep "CPU usage"
            # On Linux, could use: top -bn1 | grep "Cpu(s)"
            # For now, just log timestamp
            echo "$timestamp,$cpu_usage,$memory_usage,$battery_level" >> "$monitor_output"

            sleep 5
        done
    ) &

    MONITOR_PID=$!
    return 0
}

# Stop performance monitoring
stop_performance_monitoring() {
    if [[ -n "$MONITOR_PID" ]]; then
        kill $MONITOR_PID 2>/dev/null || true
        wait $MONITOR_PID 2>/dev/null || true
        log "Performance monitoring stopped"
    fi
}

# Analyze test results
analyze_results() {
    log "Analyzing test results..."

    local precision_log="$LOG_DIR/precision_tests.log"
    local stress_log="$LOG_DIR/stress_tests.log"

    # Extract precision statistics
    if [[ -f "$precision_log" && "$RUN_PRECISION_TESTS" == "true" ]]; then
        log "Precision Test Analysis:"

        # Look for timing statistics in logs
        if grep -q "Timer Precision Statistics:" "$precision_log"; then
            grep -A 10 "Timer Precision Statistics:" "$precision_log" | while read line; do
                log "  $line"
            done
        fi

        # Count passed/failed tests
        local passed_precision=$(grep -c "✓" "$precision_log" 2>/dev/null || echo "0")
        local failed_precision=$(grep -c "✗" "$precision_log" 2>/dev/null || echo "0")

        log "  Precision Tests: $passed_precision passed, $failed_precision failed"
    fi

    # Extract stress test statistics
    if [[ -f "$stress_log" && "$RUN_STRESS_TESTS" == "true" ]]; then
        log "Stress Test Analysis:"

        local passed_stress=$(grep -c "✓" "$stress_log" 2>/dev/null || echo "0")
        local failed_stress=$(grep -c "✗" "$stress_log" 2>/dev/null || echo "0")

        log "  Stress Tests: $passed_stress passed, $failed_stress failed"
    fi
}

# Generate HTML report
generate_report() {
    log "Generating test report..."

    local report_file="$REPORT_DIR/timer_precision_report.html"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Timer Precision Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .metrics { display: flex; flex-wrap: wrap; gap: 15px; margin: 15px 0; }
        .metric { background: #f8f8f8; padding: 10px; border-radius: 3px; min-width: 150px; }
        .logs { background: #f8f8f8; padding: 10px; font-family: monospace; white-space: pre-wrap; max-height: 300px; overflow-y: auto; }
        table { border-collapse: collapse; width: 100%; margin: 15px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Timer Precision Test Report</h1>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>Flutter Version:</strong> $(flutter --version | head -n1 | awk '{print $2}')</p>
        <p><strong>Device:</strong> ${DEVICE:-"Default"}</p>
        <p><strong>Test Timeout:</strong> $TIMEOUT</p>
    </div>

    <div class="test-section">
        <h2>Test Configuration</h2>
        <div class="metrics">
            <div class="metric">
                <strong>Precision Tests:</strong> $([ "$RUN_PRECISION_TESTS" == "true" ] && echo "Executed" || echo "Skipped")
            </div>
            <div class="metric">
                <strong>Stress Tests:</strong> $([ "$RUN_STRESS_TESTS" == "true" ] && echo "Executed" || echo "Skipped")
            </div>
            <div class="metric">
                <strong>Performance Monitoring:</strong> $([ "$MONITOR_PERFORMANCE" == "true" ] && echo "Enabled" || echo "Disabled")
            </div>
            <div class="metric">
                <strong>Coverage:</strong> $([ "$COVERAGE" == "true" ] && echo "Generated" || echo "Disabled")
            </div>
        </div>
    </div>

    <div class="test-section">
        <h2>Precision Requirements</h2>
        <table>
            <tr><th>Scenario</th><th>Target Precision</th><th>Description</th></tr>
            <tr><td>Standard Operations</td><td>±1 second</td><td>Normal timer start/stop/pause/resume</td></tr>
            <tr><td>Short Timers (&lt;5s)</td><td>±500ms</td><td>Very short duration timers</td></tr>
            <tr><td>Stress Conditions</td><td>±1.5 seconds</td><td>Under memory/CPU pressure</td></tr>
            <tr><td>Long Timers (&gt;25min)</td><td>±2 seconds</td><td>Extended duration monitoring</td></tr>
        </table>
    </div>

    <div class="test-section">
        <h2>Test Results</h2>
$(if [[ -f "$LOG_DIR/precision_tests.log" && "$RUN_PRECISION_TESTS" == "true" ]]; then
    echo "        <h3>Precision Tests</h3>"
    echo "        <div class=\"logs\">$(tail -50 "$LOG_DIR/precision_tests.log")</div>"
fi)
$(if [[ -f "$LOG_DIR/stress_tests.log" && "$RUN_STRESS_TESTS" == "true" ]]; then
    echo "        <h3>Stress Tests</h3>"
    echo "        <div class=\"logs\">$(tail -50 "$LOG_DIR/stress_tests.log")</div>"
fi)
    </div>

    <div class="test-section">
        <h2>Available Logs</h2>
        <ul>
$(find "$LOG_DIR" -name "*.log" -type f | while read log_file; do
    echo "            <li><a href=\"logs/$(basename "$log_file")\">$(basename "$log_file")</a></li>"
done)
        </ul>
    </div>

$(if [[ "$COVERAGE" == "true" && -f "$MOBILE_DIR/coverage/lcov.info" ]]; then
    echo "    <div class=\"test-section\">"
    echo "        <h2>Coverage Report</h2>"
    echo "        <p>Coverage data generated at: <code>coverage/lcov.info</code></p>"
    echo "    </div>"
fi)
</body>
</html>
EOF

    success "Test report generated: $report_file"
}

# Cleanup function
cleanup() {
    stop_performance_monitoring
    log "Cleanup completed"
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    log "Starting Timer Precision Tests"
    log "Configuration: Precision=$RUN_PRECISION_TESTS, Stress=$RUN_STRESS_TESTS, Performance=$MONITOR_PERFORMANCE"

    setup_directories
    check_prerequisites
    check_device

    cd "$MOBILE_DIR"

    local failed_tests=0
    local total_tests=0

    # Start performance monitoring if requested
    if [[ "$MONITOR_PERFORMANCE" == "true" ]]; then
        monitor_performance
    fi

    # Run precision tests
    if [[ "$RUN_PRECISION_TESTS" == "true" ]]; then
        ((total_tests++))
        if ! run_precision_tests; then
            ((failed_tests++))
        fi
    fi

    # Run stress tests
    if [[ "$RUN_STRESS_TESTS" == "true" ]]; then
        ((total_tests++))
        if ! run_stress_tests; then
            ((failed_tests++))
        fi
    fi

    # Stop performance monitoring
    stop_performance_monitoring

    # Analyze results
    analyze_results

    # Generate report
    generate_report

    # Report final results
    echo ""
    echo "=========================="
    echo "   TIMER PRECISION TEST RESULTS"
    echo "=========================="
    echo ""

    if [[ $failed_tests -eq 0 ]]; then
        success "All timer precision tests passed! ($total_tests/$total_tests)"
        echo ""
        log "Detailed report: $REPORT_DIR/timer_precision_report.html"
        exit 0
    else
        error "Some timer precision tests failed ($failed_tests/$total_tests)"
        echo ""
        log "Check detailed logs in: $LOG_DIR/"
        log "Report available at: $REPORT_DIR/timer_precision_report.html"
        exit 1
    fi
}

# Run main function
main "$@"