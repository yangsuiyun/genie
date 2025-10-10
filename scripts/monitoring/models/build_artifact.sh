#!/bin/bash
# BuildArtifact model - represents generated files or outputs from workflow execution
set -euo pipefail

# BuildArtifact data structure and operations
# Based on data-model.md specification

# Create a BuildArtifact record
create_build_artifact() {
    local id="$1"
    local workflow_run_id="$2"
    local name="$3"
    local type="$4"
    local size_bytes="$5"
    local download_url="$6"
    local expires_at="$7"
    local created_at="$8"

    # Validate required fields
    [[ -n "$id" ]] || { echo "Error: id is required"; return 1; }
    [[ -n "$workflow_run_id" ]] || { echo "Error: workflow_run_id is required"; return 1; }
    [[ -n "$name" ]] || { echo "Error: name is required"; return 1; }
    [[ -n "$type" ]] || { echo "Error: type is required"; return 1; }

    # Validate type enum
    case "$type" in
        app|dmg|logs|test_results)
            ;;
        *)
            echo "Error: Invalid type '$type'. Must be one of: app, dmg, logs, test_results"
            return 1
            ;;
    esac

    # Validate size is positive
    if [[ -n "$size_bytes" && "$size_bytes" -le 0 ]]; then
        echo "Error: size_bytes must be positive"
        return 1
    fi

    # Create JSON record
    local build_artifact=$(cat <<EOF
{
    "id": "$id",
    "workflow_run_id": "$workflow_run_id",
    "name": "$name",
    "type": "$type",
    "size_bytes": $size_bytes,
    "download_url": "$download_url",
    "expires_at": "$expires_at",
    "created_at": "$created_at"
}
EOF
)

    echo "$build_artifact"
}

# Validate BuildArtifact data
validate_build_artifact() {
    local artifact_json="$1"

    # Check required fields
    local id=$(echo "$artifact_json" | jq -r '.id')
    local workflow_run_id=$(echo "$artifact_json" | jq -r '.workflow_run_id')
    local name=$(echo "$artifact_json" | jq -r '.name')
    local type=$(echo "$artifact_json" | jq -r '.type')

    [[ "$id" != "null" && -n "$id" ]] || { echo "Validation failed: id is required"; return 1; }
    [[ "$workflow_run_id" != "null" && -n "$workflow_run_id" ]] || { echo "Validation failed: workflow_run_id is required"; return 1; }
    [[ "$name" != "null" && -n "$name" ]] || { echo "Validation failed: name is required"; return 1; }
    [[ "$type" != "null" && -n "$type" ]] || { echo "Validation failed: type is required"; return 1; }

    # Validate type enum
    case "$type" in
        app|dmg|logs|test_results)
            ;;
        *)
            echo "Validation failed: Invalid type '$type'"
            return 1
            ;;
    esac

    # Validate size is positive if set
    local size_bytes=$(echo "$artifact_json" | jq -r '.size_bytes')
    if [[ "$size_bytes" != "null" && "$size_bytes" -le 0 ]]; then
        echo "Validation failed: size_bytes must be positive"
        return 1
    fi

    echo "Validation passed"
}

# Get artifacts for a workflow run (mock implementation)
get_artifacts_for_run() {
    local workflow_run_id="$1"

    # Mock response - in real implementation, this would query GitHub API
    if [[ "$workflow_run_id" == "test-run-123" ]]; then
        local artifacts='[]'

        # Add macOS app artifact
        local app_artifact=$(create_build_artifact \
            "artifact-1" \
            "$workflow_run_id" \
            "PomodoroGenie.app" \
            "app" \
            "52428800" \
            "https://api.github.com/repos/owner/repo/actions/artifacts/1/zip" \
            "$(date -u -d '+30 days' +%Y-%m-%dT%H:%M:%SZ)" \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)")

        artifacts=$(echo "$artifacts" | jq --argjson artifact "$app_artifact" '. + [$artifact]')

        # Add DMG artifact
        local dmg_artifact=$(create_build_artifact \
            "artifact-2" \
            "$workflow_run_id" \
            "PomodoroGenie-macos.dmg" \
            "dmg" \
            "62914560" \
            "https://api.github.com/repos/owner/repo/actions/artifacts/2/zip" \
            "$(date -u -d '+30 days' +%Y-%m-%dT%H:%M:%SZ)" \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)")

        artifacts=$(echo "$artifacts" | jq --argjson artifact "$dmg_artifact" '. + [$artifact]')

        echo "$artifacts"
    else
        echo "[]"
    fi
}

# Check artifact accessibility
check_artifact_accessibility() {
    local download_url="$1"

    # Mock check - in real implementation, this would test the download URL
    if [[ "$download_url" =~ ^https://api\.github\.com/repos/.*/actions/artifacts/.*/zip$ ]]; then
        echo "accessible"
    else
        echo "inaccessible"
    fi
}

# Export functions for use in other scripts
export -f create_build_artifact
export -f validate_build_artifact
export -f get_artifacts_for_run
export -f check_artifact_accessibility