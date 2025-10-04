#!/bin/bash

# Pomodoro Genie E2E Test Runner
# Usage: ./run_tests.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_ID="com.pomodoro.genie"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${TEST_DIR}/reports"
SCREENSHOTS_DIR="${REPORT_DIR}/screenshots"
LOGS_DIR="${REPORT_DIR}/logs"

# Default values
DEVICE=""
PLATFORM="android"
TAG=""
SUITE=""
HEADLESS=false
PARALLEL=false
RETRY_COUNT=2

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --device DEVICE     Target device (e.g., emulator-5554, iPhone-13)"
    echo "  -p, --platform PLATFORM Platform (android|ios) [default: android]"
    echo "  -t, --tag TAG          Run tests with specific tag"
    echo "  -s, --suite SUITE      Run specific test suite"
    echo "  -h, --headless         Run in headless mode"
    echo "  -j, --parallel         Run tests in parallel"
    echo "  -r, --retry COUNT      Number of retries [default: 2]"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --platform android --tag critical"
    echo "  $0 --suite auth_flow.yaml --device emulator-5554"
    echo "  $0 --parallel --headless"
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
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -s|--suite)
            SUITE="$2"
            shift 2
            ;;
        -h|--headless)
            HEADLESS=true
            shift
            ;;
        -j|--parallel)
            PARALLEL=true
            shift
            ;;
        -r|--retry)
            RETRY_COUNT="$2"
            shift 2
            ;;
        --help)
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
    log "Setting up test directories..."
    mkdir -p "$REPORT_DIR"
    mkdir -p "$SCREENSHOTS_DIR"
    mkdir -p "$LOGS_DIR"

    # Clean previous reports
    rm -rf "${REPORT_DIR}"/*
    mkdir -p "$SCREENSHOTS_DIR"
    mkdir -p "$LOGS_DIR"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check if Maestro is installed
    if ! command -v maestro &> /dev/null; then
        error "Maestro is not installed. Please install it first:"
        echo "  curl -Ls 'https://get.maestro.mobile.dev' | bash"
        exit 1
    fi

    # Check if Flutter is installed (for Flutter projects)
    if ! command -v flutter &> /dev/null; then
        warning "Flutter is not installed. Some features may not work."
    fi

    # Check if ADB is available (for Android)
    if [[ "$PLATFORM" == "android" ]] && ! command -v adb &> /dev/null; then
        error "ADB is not available. Please install Android SDK."
        exit 1
    fi

    success "Prerequisites check passed"
}

# Detect available devices
detect_devices() {
    log "Detecting available devices..."

    if [[ "$PLATFORM" == "android" ]]; then
        local devices=$(adb devices | grep -v "List of devices" | grep "device$" | awk '{print $1}')
        if [[ -z "$devices" ]]; then
            error "No Android devices found. Please start an emulator or connect a device."
            exit 1
        fi

        if [[ -z "$DEVICE" ]]; then
            DEVICE=$(echo "$devices" | head -n1)
            log "Using device: $DEVICE"
        fi
    elif [[ "$PLATFORM" == "ios" ]]; then
        # iOS device detection would require xcrun simctl list
        if [[ -z "$DEVICE" ]]; then
            warning "No iOS device specified. Using default simulator."
        fi
    fi
}

# Start app
start_app() {
    log "Starting app: $APP_ID"

    if [[ "$PLATFORM" == "android" ]]; then
        adb -s "$DEVICE" shell am start -n "$APP_ID/.MainActivity" || {
            error "Failed to start app. Make sure the app is installed."
            exit 1
        }
    fi

    # Wait for app to start
    sleep 3
}

# Run specific test suite
run_test_suite() {
    local suite_file="$1"
    local suite_name=$(basename "$suite_file" .yaml)

    log "Running test suite: $suite_name"

    local cmd="maestro test"

    # Add device parameter
    if [[ -n "$DEVICE" ]]; then
        cmd="$cmd --device $DEVICE"
    fi

    # Add output directory
    cmd="$cmd --output $LOGS_DIR"

    # Add format
    cmd="$cmd --format junit"

    # Add retry count
    cmd="$cmd --retry $RETRY_COUNT"

    # Add the test file
    cmd="$cmd $suite_file"

    # Execute the command
    if eval "$cmd"; then
        success "Test suite '$suite_name' passed"
        return 0
    else
        error "Test suite '$suite_name' failed"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    local failed_tests=()
    local passed_tests=()

    # Get list of test files
    local test_files=()

    if [[ -n "$SUITE" ]]; then
        test_files=("$SUITE")
    elif [[ -n "$TAG" ]]; then
        # Find test files with specific tag (would need to parse YAML)
        test_files=($(find "$TEST_DIR" -name "*.yaml" -not -path "*/shared/*"))
    else
        test_files=($(find "$TEST_DIR" -name "*_flow.yaml"))
    fi

    if [[ ${#test_files[@]} -eq 0 ]]; then
        warning "No test files found matching criteria"
        return 0
    fi

    log "Found ${#test_files[@]} test suite(s) to run"

    # Run tests
    for test_file in "${test_files[@]}"; do
        if [[ ! -f "$test_file" ]]; then
            test_file="$TEST_DIR/$test_file"
        fi

        if [[ -f "$test_file" ]]; then
            if run_test_suite "$test_file"; then
                passed_tests+=("$(basename "$test_file")")
            else
                failed_tests+=("$(basename "$test_file")")
            fi
        else
            warning "Test file not found: $test_file"
        fi
    done

    # Report results
    echo ""
    echo "=========================="
    echo "        TEST RESULTS      "
    echo "=========================="
    echo ""

    if [[ ${#passed_tests[@]} -gt 0 ]]; then
        success "Passed tests (${#passed_tests[@]}):"
        for test in "${passed_tests[@]}"; do
            echo "  ✓ $test"
        done
        echo ""
    fi

    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        error "Failed tests (${#failed_tests[@]}):"
        for test in "${failed_tests[@]}"; do
            echo "  ✗ $test"
        done
        echo ""
        return 1
    fi

    success "All tests passed!"
    return 0
}

# Generate HTML report
generate_report() {
    log "Generating test report..."

    local report_file="$REPORT_DIR/index.html"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Pomodoro Genie E2E Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        .test-suite { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .logs { background: #f8f8f8; padding: 10px; font-family: monospace; white-space: pre-wrap; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Pomodoro Genie E2E Test Report</h1>
        <p>Generated on: $(date)</p>
        <p>Platform: $PLATFORM</p>
        <p>Device: $DEVICE</p>
    </div>

    <div class="test-suite">
        <h2>Test Execution Summary</h2>
        <p>Check the logs directory for detailed results: <code>$LOGS_DIR</code></p>
    </div>
</body>
</html>
EOF

    success "Report generated: $report_file"
}

# Main execution
main() {
    log "Starting Pomodoro Genie E2E Tests"
    log "Platform: $PLATFORM"
    log "Device: $DEVICE"

    setup_directories
    check_prerequisites
    detect_devices
    start_app

    if run_all_tests; then
        generate_report
        success "All E2E tests completed successfully!"
        exit 0
    else
        generate_report
        error "Some E2E tests failed. Check the reports for details."
        exit 1
    fi
}

# Run main function
main "$@"