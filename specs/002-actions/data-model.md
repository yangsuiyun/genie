# Data Model: GitHub Actions Pipeline Reliability

## Core Entities

### WorkflowRun
**Description**: Represents a single execution instance of a GitHub Actions workflow

**Fields**:
- `id`: Unique identifier for the workflow run
- `workflow_name`: Name of the workflow (e.g., "Build macOS App")
- `branch`: Git branch that triggered the run
- `commit_sha`: Git commit hash
- `status`: Execution status (pending, in_progress, success, failure, cancelled)
- `started_at`: Timestamp when execution began
- `completed_at`: Timestamp when execution finished (null if running)
- `duration_seconds`: Total execution time
- `trigger_event`: Event that triggered the run (push, pull_request, workflow_dispatch)
- `actor`: User who triggered the run

**Validation Rules**:
- Status must be one of: pending, in_progress, success, failure, cancelled
- Duration must be positive if completed
- Completed_at must be after started_at

**State Transitions**:
- pending → in_progress → [success|failure|cancelled]
- Only completed runs can have duration calculated

### BuildArtifact
**Description**: Generated files or outputs from workflow execution

**Fields**:
- `id`: Unique identifier for the artifact
- `workflow_run_id`: Reference to parent workflow run
- `name`: Artifact name (e.g., "macos-app-abc123")
- `type`: Artifact type (app, dmg, logs, test_results)
- `size_bytes`: File size in bytes
- `download_url`: GitHub API URL for download
- `expires_at`: When the artifact will be automatically deleted
- `created_at`: When the artifact was created

**Validation Rules**:
- Size must be positive
- Type must be one of: app, dmg, logs, test_results
- Expires_at must be in the future

### ErrorReport
**Description**: Detailed diagnostic information about workflow failures

**Fields**:
- `id`: Unique identifier for the error report
- `workflow_run_id`: Reference to failed workflow run
- `step_name`: Name of the failed step
- `error_type`: Classification of error (network, build, dependency, timeout)
- `error_message`: Human-readable error description
- `error_details`: Technical details and stack trace
- `suggested_resolution`: Recommended fix for the error
- `retry_count`: Number of automatic retry attempts
- `is_transient`: Whether the error is likely temporary
- `created_at`: When the error occurred

**Validation Rules**:
- Error_type must be one of: network, build, dependency, timeout, configuration
- Retry_count must be non-negative
- Is_transient must be boolean

### PerformanceMetrics
**Description**: Execution times, success rates, and resource usage data

**Fields**:
- `id`: Unique identifier for the metrics record
- `workflow_name`: Name of the workflow being measured
- `date`: Date of measurement (daily aggregation)
- `total_runs`: Number of workflow executions
- `successful_runs`: Number of successful executions
- `failed_runs`: Number of failed executions
- `avg_duration_seconds`: Average execution time
- `p95_duration_seconds`: 95th percentile execution time
- `success_rate_percent`: Percentage of successful runs
- `most_common_error`: Most frequent error type

**Validation Rules**:
- All run counts must be non-negative
- Successful_runs + failed_runs must equal total_runs
- Success_rate_percent must be between 0 and 100
- Duration metrics must be positive

## Relationships

### WorkflowRun → BuildArtifact
- **Type**: One-to-Many
- **Description**: A workflow run can generate multiple artifacts
- **Constraints**: Artifacts cannot exist without a parent workflow run

### WorkflowRun → ErrorReport
- **Type**: One-to-Many
- **Description**: A workflow run can have multiple error reports (one per failed step)
- **Constraints**: Error reports only exist for failed workflow runs

### WorkflowRun → PerformanceMetrics
- **Type**: Many-to-One (aggregated)
- **Description**: Multiple workflow runs contribute to daily performance metrics
- **Constraints**: Metrics are calculated from completed workflow runs only

## State Diagram

```
[Triggered] → [Queued] → [Running] → [Success]
                           ↓
                      [Failed] → [Retrying] → [Running]
                           ↓
                      [Cancelled]
```

## Data Sources

- **GitHub Actions API**: Primary source for workflow runs, artifacts, and status
- **Workflow Logs**: Source for error details and performance data
- **GitHub Webhooks**: Real-time notifications for status changes
- **Runner Metrics**: Resource usage and performance data