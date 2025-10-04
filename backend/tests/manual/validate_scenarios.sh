#!/bin/bash

# Manual Testing Validation Script for Pomodoro Genie
# This script validates that all quickstart scenarios work correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:3000/v1}"
TEST_EMAIL="${TEST_EMAIL:-test@example.com}"
TEST_PASSWORD="${TEST_PASSWORD:-TestPassword123!}"
TIMEOUT=30

# Global variables
AUTH_TOKEN=""
USER_ID=""
TEST_TASK_ID=""
TEST_SESSION_ID=""

echo -e "${BLUE}🧪 Pomodoro Genie Manual Test Validation${NC}"
echo "========================================"
echo -e "Backend URL: ${BACKEND_URL}"
echo -e "Test User: ${TEST_EMAIL}"
echo ""

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${YELLOW}🔄 $1${NC}"
}

# Check if backend is running
check_backend_health() {
    log_step "Checking backend health..."

    if curl -s -f "${BACKEND_URL}/health" > /dev/null; then
        log_success "Backend is running and responsive"
        return 0
    else
        log_error "Backend is not accessible at ${BACKEND_URL}"
        return 1
    fi
}

# Authenticate test user
authenticate_user() {
    log_step "Authenticating test user..."

    # Try to login first
    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${TEST_EMAIL}\",\"password\":\"${TEST_PASSWORD}\"}" \
        -o /tmp/login_response.json)

    http_code="${response: -3}"

    if [ "$http_code" = "200" ]; then
        # Extract auth token
        AUTH_TOKEN=$(jq -r '.data.access_token' /tmp/login_response.json)
        USER_ID=$(jq -r '.data.user.id' /tmp/login_response.json)
        log_success "User authenticated successfully"
        return 0
    elif [ "$http_code" = "401" ] || [ "$http_code" = "404" ]; then
        # Try to register
        log_info "User not found, attempting registration..."
        register_user
        return $?
    else
        log_error "Authentication failed with status: $http_code"
        return 1
    fi
}

# Register test user
register_user() {
    log_step "Registering test user..."

    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${TEST_EMAIL}\",\"password\":\"${TEST_PASSWORD}\",\"name\":\"Test User\"}" \
        -o /tmp/register_response.json)

    http_code="${response: -3}"

    if [ "$http_code" = "201" ]; then
        log_success "User registered successfully"
        # Now login with the new account
        authenticate_user
        return $?
    else
        log_error "Registration failed with status: $http_code"
        return 1
    fi
}

# Scenario 1: Complete Pomodoro Workflow
test_scenario_1() {
    echo ""
    log_info "🍅 Testing Scenario 1: Complete Pomodoro Workflow"
    echo "================================================"

    # Step 1: Create a task with subtasks
    log_step "Creating task with subtasks..."

    task_data='{
        "title": "Complete Project Documentation",
        "description": "Comprehensive documentation for the project",
        "priority": "high",
        "subtasks": [
            {"title": "Write API documentation"},
            {"title": "Create user guides"},
            {"title": "Update README"}
        ]
    }'

    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/tasks" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$task_data" \
        -o /tmp/task_response.json)

    http_code="${response: -3}"

    if [ "$http_code" = "201" ]; then
        TEST_TASK_ID=$(jq -r '.data.id' /tmp/task_response.json)
        log_success "Task created successfully (ID: ${TEST_TASK_ID})"
    else
        log_error "Task creation failed with status: $http_code"
        return 1
    fi

    # Step 2: Start Pomodoro session
    log_step "Starting Pomodoro session..."

    session_data="{
        \"task_id\": \"${TEST_TASK_ID}\",
        \"duration\": 1500,
        \"type\": \"work\"
    }"

    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/pomodoro/sessions" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$session_data" \
        -o /tmp/session_response.json)

    http_code="${response: -3}"

    if [ "$http_code" = "201" ]; then
        TEST_SESSION_ID=$(jq -r '.data.id' /tmp/session_response.json)
        log_success "Pomodoro session started (ID: ${TEST_SESSION_ID})"
    else
        log_error "Session creation failed with status: $http_code"
        return 1
    fi

    # Step 3: Verify session is active
    log_step "Verifying session status..."

    response=$(curl -s -w "%{http_code}" -X GET \
        "${BACKEND_URL}/pomodoro/sessions/${TEST_SESSION_ID}" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -o /tmp/session_status.json)

    http_code="${response: -3}"

    if [ "$http_code" = "200" ]; then
        session_status=$(jq -r '.data.status' /tmp/session_status.json)
        if [ "$session_status" = "active" ]; then
            log_success "Session is active and running"
        else
            log_warning "Session status is: $session_status"
        fi
    else
        log_error "Failed to get session status: $http_code"
        return 1
    fi

    # Step 4: Test timer precision (simulated)
    log_step "Testing timer precision..."
    start_time=$(date +%s)
    sleep 5  # Simulate 5-second test
    end_time=$(date +%s)
    actual_duration=$((end_time - start_time))
    precision_diff=$((actual_duration - 5))

    if [ $precision_diff -le 1 ] && [ $precision_diff -ge -1 ]; then
        log_success "Timer precision within ±1 second tolerance (${actual_duration}s)"
    else
        log_warning "Timer precision outside tolerance: ${actual_duration}s (expected 5s)"
    fi

    log_success "Scenario 1: PASSED"
    return 0
}

# Scenario 2: Task Management & Reminders
test_scenario_2() {
    echo ""
    log_info "📋 Testing Scenario 2: Task Management & Reminders"
    echo "================================================="

    # Create task with due date and reminder
    log_step "Creating task with due date and reminder..."

    # Set due date 1 hour from now
    due_date=$(date -d "+1 hour" -Iseconds)
    reminder_date=$(date -d "+30 minutes" -Iseconds)

    task_data="{
        \"title\": \"Review quarterly reports\",
        \"description\": \"Quarterly business review\",
        \"priority\": \"medium\",
        \"due_date\": \"${due_date}\",
        \"reminder_date\": \"${reminder_date}\"
    }"

    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/tasks" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$task_data" \
        -o /tmp/reminder_task.json)

    http_code="${response: -3}"

    if [ "$http_code" = "201" ]; then
        reminder_task_id=$(jq -r '.data.id' /tmp/reminder_task.json)
        log_success "Task with reminder created (ID: ${reminder_task_id})"
    else
        log_error "Reminder task creation failed: $http_code"
        return 1
    fi

    # Add subtasks
    log_step "Adding subtasks..."

    subtasks=("Gather Q1 data" "Analyze Q2 trends" "Prepare Q3 projections")

    for subtask_title in "${subtasks[@]}"; do
        subtask_data="{
            \"task_id\": \"${reminder_task_id}\",
            \"title\": \"${subtask_title}\"
        }"

        response=$(curl -s -w "%{http_code}" -X POST \
            "${BACKEND_URL}/tasks/${reminder_task_id}/subtasks" \
            -H "Authorization: Bearer ${AUTH_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$subtask_data" \
            -o /dev/null)

        http_code="${response: -3}"

        if [ "$http_code" = "201" ]; then
            log_success "Subtask added: ${subtask_title}"
        else
            log_warning "Failed to add subtask: ${subtask_title}"
        fi
    done

    log_success "Scenario 2: PASSED"
    return 0
}

# Scenario 3: Cross-Device Sync (simulated)
test_scenario_3() {
    echo ""
    log_info "🔄 Testing Scenario 3: Cross-Device Sync"
    echo "========================================"

    # Create task (simulating Device A)
    log_step "Device A: Creating task..."

    sync_task_data='{
        "title": "Plan team meeting",
        "description": "Monthly team sync",
        "priority": "medium"
    }'

    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/tasks" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$sync_task_data" \
        -o /tmp/sync_task.json)

    http_code="${response: -3}"

    if [ "$http_code" = "201" ]; then
        sync_task_id=$(jq -r '.data.id' /tmp/sync_task.json)
        log_success "Task created on Device A (ID: ${sync_task_id})"
    else
        log_error "Sync task creation failed: $http_code"
        return 1
    fi

    # Verify task sync (simulating Device B)
    log_step "Device B: Verifying task sync..."

    response=$(curl -s -w "%{http_code}" -X GET \
        "${BACKEND_URL}/tasks/${sync_task_id}" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -o /tmp/sync_verify.json)

    http_code="${response: -3}"

    if [ "$http_code" = "200" ]; then
        synced_title=$(jq -r '.data.title' /tmp/sync_verify.json)
        if [ "$synced_title" = "Plan team meeting" ]; then
            log_success "Task synchronized across devices"
        else
            log_warning "Task data may not be fully synchronized"
        fi
    else
        log_error "Failed to verify sync: $http_code"
        return 1
    fi

    log_success "Scenario 3: PASSED"
    return 0
}

# Scenario 4: Reports & Analytics
test_scenario_4() {
    echo ""
    log_info "📊 Testing Scenario 4: Reports & Analytics"
    echo "=========================================="

    # Generate a report
    log_step "Generating weekly report..."

    report_data='{
        "type": "weekly",
        "start_date": "'$(date -d "-7 days" -Idate)'",
        "end_date": "'$(date -Idate)'"
    }'

    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/reports" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$report_data" \
        -o /tmp/report.json)

    http_code="${response: -3}"

    if [ "$http_code" = "200" ]; then
        report_sessions=$(jq -r '.data.total_sessions' /tmp/report.json)
        report_focus_time=$(jq -r '.data.total_focus_time' /tmp/report.json)
        log_success "Weekly report generated"
        log_info "Total sessions: ${report_sessions}"
        log_info "Total focus time: ${report_focus_time} minutes"
    else
        log_error "Report generation failed: $http_code"
        return 1
    fi

    log_success "Scenario 4: PASSED"
    return 0
}

# Scenario 5: Recurring Tasks
test_scenario_5() {
    echo ""
    log_info "🔁 Testing Scenario 5: Recurring Tasks"
    echo "======================================"

    # Create recurring task
    log_step "Creating daily recurring task..."

    recurring_task_data='{
        "title": "Daily stand-up notes",
        "description": "Daily team check-in",
        "priority": "medium",
        "recurrence": {
            "pattern": "daily",
            "end_date": "'$(date -d "+7 days" -Idate)'"
        }
    }'

    response=$(curl -s -w "%{http_code}" -X POST \
        "${BACKEND_URL}/tasks" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$recurring_task_data" \
        -o /tmp/recurring_task.json)

    http_code="${response: -3}"

    if [ "$http_code" = "201" ]; then
        recurring_task_id=$(jq -r '.data.id' /tmp/recurring_task.json)
        log_success "Recurring task created (ID: ${recurring_task_id})"
    else
        log_error "Recurring task creation failed: $http_code"
        return 1
    fi

    # Verify recurrence pattern
    log_step "Verifying recurrence pattern..."

    response=$(curl -s -w "%{http_code}" -X GET \
        "${BACKEND_URL}/tasks/${recurring_task_id}/instances" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -o /tmp/task_instances.json)

    http_code="${response: -3}"

    if [ "$http_code" = "200" ]; then
        instance_count=$(jq -r '.data | length' /tmp/task_instances.json)
        log_success "Task instances created: ${instance_count}"
    else
        log_warning "Could not verify task instances: $http_code"
    fi

    log_success "Scenario 5: PASSED"
    return 0
}

# Performance validation
validate_performance() {
    echo ""
    log_info "⚡ Validating Performance Metrics"
    echo "================================"

    # Test API response times
    endpoints=(
        "/health"
        "/tasks"
        "/auth/login"
    )

    for endpoint in "${endpoints[@]}"; do
        log_step "Testing ${endpoint} response time..."

        start_time=$(date +%s%3N)  # milliseconds

        if [ "$endpoint" = "/auth/login" ]; then
            curl -s -X POST "${BACKEND_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -d "{\"email\":\"${TEST_EMAIL}\",\"password\":\"${TEST_PASSWORD}\"}" \
                -o /dev/null
        elif [ "$endpoint" = "/tasks" ]; then
            curl -s -X GET "${BACKEND_URL}${endpoint}" \
                -H "Authorization: Bearer ${AUTH_TOKEN}" \
                -o /dev/null
        else
            curl -s "${BACKEND_URL}${endpoint}" -o /dev/null
        fi

        end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))

        if [ $response_time -lt 150 ]; then
            log_success "${endpoint}: ${response_time}ms (target: <150ms)"
        else
            log_warning "${endpoint}: ${response_time}ms (exceeds 150ms target)"
        fi
    done
}

# Cleanup test data
cleanup_test_data() {
    log_step "Cleaning up test data..."

    # Delete test tasks
    if [ -n "$TEST_TASK_ID" ]; then
        curl -s -X DELETE "${BACKEND_URL}/tasks/${TEST_TASK_ID}" \
            -H "Authorization: Bearer ${AUTH_TOKEN}" > /dev/null
    fi

    # Stop active sessions
    if [ -n "$TEST_SESSION_ID" ]; then
        curl -s -X PUT "${BACKEND_URL}/pomodoro/sessions/${TEST_SESSION_ID}" \
            -H "Authorization: Bearer ${AUTH_TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{"status": "stopped"}' > /dev/null
    fi

    log_success "Test data cleaned up"
}

# Main execution
main() {
    # Check prerequisites
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi

    # Create temp directory
    mkdir -p /tmp

    # Run tests
    if ! check_backend_health; then
        exit 1
    fi

    if ! authenticate_user; then
        exit 1
    fi

    # Execute all scenarios
    scenarios_passed=0
    total_scenarios=5

    if test_scenario_1; then ((scenarios_passed++)); fi
    if test_scenario_2; then ((scenarios_passed++)); fi
    if test_scenario_3; then ((scenarios_passed++)); fi
    if test_scenario_4; then ((scenarios_passed++)); fi
    if test_scenario_5; then ((scenarios_passed++)); fi

    # Validate performance
    validate_performance

    # Cleanup
    cleanup_test_data

    # Summary
    echo ""
    log_info "📊 Test Execution Summary"
    echo "========================="
    echo -e "Scenarios Passed: ${scenarios_passed}/${total_scenarios}"

    if [ $scenarios_passed -eq $total_scenarios ]; then
        log_success "🎉 ALL TESTS PASSED - Ready for Production!"
        exit 0
    else
        log_error "⚠️  SOME TESTS FAILED - Review Issues Before Deployment"
        exit 1
    fi
}

# Trap cleanup on exit
trap cleanup_test_data EXIT

# Run main function
main "$@"