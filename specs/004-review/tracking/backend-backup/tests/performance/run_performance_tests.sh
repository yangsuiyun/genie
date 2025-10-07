#!/bin/bash

# Pomodoro Genie Backend Performance Test Runner
# Usage: ./run_performance_tests.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPORT_DIR="$SCRIPT_DIR/reports"
LOG_DIR="$REPORT_DIR/logs"

# Default values
RUN_API_TESTS=true
RUN_DB_TESTS=true
RUN_MEMORY_TESTS=true
RUN_BENCHMARKS=false
RUN_SUSTAINED=false
VERBOSE=false
TIMEOUT="10m"
CONCURRENT_USERS=50
TEST_DURATION="30s"

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --api-only              Run only API performance tests"
    echo "  --db-only               Run only database performance tests"
    echo "  --memory-only           Run only memory usage tests"
    echo "  --benchmarks            Run Go benchmarks"
    echo "  --sustained             Run sustained load tests (longer duration)"
    echo "  --timeout DURATION      Test timeout [default: 10m]"
    echo "  --users COUNT           Concurrent users for load tests [default: 50]"
    echo "  --duration DURATION     Test duration [default: 30s]"
    echo "  -v, --verbose           Verbose output"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run all performance tests"
    echo "  $0 --api-only --verbose # Run only API tests with verbose output"
    echo "  $0 --sustained --users 100 --duration 5m"
    echo "  $0 --benchmarks         # Run Go benchmarks"
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
        --api-only)
            RUN_API_TESTS=true
            RUN_DB_TESTS=false
            RUN_MEMORY_TESTS=false
            shift
            ;;
        --db-only)
            RUN_API_TESTS=false
            RUN_DB_TESTS=true
            RUN_MEMORY_TESTS=false
            shift
            ;;
        --memory-only)
            RUN_API_TESTS=false
            RUN_DB_TESTS=false
            RUN_MEMORY_TESTS=true
            shift
            ;;
        --benchmarks)
            RUN_BENCHMARKS=true
            shift
            ;;
        --sustained)
            RUN_SUSTAINED=true
            TEST_DURATION="5m"
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --users)
            CONCURRENT_USERS="$2"
            shift 2
            ;;
        --duration)
            TEST_DURATION="$2"
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

    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        error "Go is not installed. Please install Go 1.21+"
        exit 1
    fi

    # Check Go version
    go_version=$(go version | awk '{print $3}' | sed 's/go//')
    required_version="1.21"
    if ! printf '%s\n%s\n' "$required_version" "$go_version" | sort -V -C; then
        error "Go version $go_version is too old. Required: $required_version+"
        exit 1
    fi

    # Check if we're in the right directory
    if [[ ! -f "$BACKEND_DIR/go.mod" ]]; then
        error "Backend go.mod not found. Make sure you're running from the correct directory."
        exit 1
    fi

    # Check if dependencies are available
    cd "$BACKEND_DIR"
    if ! go mod download; then
        error "Failed to download Go dependencies"
        exit 1
    fi

    success "Prerequisites check passed"
}

# Set environment variables
setup_environment() {
    log "Setting up environment variables..."

    # Export test configuration
    export PERF_TEST_DURATION="$TEST_DURATION"
    export PERF_CONCURRENT_USERS="$CONCURRENT_USERS"
    export PERF_TARGET_RPS="500"
    export PERF_ERROR_THRESHOLD="0.01"

    # Check if database environment variables are set
    if [[ -z "$SUPABASE_URL" ]] || [[ -z "$SUPABASE_KEY" ]]; then
        warning "Supabase environment variables not set. Some tests may be skipped."
        warning "Set SUPABASE_URL and SUPABASE_KEY for full integration testing."
    fi

    # Set Go test environment
    export CGO_ENABLED=0
    export GOOS=$(go env GOOS)
    export GOARCH=$(go env GOARCH)

    log "Environment configured for $CONCURRENT_USERS concurrent users, $TEST_DURATION duration"
}

# Run API performance tests
run_api_performance_tests() {
    if [[ "$RUN_API_TESTS" != "true" ]]; then
        return 0
    fi

    log "Running API performance tests..."

    local test_args="-v -timeout=$TIMEOUT"
    if [[ "$VERBOSE" == "true" ]]; then
        test_args="$test_args -count=1"
    fi

    local output_file="$LOG_DIR/api_performance.log"

    if go test $test_args -run="TestAuth.*Performance|TestTask.*Performance|TestPomodoro.*Performance" ./tests/performance/ 2>&1 | tee "$output_file"; then
        success "API performance tests passed"
        return 0
    else
        error "API performance tests failed"
        return 1
    fi
}

# Run database performance tests
run_database_performance_tests() {
    if [[ "$RUN_DB_TESTS" != "true" ]]; then
        return 0
    fi

    log "Running database performance tests..."

    local test_args="-v -timeout=$TIMEOUT"
    if [[ "$VERBOSE" == "true" ]]; then
        test_args="$test_args -count=1"
    fi

    local output_file="$LOG_DIR/database_performance.log"

    if go test $test_args -run="Test.*Operations.*Performance|TestBatch.*Performance|TestConcurrent.*Operations" ./tests/performance/ 2>&1 | tee "$output_file"; then
        success "Database performance tests passed"
        return 0
    else
        error "Database performance tests failed"
        return 1
    fi
}

# Run memory usage tests
run_memory_tests() {
    if [[ "$RUN_MEMORY_TESTS" != "true" ]]; then
        return 0
    fi

    log "Running memory usage tests..."

    local test_args="-v -timeout=$TIMEOUT"
    if [[ "$VERBOSE" == "true" ]]; then
        test_args="$test_args -count=1"
    fi

    local output_file="$LOG_DIR/memory_usage.log"

    if go test $test_args -run="TestMemory.*" ./tests/performance/ 2>&1 | tee "$output_file"; then
        success "Memory usage tests passed"
        return 0
    else
        error "Memory usage tests failed"
        return 1
    fi
}

# Run sustained load tests
run_sustained_load_tests() {
    if [[ "$RUN_SUSTAINED" != "true" ]]; then
        return 0
    fi

    log "Running sustained load tests (this may take several minutes)..."

    local test_args="-v -timeout=30m"
    local output_file="$LOG_DIR/sustained_load.log"

    if go test $test_args -run="TestSustainedLoad|TestConcurrentLoad" ./tests/performance/ 2>&1 | tee "$output_file"; then
        success "Sustained load tests passed"
        return 0
    else
        error "Sustained load tests failed"
        return 1
    fi
}

# Run Go benchmarks
run_benchmarks() {
    if [[ "$RUN_BENCHMARKS" != "true" ]]; then
        return 0
    fi

    log "Running Go benchmarks..."

    local bench_args="-v -bench=. -benchtime=30s -timeout=$TIMEOUT"
    local output_file="$LOG_DIR/benchmarks.log"

    if go test $bench_args ./tests/performance/ 2>&1 | tee "$output_file"; then
        success "Benchmarks completed"
        return 0
    else
        error "Benchmarks failed"
        return 1
    fi
}

# Generate performance report
generate_report() {
    log "Generating performance report..."

    local report_file="$REPORT_DIR/performance_report.html"
    local summary_file="$REPORT_DIR/summary.json"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Pomodoro Genie Performance Test Report</title>
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
        <h1>Pomodoro Genie Performance Test Report</h1>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>Test Duration:</strong> $TEST_DURATION</p>
        <p><strong>Concurrent Users:</strong> $CONCURRENT_USERS</p>
        <p><strong>Test Environment:</strong> $(go env GOOS)/$(go env GOARCH)</p>
        <p><strong>Go Version:</strong> $(go version)</p>
    </div>

    <div class="test-section">
        <h2>Test Summary</h2>
        <div class="metrics">
            <div class="metric">
                <strong>API Tests:</strong> $([ "$RUN_API_TESTS" == "true" ] && echo "Executed" || echo "Skipped")
            </div>
            <div class="metric">
                <strong>Database Tests:</strong> $([ "$RUN_DB_TESTS" == "true" ] && echo "Executed" || echo "Skipped")
            </div>
            <div class="metric">
                <strong>Memory Tests:</strong> $([ "$RUN_MEMORY_TESTS" == "true" ] && echo "Executed" || echo "Skipped")
            </div>
            <div class="metric">
                <strong>Sustained Load:</strong> $([ "$RUN_SUSTAINED" == "true" ] && echo "Executed" || echo "Skipped")
            </div>
            <div class="metric">
                <strong>Benchmarks:</strong> $([ "$RUN_BENCHMARKS" == "true" ] && echo "Executed" || echo "Skipped")
            </div>
        </div>
    </div>

    <div class="test-section">
        <h2>Performance Thresholds</h2>
        <table>
            <tr><th>Metric</th><th>Threshold</th><th>Description</th></tr>
            <tr><td>API Response Time</td><td>&lt; 150ms</td><td>Average response time for all endpoints</td></tr>
            <tr><td>Database Query Time</td><td>&lt; 50ms</td><td>Simple database operations</td></tr>
            <tr><td>Complex Query Time</td><td>&lt; 200ms</td><td>Analytics and reporting queries</td></tr>
            <tr><td>Throughput</td><td>&gt; 500 req/s</td><td>Requests per second under normal load</td></tr>
            <tr><td>Error Rate</td><td>&lt; 1%</td><td>Percentage of failed requests</td></tr>
            <tr><td>Memory Usage</td><td>&lt; 100MB</td><td>Maximum memory consumption</td></tr>
        </table>
    </div>

    <div class="test-section">
        <h2>Test Logs</h2>
        <p>Detailed logs are available in the following files:</p>
        <ul>
$(find "$LOG_DIR" -name "*.log" -type f | while read log_file; do
    echo "            <li><a href=\"logs/$(basename "$log_file")\">$(basename "$log_file")</a></li>"
done)
        </ul>
    </div>

    <div class="test-section">
        <h2>Quick Log Preview</h2>
$(find "$LOG_DIR" -name "*.log" -type f | head -3 | while read log_file; do
    echo "        <h3>$(basename "$log_file")</h3>"
    echo "        <div class=\"logs\">$(tail -20 "$log_file" | head -10)</div>"
done)
    </div>
</body>
</html>
EOF

    # Generate JSON summary
    cat > "$summary_file" << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "test_configuration": {
        "duration": "$TEST_DURATION",
        "concurrent_users": $CONCURRENT_USERS,
        "api_tests": $RUN_API_TESTS,
        "database_tests": $RUN_DB_TESTS,
        "memory_tests": $RUN_MEMORY_TESTS,
        "sustained_load": $RUN_SUSTAINED,
        "benchmarks": $RUN_BENCHMARKS
    },
    "environment": {
        "go_version": "$(go version | awk '{print $3}')",
        "os": "$(go env GOOS)",
        "arch": "$(go env GOARCH)"
    },
    "log_files": [
$(find "$LOG_DIR" -name "*.log" -type f | sed 's/.*/"&"/' | paste -sd "," -)
    ]
}
EOF

    success "Performance report generated: $report_file"
    log "Summary JSON: $summary_file"
}

# Monitor system resources during tests
monitor_resources() {
    local pid=$1
    local output_file="$LOG_DIR/system_resources.log"

    (
        echo "Timestamp,CPU%,Memory(MB),Goroutines" > "$output_file"
        while kill -0 $pid 2>/dev/null; do
            if command -v ps &> /dev/null; then
                cpu=$(ps -p $pid -o %cpu= 2>/dev/null || echo "0")
                mem=$(ps -p $pid -o rss= 2>/dev/null || echo "0")
                mem_mb=$((mem / 1024))
                echo "$(date '+%Y-%m-%d %H:%M:%S'),$cpu,$mem_mb,N/A" >> "$output_file"
            fi
            sleep 5
        done
    ) &

    echo $!
}

# Main execution function
main() {
    log "Starting Pomodoro Genie Performance Tests"
    log "Configuration: API=$RUN_API_TESTS, DB=$RUN_DB_TESTS, Memory=$RUN_MEMORY_TESTS, Sustained=$RUN_SUSTAINED"

    setup_directories
    check_prerequisites
    setup_environment

    cd "$BACKEND_DIR"

    local failed_tests=0
    local total_tests=0

    # Run API performance tests
    if [[ "$RUN_API_TESTS" == "true" ]]; then
        ((total_tests++))
        if ! run_api_performance_tests; then
            ((failed_tests++))
        fi
    fi

    # Run database performance tests
    if [[ "$RUN_DB_TESTS" == "true" ]]; then
        ((total_tests++))
        if ! run_database_performance_tests; then
            ((failed_tests++))
        fi
    fi

    # Run memory tests
    if [[ "$RUN_MEMORY_TESTS" == "true" ]]; then
        ((total_tests++))
        if ! run_memory_tests; then
            ((failed_tests++))
        fi
    fi

    # Run sustained load tests
    if [[ "$RUN_SUSTAINED" == "true" ]]; then
        ((total_tests++))
        if ! run_sustained_load_tests; then
            ((failed_tests++))
        fi
    fi

    # Run benchmarks
    if [[ "$RUN_BENCHMARKS" == "true" ]]; then
        run_benchmarks
    fi

    # Generate report
    generate_report

    # Report results
    echo ""
    echo "=========================="
    echo "   PERFORMANCE TEST RESULTS"
    echo "=========================="
    echo ""

    if [[ $failed_tests -eq 0 ]]; then
        success "All performance tests passed! ($total_tests/$total_tests)"
        echo ""
        log "Performance report: $REPORT_DIR/performance_report.html"
        exit 0
    else
        error "Some performance tests failed ($failed_tests/$total_tests)"
        echo ""
        log "Check the detailed logs in: $LOG_DIR/"
        log "Performance report: $REPORT_DIR/performance_report.html"
        exit 1
    fi
}

# Run main function
main "$@"