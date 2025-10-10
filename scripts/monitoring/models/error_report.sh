#!/bin/bash
# ErrorReport model - detailed diagnostic information about workflow failures
set -euo pipefail

# ErrorReport data structure and operations
# Based on data-model.md specification

# Create an ErrorReport record
create_error_report() {
    local id="$1"
    local workflow_run_id="$2"
    local step_name="$3"
    local error_type="$4"
    local error_message="$5"
    local error_details="$6"
    local suggested_resolution="$7"
    local retry_count="${8:-0}"
    local is_transient="${9:-false}"
    local created_at="${10:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

    # Validate required fields
    [[ -n "$id" ]] || { echo "Error: id is required"; return 1; }
    [[ -n "$workflow_run_id" ]] || { echo "Error: workflow_run_id is required"; return 1; }
    [[ -n "$step_name" ]] || { echo "Error: step_name is required"; return 1; }
    [[ -n "$error_type" ]] || { echo "Error: error_type is required"; return 1; }
    [[ -n "$error_message" ]] || { echo "Error: error_message is required"; return 1; }

    # Validate error_type enum
    case "$error_type" in
        network|build|dependency|timeout|configuration)
            ;;
        *)
            echo "Error: Invalid error_type '$error_type'. Must be one of: network, build, dependency, timeout, configuration"
            return 1
            ;;
    esac

    # Validate retry_count is non-negative
    if [[ "$retry_count" -lt 0 ]]; then
        echo "Error: retry_count must be non-negative"
        return 1
    fi

    # Validate is_transient is boolean
    case "$is_transient" in
        true|false)
            ;;
        *)
            echo "Error: is_transient must be true or false"
            return 1
            ;;
    esac

    # Create JSON record
    local error_report=$(cat <<EOF
{
    "id": "$id",
    "workflow_run_id": "$workflow_run_id",
    "step_name": "$step_name",
    "error_type": "$error_type",
    "error_message": "$error_message",
    "error_details": "$error_details",
    "suggested_resolution": "$suggested_resolution",
    "retry_count": $retry_count,
    "is_transient": $is_transient,
    "created_at": "$created_at"
}
EOF
)

    echo "$error_report"
}

# Classify error based on message patterns
classify_error() {
    local error_message="$1"
    local step_name="$2"

    local error_type="configuration"  # default
    local is_transient="false"
    local suggested_resolution=""

    # Pattern matching for error classification
    if [[ "$error_message" =~ (timeout|timed.*out|connection.*reset) ]]; then
        error_type="network"
        is_transient="true"
        suggested_resolution="Retry the operation. Check network connectivity and external service status."
    elif [[ "$error_message" =~ (build.*failed|compilation.*error|syntax.*error) ]]; then
        error_type="build"
        is_transient="false"
        suggested_resolution="Fix the build error in the source code and retry."
    elif [[ "$error_message" =~ (dependency|package.*not.*found|module.*not.*found) ]]; then
        error_type="dependency"
        is_transient="true"
        suggested_resolution="Check dependency availability and update package versions."
    elif [[ "$error_message" =~ (timeout|exceeded.*time.*limit) ]]; then
        error_type="timeout"
        is_transient="true"
        suggested_resolution="Increase timeout values or optimize the operation."
    fi

    echo "$error_type,$is_transient,$suggested_resolution"
}

# Validate ErrorReport data
validate_error_report() {
    local error_json="$1"

    # Check required fields
    local id=$(echo "$error_json" | jq -r '.id')
    local workflow_run_id=$(echo "$error_json" | jq -r '.workflow_run_id')
    local step_name=$(echo "$error_json" | jq -r '.step_name')
    local error_type=$(echo "$error_json" | jq -r '.error_type')
    local error_message=$(echo "$error_json" | jq -r '.error_message')

    [[ "$id" != "null" && -n "$id" ]] || { echo "Validation failed: id is required"; return 1; }
    [[ "$workflow_run_id" != "null" && -n "$workflow_run_id" ]] || { echo "Validation failed: workflow_run_id is required"; return 1; }
    [[ "$step_name" != "null" && -n "$step_name" ]] || { echo "Validation failed: step_name is required"; return 1; }
    [[ "$error_type" != "null" && -n "$error_type" ]] || { echo "Validation failed: error_type is required"; return 1; }
    [[ "$error_message" != "null" && -n "$error_message" ]] || { echo "Validation failed: error_message is required"; return 1; }

    # Validate error_type enum
    case "$error_type" in
        network|build|dependency|timeout|configuration)
            ;;
        *)
            echo "Validation failed: Invalid error_type '$error_type'"
            return 1
            ;;
    esac

    # Validate retry_count is non-negative
    local retry_count=$(echo "$error_json" | jq -r '.retry_count')
    if [[ "$retry_count" != "null" && "$retry_count" -lt 0 ]]; then
        echo "Validation failed: retry_count must be non-negative"
        return 1
    fi

    echo "Validation passed"
}

# Get error reports for a workflow run (mock implementation)
get_errors_for_run() {
    local workflow_run_id="$1"

    # Mock response - in real implementation, this would query logs/database
    if [[ "$workflow_run_id" == "failed-run-456" ]]; then
        local errors='[]'

        # Add network error
        local network_error=$(create_error_report \
            "error-1" \
            "$workflow_run_id" \
            "Setup Flutter" \
            "network" \
            "Connection timeout while downloading Flutter SDK" \
            "curl: (28) Connection timed out after 300 seconds" \
            "Retry the operation. Check network connectivity and external service status." \
            "2" \
            "true")

        errors=$(echo "$errors" | jq --argjson error "$network_error" '. + [$error]')

        echo "$errors"
    else
        echo "[]"
    fi
}

# Export functions for use in other scripts
export -f create_error_report
export -f classify_error
export -f validate_error_report
export -f get_errors_for_run