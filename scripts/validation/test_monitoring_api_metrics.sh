#!/bin/bash
# Contract test for GET /workflows/{workflow_name}/metrics endpoint
set -euo pipefail

# This test MUST FAIL initially (TDD approach)
echo "🧪 Testing GET /workflows/{workflow_name}/metrics contract..."

WORKFLOW_NAME="build-macos-app"
DAYS_PARAM=7

echo "Testing workflow metrics endpoint..."

# Expected response schema validation
expected_fields=("workflow_name" "total_runs" "successful_runs" "failed_runs" "success_rate" "avg_duration_seconds" "p95_duration_seconds")
echo "Expected fields: ${expected_fields[*]}"

# Test cases that should be implemented
test_cases=(
    "GET /workflows/build-macos-app/metrics - should return 200"
    "GET /workflows/build-macos-app/metrics?days=7 - should accept days parameter"
    "GET /workflows/build-macos-app/metrics - should include performance metrics"
    "GET /workflows/build-macos-app/metrics - should validate metrics ranges"
    "GET /workflows/nonexistent/metrics - should return 404"
)

echo "Contract test cases to implement:"
for test_case in "${test_cases[@]}"; do
    echo "  - $test_case"
done

# Validation rules to implement
echo "📋 Validation rules:"
echo "  - total_runs >= 0"
echo "  - successful_runs + failed_runs = total_runs"
echo "  - success_rate between 0 and 100"
echo "  - duration metrics > 0"

# This test intentionally fails to follow TDD
echo "❌ Contract test FAILS: Metrics API not implemented yet"
echo "📋 Requirements:"
echo "  - Endpoint: GET /workflows/{workflow_name}/metrics"
echo "  - Query params: days (optional, default 7)"
echo "  - Response: 200 OK with PerformanceMetrics schema"

exit 1