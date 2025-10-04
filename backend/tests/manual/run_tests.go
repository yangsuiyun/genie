package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/pomodoro-team/pomodoro-app/backend/tests/manual"
)

func main() {
	var (
		baseURL     = flag.String("url", "http://localhost:3000/v1", "Backend API base URL")
		skipSetup   = flag.Bool("skip-setup", false, "Skip test environment setup")
		scenarios   = flag.String("scenarios", "all", "Scenarios to run (all, 1, 2, 3, 4, 5)")
		timeout     = flag.Duration("timeout", 30*time.Minute, "Test execution timeout")
		verbose     = flag.Bool("verbose", false, "Enable verbose output")
		reportFile  = flag.String("report", "", "Save test report to file")
	)
	flag.Parse()

	fmt.Println("🧪 Pomodoro Genie Manual Test Execution")
	fmt.Println("=====================================")
	fmt.Printf("Backend URL: %s\n", *baseURL)
	fmt.Printf("Timeout: %v\n", *timeout)
	fmt.Printf("Scenarios: %s\n", *scenarios)
	fmt.Println()

	// Create test runner
	runner := manual.NewTestRunner(*baseURL)
	runner.SetVerbose(*verbose)

	// Set execution timeout
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// Execute tests
	if err := executeTests(ctx, runner, *scenarios, *skipSetup); err != nil {
		log.Printf("Test execution failed: %v", err)
		os.Exit(1)
	}

	// Save report if requested
	if *reportFile != "" {
		if err := runner.SaveReport(*reportFile); err != nil {
			log.Printf("Failed to save report: %v", err)
		} else {
			fmt.Printf("📄 Test report saved to: %s\n", *reportFile)
		}
	}

	// Exit with appropriate code
	if runner.AllTestsPassed() {
		fmt.Println("\n🎉 ALL TESTS PASSED!")
		os.Exit(0)
	} else {
		fmt.Println("\n❌ SOME TESTS FAILED!")
		os.Exit(1)
	}
}

func executeTests(ctx context.Context, runner *manual.TestRunner, scenarios string, skipSetup bool) error {
	// Setup test environment
	if !skipSetup {
		fmt.Println("🔧 Setting up test environment...")
		if err := runner.SetupTestEnvironment(); err != nil {
			return fmt.Errorf("test setup failed: %w", err)
		}
	}

	// Execute scenarios based on selection
	switch scenarios {
	case "all":
		return runner.ExecuteAllScenarios(ctx)
	case "1":
		return runner.ExecuteScenario1_PomodoroWorkflow(ctx)
	case "2":
		return runner.ExecuteScenario2_TaskManagement(ctx)
	case "3":
		return runner.ExecuteScenario3_CrossDeviceSync(ctx)
	case "4":
		return runner.ExecuteScenario4_ReportsAnalytics(ctx)
	case "5":
		return runner.ExecuteScenario5_RecurringTasks(ctx)
	default:
		return fmt.Errorf("invalid scenario selection: %s", scenarios)
	}
}