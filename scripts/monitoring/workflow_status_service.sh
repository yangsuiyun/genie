#!/bin/bash
# WorkflowStatusService - service for monitoring workflow status and providing status information
set -euo pipefail

# Source the required models
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/models/workflow_run.sh"
source "$SCRIPT_DIR/models/build_artifact.sh"

# Get current workflow status
get_workflow_status() {
    local workflow_name="$1"

    echo "🔍 Getting status for workflow: $workflow_name"

    # Use GitHub CLI to get recent workflow runs
    if command -v gh &> /dev/null; then
        # Get the most recent run for this workflow
        local recent_runs=$(gh run list --workflow="$workflow_name" --limit=5 --json status,conclusion,createdAt,databaseId,headSha,headBranch || echo "[]")

        if [[ "$recent_runs" == "[]" || "$recent_runs" == "" ]]; then
            echo "⚠️  No recent runs found for workflow: $workflow_name"
            return 1
        fi

        # Get the latest run
        local latest_run=$(echo "$recent_runs" | jq '.[0]')
        local run_id=$(echo "$latest_run" | jq -r '.databaseId')
        local status=$(echo "$latest_run" | jq -r '.status')
        local conclusion=$(echo "$latest_run" | jq -r '.conclusion')
        local created_at=$(echo "$latest_run" | jq -r '.createdAt')
        local commit_sha=$(echo "$latest_run" | jq -r '.headSha')
        local branch=$(echo "$latest_run" | jq -r '.headBranch')

        # Map GitHub status to our status enum
        local mapped_status="pending"
        case "$status" in
            "completed")
                case "$conclusion" in
                    "success") mapped_status="success" ;;
                    "failure") mapped_status="failure" ;;
                    "cancelled") mapped_status="cancelled" ;;
                    *) mapped_status="failure" ;;
                esac
                ;;
            "in_progress") mapped_status="in_progress" ;;
            "queued") mapped_status="pending" ;;
            *) mapped_status="pending" ;;
        esac

        # Calculate success rate from recent runs
        local total_completed=$(echo "$recent_runs" | jq '[.[] | select(.status == "completed")] | length')
        local successful_completed=$(echo "$recent_runs" | jq '[.[] | select(.status == "completed" and .conclusion == "success")] | length')
        local success_rate=0
        if [[ "$total_completed" -gt 0 ]]; then
            success_rate=$(echo "scale=2; $successful_completed * 100 / $total_completed" | bc)
        fi

        # Create WorkflowRun record for the latest run
        local workflow_run=$(create_workflow_run \
            "$run_id" \
            "$workflow_name" \
            "$branch" \
            "$commit_sha" \
            "$mapped_status" \
            "$created_at" \
            "push" \
            "unknown")

        # Create workflow status response
        local workflow_status=$(cat <<EOF
{
    "name": "$workflow_name",
    "status": "$mapped_status",
    "last_run": $workflow_run,
    "success_rate": $success_rate
}
EOF
)

        echo "$workflow_status"
    else
        echo "❌ GitHub CLI not available"
        return 1
    fi
}

# Check if workflow exists
workflow_exists() {
    local workflow_name="$1"

    if command -v gh &> /dev/null; then
        gh workflow list --json name | jq -e --arg name "$workflow_name" '.[] | select(.name == $name)' > /dev/null
    else
        # Fallback: check if workflow file exists
        find .github/workflows -name "*.yml" -o -name "*.yaml" | xargs grep -l "name:.*$workflow_name" > /dev/null 2>&1
    fi
}

# Get workflow status with error handling
get_workflow_status_safe() {
    local workflow_name="$1"

    # Check if workflow exists
    if ! workflow_exists "$workflow_name"; then
        echo "❌ Workflow '$workflow_name' not found"
        return 404
    fi

    # Get status
    local status_result
    if status_result=$(get_workflow_status "$workflow_name"); then
        echo "$status_result"
        return 0
    else
        echo "❌ Failed to get status for workflow: $workflow_name"
        return 500
    fi
}

# Monitor workflow status changes
monitor_workflow_status() {
    local workflow_name="$1"
    local interval_seconds="${2:-60}"

    echo "🔄 Monitoring workflow status for: $workflow_name (every ${interval_seconds}s)"
    echo "Press Ctrl+C to stop monitoring"

    local previous_status=""
    while true; do
        local current_status_json
        if current_status_json=$(get_workflow_status_safe "$workflow_name"); then
            local current_status=$(echo "$current_status_json" | jq -r '.status')

            if [[ "$current_status" != "$previous_status" ]]; then
                echo "$(date): Status changed to: $current_status"
                previous_status="$current_status"
            fi
        else
            echo "$(date): Failed to get workflow status"
        fi

        sleep "$interval_seconds"
    done
}

# List all available workflows
list_workflows() {
    echo "📋 Available workflows:"

    if command -v gh &> /dev/null; then
        gh workflow list --json name,state | jq -r '.[] | "- \(.name) (\(.state))"'
    else
        # Fallback: parse workflow files
        find .github/workflows -name "*.yml" -o -name "*.yaml" | while read -r file; do
            local name=$(grep -m1 "^name:" "$file" | sed 's/name: *//' | tr -d '"'"'"'')
            echo "- $name (file: $(basename "$file"))"
        done
    fi
}

# Export functions for use in other scripts
export -f get_workflow_status
export -f workflow_exists
export -f get_workflow_status_safe
export -f monitor_workflow_status
export -f list_workflows

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "status")
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 status <workflow_name>"
                exit 1
            fi
            get_workflow_status_safe "$2"
            ;;
        "monitor")
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 monitor <workflow_name> [interval_seconds]"
                exit 1
            fi
            monitor_workflow_status "$2" "${3:-60}"
            ;;
        "list")
            list_workflows
            ;;
        *)
            echo "Usage: $0 {status|monitor|list} [args...]"
            echo "Commands:"
            echo "  status <workflow_name>                 - Get current workflow status"
            echo "  monitor <workflow_name> [interval]     - Monitor workflow status changes"
            echo "  list                                   - List all available workflows"
            exit 1
            ;;
    esac
fi