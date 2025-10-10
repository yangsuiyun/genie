#!/bin/bash
# Contract test for GET /workflows/{workflow_name}/errors endpoint
set -euo pipefail

# This test MUST FAIL initially (TDD approach)
echo "🧪 Testing GET /workflows/{workflow_name}/errors contract..."

WORKFLOW_NAME="build-macos-app"

echo "Testing workflow errors endpoint..."

# Expected response schema validation
expected_error_fields=("id" "step_name" "error_type" "error_message" "error_details" "suggested_resolution" "retry_count" "is_transient" "created_at")
echo "Expected error fields: ${expected_error_fields[*]}"

# Expected error types
error_types=("network" "build" "dependency" "timeout" "configuration")
echo "Expected error types: ${error_types[*]}"

# Test cases that should be implemented
test_cases=(
    "GET /workflows/build-macos-app/errors - should return 200"
    "GET /workflows/build-macos-app/errors - should return array of errors"
    "GET /workflows/build-macos-app/errors - should include error classification"
    "GET /workflows/build-macos-app/errors - should provide suggested resolutions"
    "GET /workflows/nonexistent/errors - should return 404"
    "GET /workflows/successful-workflow/errors - should return empty array"
)

echo "Contract test cases to implement:"
for test_case in "${test_cases[@]}"; do
    echo "  - $test_case"
done

# Validation rules to implement
echo "📋 Validation rules:"
echo "  - error_type must be one of: ${error_types[*]}"
echo "  - retry_count >= 0"
echo "  - is_transient must be boolean"
echo "  - created_at must be valid ISO timestamp"

# This test intentionally fails to follow TDD
echo "❌ Contract test FAILS: Errors API not implemented yet"
echo "📋 Requirements:"
echo "  - Endpoint: GET /workflows/{workflow_name}/errors"
echo "  - Response: 200 OK with array of ErrorReport schema"
echo "  - Error classification and suggested resolutions"

exit 1