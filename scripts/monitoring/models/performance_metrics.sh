#!/bin/bash
# PerformanceMetrics model - execution times, success rates, and resource usage data
set -euo pipefail

# PerformanceMetrics data structure and operations
# Based on data-model.md specification

# Create a PerformanceMetrics record
create_performance_metrics() {
    local id="$1"
    local workflow_name="$2"
    local date="$3"
    local total_runs="$4"
    local successful_runs="$5"
    local failed_runs="$6"
    local avg_duration_seconds="$7"
    local p95_duration_seconds="$8"
    local most_common_error="${9:-}"

    # Validate required fields
    [[ -n "$id" ]] || { echo "Error: id is required"; return 1; }
    [[ -n "$workflow_name" ]] || { echo "Error: workflow_name is required"; return 1; }
    [[ -n "$date" ]] || { echo "Error: date is required"; return 1; }

    # Validate counts are non-negative
    [[ "$total_runs" -ge 0 ]] || { echo "Error: total_runs must be non-negative"; return 1; }
    [[ "$successful_runs" -ge 0 ]] || { echo "Error: successful_runs must be non-negative"; return 1; }
    [[ "$failed_runs" -ge 0 ]] || { echo "Error: failed_runs must be non-negative"; return 1; }

    # Validate successful_runs + failed_runs = total_runs
    local sum_runs=$((successful_runs + failed_runs))
    if [[ "$sum_runs" -ne "$total_runs" ]]; then
        echo "Error: successful_runs + failed_runs must equal total_runs"
        return 1
    fi

    # Calculate success rate
    local success_rate_percent=0
    if [[ "$total_runs" -gt 0 ]]; then
        success_rate_percent=$(echo "scale=2; $successful_runs * 100 / $total_runs" | bc)
    fi

    # Validate duration metrics are positive
    if [[ -n "$avg_duration_seconds" ]] && (( $(echo "$avg_duration_seconds <= 0" | bc -l) )); then
        echo "Error: avg_duration_seconds must be positive"
        return 1
    fi

    if [[ -n "$p95_duration_seconds" ]] && (( $(echo "$p95_duration_seconds <= 0" | bc -l) )); then
        echo "Error: p95_duration_seconds must be positive"
        return 1
    fi

    # Create JSON record
    local performance_metrics=$(cat <<EOF
{
    "id": "$id",
    "workflow_name": "$workflow_name",
    "date": "$date",
    "total_runs": $total_runs,
    "successful_runs": $successful_runs,
    "failed_runs": $failed_runs,
    "avg_duration_seconds": $avg_duration_seconds,
    "p95_duration_seconds": $p95_duration_seconds,
    "success_rate_percent": $success_rate_percent,
    "most_common_error": "$most_common_error"
}
EOF
)

    echo "$performance_metrics"
}

# Calculate metrics from workflow runs
calculate_metrics() {
    local workflow_name="$1"
    local date="$2"
    local runs_json="$3"  # Array of workflow runs

    local total_runs=$(echo "$runs_json" | jq 'length')
    local successful_runs=$(echo "$runs_json" | jq '[.[] | select(.status == "success")] | length')
    local failed_runs=$(echo "$runs_json" | jq '[.[] | select(.status == "failure")] | length')

    # Calculate average duration
    local avg_duration_seconds=0
    if [[ "$total_runs" -gt 0 ]]; then
        local total_duration=$(echo "$runs_json" | jq '[.[] | select(.duration_seconds != null) | .duration_seconds] | add // 0')
        local count_with_duration=$(echo "$runs_json" | jq '[.[] | select(.duration_seconds != null)] | length')
        if [[ "$count_with_duration" -gt 0 ]]; then
            avg_duration_seconds=$(echo "scale=2; $total_duration / $count_with_duration" | bc)
        fi
    fi

    # Calculate P95 duration (simplified - would need proper percentile calculation)
    local p95_duration_seconds=0
    if [[ "$total_runs" -gt 0 ]]; then
        p95_duration_seconds=$(echo "$runs_json" | jq '[.[] | select(.duration_seconds != null) | .duration_seconds] | sort | .[-1] // 0')
    fi

    # Find most common error (simplified)
    local most_common_error=""
    if [[ "$failed_runs" -gt 0 ]]; then
        most_common_error="build_failure"  # Mock - would analyze actual errors
    fi

    local metrics_id="metrics-$(date +%s)-$workflow_name"
    create_performance_metrics \
        "$metrics_id" \
        "$workflow_name" \
        "$date" \
        "$total_runs" \
        "$successful_runs" \
        "$failed_runs" \
        "$avg_duration_seconds" \
        "$p95_duration_seconds" \
        "$most_common_error"
}

# Validate PerformanceMetrics data
validate_performance_metrics() {
    local metrics_json="$1"

    # Check required fields
    local workflow_name=$(echo "$metrics_json" | jq -r '.workflow_name')
    local total_runs=$(echo "$metrics_json" | jq -r '.total_runs')
    local successful_runs=$(echo "$metrics_json" | jq -r '.successful_runs')
    local failed_runs=$(echo "$metrics_json" | jq -r '.failed_runs')
    local success_rate_percent=$(echo "$metrics_json" | jq -r '.success_rate_percent')

    [[ "$workflow_name" != "null" && -n "$workflow_name" ]] || { echo "Validation failed: workflow_name is required"; return 1; }
    [[ "$total_runs" != "null" && "$total_runs" -ge 0 ]] || { echo "Validation failed: total_runs must be non-negative"; return 1; }
    [[ "$successful_runs" != "null" && "$successful_runs" -ge 0 ]] || { echo "Validation failed: successful_runs must be non-negative"; return 1; }
    [[ "$failed_runs" != "null" && "$failed_runs" -ge 0 ]] || { echo "Validation failed: failed_runs must be non-negative"; return 1; }

    # Validate success_rate_percent is between 0 and 100
    if [[ "$success_rate_percent" != "null" ]]; then
        if (( $(echo "$success_rate_percent < 0 || $success_rate_percent > 100" | bc -l) )); then
            echo "Validation failed: success_rate_percent must be between 0 and 100"
            return 1
        fi
    fi

    echo "Validation passed"
}

# Get metrics for a workflow (mock implementation)
get_metrics_for_workflow() {
    local workflow_name="$1"
    local days="${2:-7}"

    # Mock response - in real implementation, this would aggregate from runs
    local metrics=$(create_performance_metrics \
        "metrics-$(date +%s)" \
        "$workflow_name" \
        "$(date -u +%Y-%m-%d)" \
        "10" \
        "9" \
        "1" \
        "450.5" \
        "720.0" \
        "network")

    echo "$metrics"
}

# Export functions for use in other scripts
export -f create_performance_metrics
export -f calculate_metrics
export -f validate_performance_metrics
export -f get_metrics_for_workflow