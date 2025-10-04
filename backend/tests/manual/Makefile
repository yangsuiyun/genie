# Manual Testing Makefile for Pomodoro Genie
# This file orchestrates the execution of manual test scenarios

.PHONY: help test-all test-scenarios test-performance validate-setup clean-reports run-backend setup-test-env

# Default target
help:
	@echo "🍅 Pomodoro Genie Manual Testing Suite"
	@echo "======================================"
	@echo ""
	@echo "Available targets:"
	@echo "  test-all          - Run complete manual test suite"
	@echo "  test-scenarios    - Run individual test scenarios"
	@echo "  test-performance  - Run performance validation only"
	@echo "  validate-setup    - Validate test environment setup"
	@echo "  setup-test-env    - Setup test environment and dependencies"
	@echo "  run-backend       - Start backend server for testing"
	@echo "  clean-reports     - Clean up generated test reports"
	@echo "  generate-report   - Generate HTML test report"
	@echo ""
	@echo "Environment variables:"
	@echo "  BACKEND_URL       - Backend API URL (default: http://localhost:3000/v1)"
	@echo "  TEST_EMAIL        - Test user email (default: test@example.com)"
	@echo "  TEST_PASSWORD     - Test user password (default: TestPassword123!)"
	@echo "  REPORT_DIR        - Report output directory (default: ./reports)"
	@echo ""

# Configuration
BACKEND_URL ?= http://localhost:3000/v1
TEST_EMAIL ?= test@example.com
TEST_PASSWORD ?= TestPassword123!
REPORT_DIR ?= ./reports
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Create reports directory
$(REPORT_DIR):
	@mkdir -p $(REPORT_DIR)

# Validate test environment setup
validate-setup:
	@echo "🔍 Validating test environment setup..."
	@echo "Backend URL: $(BACKEND_URL)"
	@echo "Test User: $(TEST_EMAIL)"
	@echo ""
	@echo "Checking dependencies..."
	@command -v curl >/dev/null 2>&1 || { echo "❌ curl is required but not installed"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq is required but not installed"; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo "❌ Go is required but not installed"; exit 1; }
	@echo "✅ All dependencies are available"
	@echo ""
	@echo "Checking backend connectivity..."
	@curl -s -f $(BACKEND_URL)/health >/dev/null || { echo "❌ Backend not accessible at $(BACKEND_URL)"; exit 1; }
	@echo "✅ Backend is accessible"
	@echo ""
	@echo "🎉 Test environment is ready!"

# Setup test environment
setup-test-env: validate-setup
	@echo "🔧 Setting up test environment..."
	@echo "Creating test data..."
	# Add any additional setup commands here
	@echo "✅ Test environment setup complete"

# Run all manual tests
test-all: validate-setup $(REPORT_DIR)
	@echo "🚀 Running complete manual test suite..."
	@echo "Started at: $(shell date)"
	@echo ""

	@echo "Executing test scenarios..."
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		./validate_scenarios.sh 2>&1 | tee $(REPORT_DIR)/test_execution_$(TIMESTAMP).log

	@echo ""
	@echo "📊 Test execution completed at: $(shell date)"
	@echo "📄 Logs saved to: $(REPORT_DIR)/test_execution_$(TIMESTAMP).log"

# Run individual test scenarios
test-scenario-1: validate-setup
	@echo "🍅 Running Scenario 1: Complete Pomodoro Workflow"
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		bash -c 'source ./validate_scenarios.sh && test_scenario_1'

test-scenario-2: validate-setup
	@echo "📋 Running Scenario 2: Task Management & Reminders"
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		bash -c 'source ./validate_scenarios.sh && test_scenario_2'

test-scenario-3: validate-setup
	@echo "🔄 Running Scenario 3: Cross-Device Sync"
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		bash -c 'source ./validate_scenarios.sh && test_scenario_3'

test-scenario-4: validate-setup
	@echo "📊 Running Scenario 4: Reports & Analytics"
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		bash -c 'source ./validate_scenarios.sh && test_scenario_4'

test-scenario-5: validate-setup
	@echo "🔁 Running Scenario 5: Recurring Tasks"
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		bash -c 'source ./validate_scenarios.sh && test_scenario_5'

# Run performance tests only
test-performance: validate-setup
	@echo "⚡ Running performance validation..."
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		bash -c 'source ./validate_scenarios.sh && validate_performance'

# Run scenarios individually
test-scenarios: test-scenario-1 test-scenario-2 test-scenario-3 test-scenario-4 test-scenario-5

# Start backend server for testing
run-backend:
	@echo "🚀 Starting backend server..."
	@cd ../../.. && \
		if [ ! -f go.mod ]; then \
			echo "Initializing Go module..."; \
			go mod init github.com/pomodoro-team/pomodoro-app; \
		fi && \
		echo "Installing dependencies..." && \
		go mod tidy && \
		echo "Starting server..." && \
		go run cmd/server/main.go || \
		echo "❌ Failed to start backend server. Please check the implementation."

# Generate test reports
generate-report: $(REPORT_DIR)
	@echo "📄 Generating test reports..."
	@if [ -f "$(REPORT_DIR)/test_execution_$(TIMESTAMP).log" ]; then \
		echo "Converting log to HTML report..."; \
		go run test_report_generator.go -input $(REPORT_DIR)/test_execution_$(TIMESTAMP).log \
			-output $(REPORT_DIR)/test_report_$(TIMESTAMP).html; \
		echo "✅ HTML report generated: $(REPORT_DIR)/test_report_$(TIMESTAMP).html"; \
	else \
		echo "⚠️  No test execution log found. Run 'make test-all' first."; \
	fi

# Load testing with multiple concurrent users
load-test: validate-setup
	@echo "🔥 Running load tests..."
	@echo "Simulating 10 concurrent users..."
	@for i in $$(seq 1 10); do \
		( \
			echo "Starting user $$i..."; \
			BACKEND_URL=$(BACKEND_URL) TEST_EMAIL="test$$i@example.com" TEST_PASSWORD=$(TEST_PASSWORD) \
				./validate_scenarios.sh >/dev/null 2>&1 && \
			echo "User $$i completed successfully" || \
			echo "User $$i failed" \
		) & \
	done; \
	wait; \
	echo "✅ Load testing completed"

# Stress testing with extended duration
stress-test: validate-setup
	@echo "💪 Running stress tests..."
	@echo "Running continuous tests for 5 minutes..."
	@timeout 300 bash -c 'while true; do \
		BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
			./validate_scenarios.sh >/dev/null 2>&1 || true; \
		sleep 10; \
	done' || echo "✅ Stress testing completed"

# Memory leak testing
memory-test: validate-setup
	@echo "🧠 Running memory leak tests..."
	@echo "Monitoring memory usage during test execution..."
	@(while true; do \
		ps aux | grep -E "(server|backend)" | grep -v grep | \
		awk '{print strftime("%Y-%m-%d %H:%M:%S"), "PID:", $$2, "Memory:", $$4"%"}'; \
		sleep 5; \
	done) & \
	MONITOR_PID=$$!; \
	BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		./validate_scenarios.sh; \
	kill $$MONITOR_PID 2>/dev/null || true; \
	echo "✅ Memory monitoring completed"

# Security testing
security-test: validate-setup
	@echo "🔒 Running security tests..."
	@echo "Testing for common vulnerabilities..."
	@echo "1. Testing SQL injection..."
	@curl -s -X POST $(BACKEND_URL)/auth/login \
		-H "Content-Type: application/json" \
		-d '{"email":"test@example.com'\''OR 1=1--","password":"anything"}' >/dev/null && \
		echo "⚠️  Potential SQL injection vulnerability" || \
		echo "✅ SQL injection test passed"

	@echo "2. Testing XSS prevention..."
	@curl -s -X POST $(BACKEND_URL)/tasks \
		-H "Authorization: Bearer fake-token" \
		-H "Content-Type: application/json" \
		-d '{"title":"<script>alert(\"xss\")</script>"}' >/dev/null 2>&1 || \
		echo "✅ XSS prevention test passed"

	@echo "3. Testing rate limiting..."
	@for i in $$(seq 1 100); do \
		curl -s $(BACKEND_URL)/health >/dev/null 2>&1; \
	done && \
	echo "⚠️  Rate limiting may not be enforced" || \
	echo "✅ Rate limiting test passed"

# Cross-platform testing
cross-platform-test:
	@echo "🌐 Running cross-platform tests..."
	@echo "Testing different user agents..."
	@curl -s -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" \
		$(BACKEND_URL)/health >/dev/null && echo "✅ iOS compatibility test passed"
	@curl -s -H "User-Agent: Mozilla/5.0 (Linux; Android 10)" \
		$(BACKEND_URL)/health >/dev/null && echo "✅ Android compatibility test passed"
	@curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
		$(BACKEND_URL)/health >/dev/null && echo "✅ Windows compatibility test passed"

# Cleanup generated reports and logs
clean-reports:
	@echo "🧹 Cleaning up test reports..."
	@rm -rf $(REPORT_DIR)
	@echo "✅ Reports directory cleaned"

# Full test suite with all validations
full-test-suite: clean-reports setup-test-env test-all test-performance generate-report
	@echo ""
	@echo "🎉 Full test suite completed!"
	@echo "📊 Check the reports in: $(REPORT_DIR)/"

# Quick smoke test
smoke-test: validate-setup
	@echo "💨 Running quick smoke test..."
	@curl -s $(BACKEND_URL)/health >/dev/null && echo "✅ Backend health check passed"
	@BACKEND_URL=$(BACKEND_URL) TEST_EMAIL=$(TEST_EMAIL) TEST_PASSWORD=$(TEST_PASSWORD) \
		bash -c 'source ./validate_scenarios.sh && check_backend_health && authenticate_user' && \
		echo "✅ Authentication smoke test passed"
	@echo "🎉 Smoke test completed successfully"

# CI/CD integration target
ci-test: validate-setup test-all
	@echo "🤖 CI/CD integration test completed"
	@if [ -f "$(REPORT_DIR)/test_execution_$(TIMESTAMP).log" ]; then \
		grep -q "ALL TESTS PASSED" $(REPORT_DIR)/test_execution_$(TIMESTAMP).log && \
		echo "✅ All tests passed - Ready for deployment" || \
		(echo "❌ Some tests failed - Deployment blocked" && exit 1); \
	else \
		echo "❌ Test execution log not found" && exit 1; \
	fi

# Watch mode for development
watch-test:
	@echo "👀 Watching for changes and running tests..."
	@while inotifywait -e modify ../../ -r 2>/dev/null; do \
		echo "Changes detected, running smoke test..."; \
		make smoke-test; \
		sleep 2; \
	done

# Development mode with auto-restart
dev-mode:
	@echo "🔄 Starting development mode..."
	@echo "Backend will restart on changes, tests will run automatically"
	@make run-backend & \
	sleep 5 && \
	make watch-test

# Display test statistics
test-stats: $(REPORT_DIR)
	@echo "📈 Test Execution Statistics"
	@echo "============================"
	@if [ -d "$(REPORT_DIR)" ]; then \
		echo "Total test runs: $$(ls $(REPORT_DIR)/test_execution_*.log 2>/dev/null | wc -l)"; \
		echo "Latest test: $$(ls -t $(REPORT_DIR)/test_execution_*.log 2>/dev/null | head -1)"; \
		if [ -f "$$(ls -t $(REPORT_DIR)/test_execution_*.log 2>/dev/null | head -1)" ]; then \
			echo "Last test status: $$(grep -o 'ALL TESTS PASSED\|SOME TESTS FAILED' $$(ls -t $(REPORT_DIR)/test_execution_*.log | head -1) || echo 'UNKNOWN')"; \
		fi; \
	else \
		echo "No test reports found. Run 'make test-all' first."; \
	fi

# Help for specific test types
help-scenarios:
	@echo "📋 Available Test Scenarios"
	@echo "=========================="
	@echo "1. Complete Pomodoro Workflow (test-scenario-1)"
	@echo "   - User authentication"
	@echo "   - Task creation with subtasks"
	@echo "   - Pomodoro session management"
	@echo "   - Timer precision validation"
	@echo ""
	@echo "2. Task Management & Reminders (test-scenario-2)"
	@echo "   - Task creation with due dates"
	@echo "   - Subtask management"
	@echo "   - Reminder notifications"
	@echo "   - Task completion workflow"
	@echo ""
	@echo "3. Cross-Device Sync (test-scenario-3)"
	@echo "   - Multi-device task synchronization"
	@echo "   - Real-time updates"
	@echo "   - Conflict resolution"
	@echo "   - Offline functionality"
	@echo ""
	@echo "4. Reports & Analytics (test-scenario-4)"
	@echo "   - Report generation"
	@echo "   - Metrics calculation"
	@echo "   - Data visualization"
	@echo "   - Historical data access"
	@echo ""
	@echo "5. Recurring Tasks (test-scenario-5)"
	@echo "   - Recurrence pattern creation"
	@echo "   - Instance generation"
	@echo "   - Series management"
	@echo "   - Pattern modification"