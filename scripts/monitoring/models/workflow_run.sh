#!/bin/bash
# WorkflowRun model - represents a single execution instance of a GitHub Actions workflow
set -euo pipefail

# WorkflowRun data structure and operations
# Based on data-model.md specification

# Create a WorkflowRun record
create_workflow_run() {
    local id="$1"
    local workflow_name="$2"
    local branch="$3"
    local commit_sha="$4"
    local status="$5"
    local started_at="$6"
    local trigger_event="$7"
    local actor="$8"

    # Validate required fields
    [[ -n "$id" ]] || { echo "Error: id is required"; return 1; }
    [[ -n "$workflow_name" ]] || { echo "Error: workflow_name is required"; return 1; }
    [[ -n "$status" ]] || { echo "Error: status is required"; return 1; }

    # Validate status enum
    case "$status" in
        pending|in_progress|success|failure|cancelled)
            ;;
        *)
            echo "Error: Invalid status '$status'. Must be one of: pending, in_progress, success, failure, cancelled"
            return 1
            ;;
    esac

    # Create JSON record
    local workflow_run=$(cat <<EOF
{
    "id": "$id",
    "workflow_name": "$workflow_name",
    "branch": "$branch",
    "commit_sha": "$commit_sha",
    "status": "$status",
    "started_at": "$started_at",
    "completed_at": null,
    "duration_seconds": null,
    "trigger_event": "$trigger_event",
    "actor": "$actor"
}
EOF
)

    echo "$workflow_run"
}

# Update WorkflowRun status
update_workflow_run_status() {
    local workflow_run_json="$1"
    local new_status="$2"
    local completed_at="$3"

    # Validate status transition
    case "$new_status" in
        pending|in_progress|success|failure|cancelled)
            ;;
        *)
            echo "Error: Invalid status '$new_status'"
            return 1
            ;;
    esac

    # Calculate duration if completed
    local duration_seconds="null"
    if [[ "$new_status" =~ ^(success|failure|cancelled)$ ]] && [[ -n "$completed_at" ]]; then
        local started_at=$(echo "$workflow_run_json" | jq -r '.started_at')
        if [[ "$started_at" != "null" ]]; then
            # In a real implementation, calculate duration from timestamps
            duration_seconds="300"  # Mock 5-minute duration
        fi
    fi

    # Update the record
    echo "$workflow_run_json" | jq --arg status "$new_status" \
                                   --arg completed_at "$completed_at" \
                                   --arg duration "$duration_seconds" \
                                   '.status = $status | .completed_at = $completed_at | .duration_seconds = ($duration | tonumber)'
}

# Validate WorkflowRun data
validate_workflow_run() {
    local workflow_run_json="$1"

    # Check required fields
    local id=$(echo "$workflow_run_json" | jq -r '.id')
    local status=$(echo "$workflow_run_json" | jq -r '.status')
    local workflow_name=$(echo "$workflow_run_json" | jq -r '.workflow_name')

    [[ "$id" != "null" && -n "$id" ]] || { echo "Validation failed: id is required"; return 1; }
    [[ "$status" != "null" && -n "$status" ]] || { echo "Validation failed: status is required"; return 1; }
    [[ "$workflow_name" != "null" && -n "$workflow_name" ]] || { echo "Validation failed: workflow_name is required"; return 1; }

    # Validate status enum
    case "$status" in
        pending|in_progress|success|failure|cancelled)
            ;;
        *)
            echo "Validation failed: Invalid status '$status'"
            return 1
            ;;
    esac

    # Validate duration is positive if set
    local duration=$(echo "$workflow_run_json" | jq -r '.duration_seconds')
    if [[ "$duration" != "null" && "$duration" -le 0 ]]; then
        echo "Validation failed: duration_seconds must be positive"
        return 1
    fi

    echo "Validation passed"
}

# Get WorkflowRun by ID (mock implementation)
get_workflow_run() {
    local id="$1"

    # Mock response - in real implementation, this would query GitHub API
    if [[ "$id" == "test-run-123" ]]; then
        create_workflow_run "$id" "build-macos-app" "master" "abc123" "success" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "push" "developer"
    else
        echo "null"
    fi
}

# Export functions for use in other scripts
export -f create_workflow_run
export -f update_workflow_run_status
export -f validate_workflow_run
export -f get_workflow_run