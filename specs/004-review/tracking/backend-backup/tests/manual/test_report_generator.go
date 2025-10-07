package manual

import (
	"encoding/json"
	"fmt"
	"html/template"
	"os"
	"time"
)

// TestReportGenerator creates comprehensive test reports
type TestReportGenerator struct {
	Results    *TestResults
	Template   *template.Template
	OutputPath string
}

// TestReport contains all information for the report
type TestReport struct {
	GeneratedAt   time.Time
	TestDuration  time.Duration
	Summary       TestSummary
	Scenarios     []ScenarioReport
	Performance   PerformanceReport
	Environment   EnvironmentInfo
	Issues        []IssueReport
	Recommendations []string
}

type TestSummary struct {
	TotalScenarios   int
	PassedScenarios  int
	FailedScenarios  int
	TotalSteps       int
	PassedSteps      int
	FailedSteps      int
	SuccessRate      float64
	OverallStatus    string
}

type ScenarioReport struct {
	Name         string
	Status       string
	Duration     time.Duration
	StepsTotal   int
	StepsPassed  int
	StepsFailed  int
	Issues       []string
	Steps        []StepReport
}

type StepReport struct {
	Name         string
	Status       string
	Duration     time.Duration
	ResponseTime time.Duration
	ErrorMessage string
}

type PerformanceReport struct {
	APIEndpoints []EndpointPerformance
	TimerTests   []TimerPerformance
	Summary      PerformanceSummary
}

type EndpointPerformance struct {
	Endpoint     string
	ResponseTime time.Duration
	Target       time.Duration
	Status       string
}

type TimerPerformance struct {
	TestName   string
	Precision  time.Duration
	Target     time.Duration
	Status     string
}

type PerformanceSummary struct {
	AllTargetsMet          bool
	WorstAPIResponseTime   time.Duration
	WorstTimerPrecision    time.Duration
	APITargetsMetCount     int
	TimerTargetsMetCount   int
	TotalAPITests          int
	TotalTimerTests        int
}

type EnvironmentInfo struct {
	BackendURL     string
	TestUser       string
	ExecutionTime  time.Time
	Platform       string
	GoVersion      string
	TestFramework  string
}

type IssueReport struct {
	Severity    string
	Scenario    string
	Step        string
	Description string
	Impact      string
	Suggestion  string
}

// NewTestReportGenerator creates a new report generator
func NewTestReportGenerator(results *TestResults, outputPath string) *TestReportGenerator {
	return &TestReportGenerator{
		Results:    results,
		OutputPath: outputPath,
	}
}

// GenerateReport creates a comprehensive test report
func (trg *TestReportGenerator) GenerateReport() (*TestReport, error) {
	report := &TestReport{
		GeneratedAt:  time.Now(),
		TestDuration: trg.Results.EndTime.Sub(trg.Results.StartTime),
		Environment:  trg.buildEnvironmentInfo(),
	}

	// Build summary
	report.Summary = trg.buildTestSummary()

	// Build scenario reports
	report.Scenarios = trg.buildScenarioReports()

	// Build performance report
	report.Performance = trg.buildPerformanceReport()

	// Identify issues
	report.Issues = trg.identifyIssues()

	// Generate recommendations
	report.Recommendations = trg.generateRecommendations(report)

	return report, nil
}

// buildTestSummary creates the overall test summary
func (trg *TestReportGenerator) buildTestSummary() TestSummary {
	summary := TestSummary{
		TotalScenarios: len(trg.Results.Scenarios),
	}

	for _, scenario := range trg.Results.Scenarios {
		summary.TotalSteps += len(scenario.Steps)

		if scenario.Passed {
			summary.PassedScenarios++
		} else {
			summary.FailedScenarios++
		}

		for _, step := range scenario.Steps {
			if step.Passed {
				summary.PassedSteps++
			} else {
				summary.FailedSteps++
			}
		}
	}

	if summary.TotalScenarios > 0 {
		summary.SuccessRate = float64(summary.PassedScenarios) / float64(summary.TotalScenarios) * 100
	}

	if summary.PassedScenarios == summary.TotalScenarios {
		summary.OverallStatus = "PASSED"
	} else if summary.PassedScenarios > 0 {
		summary.OverallStatus = "PARTIAL"
	} else {
		summary.OverallStatus = "FAILED"
	}

	return summary
}

// buildScenarioReports creates detailed scenario reports
func (trg *TestReportGenerator) buildScenarioReports() []ScenarioReport {
	var reports []ScenarioReport

	for _, scenario := range trg.Results.Scenarios {
		report := ScenarioReport{
			Name:        scenario.Name,
			Duration:    scenario.EndTime.Sub(scenario.StartTime),
			StepsTotal:  len(scenario.Steps),
			Issues:      scenario.Issues,
			Steps:       make([]StepReport, len(scenario.Steps)),
		}

		// Set status
		if scenario.Passed {
			report.Status = "PASSED"
		} else {
			report.Status = "FAILED"
		}

		// Process steps
		for i, step := range scenario.Steps {
			stepReport := StepReport{
				Name:         step.Name,
				Duration:     step.Duration,
				ResponseTime: step.ResponseTime,
				ErrorMessage: step.ErrorMsg,
			}

			if step.Passed {
				stepReport.Status = "PASSED"
				report.StepsPassed++
			} else {
				stepReport.Status = "FAILED"
				report.StepsFailed++
			}

			report.Steps[i] = stepReport
		}

		reports = append(reports, report)
	}

	return reports
}

// buildPerformanceReport creates the performance analysis report
func (trg *TestReportGenerator) buildPerformanceReport() PerformanceReport {
	report := PerformanceReport{
		APIEndpoints: make([]EndpointPerformance, 0),
		TimerTests:   make([]TimerPerformance, 0),
	}

	// Process API performance
	apiTargetsMet := 0
	target := 150 * time.Millisecond
	worstAPI := time.Duration(0)

	for endpoint, duration := range trg.Results.Performance.APIResponseTimes {
		status := "PASSED"
		if duration > target {
			status = "FAILED"
		} else {
			apiTargetsMet++
		}

		if duration > worstAPI {
			worstAPI = duration
		}

		report.APIEndpoints = append(report.APIEndpoints, EndpointPerformance{
			Endpoint:     endpoint,
			ResponseTime: duration,
			Target:       target,
			Status:       status,
		})
	}

	// Process timer performance
	timerTargetsMet := 0
	timerTarget := 1 * time.Second
	worstTimer := time.Duration(0)

	for test, precision := range trg.Results.Performance.TimerPrecision {
		status := "PASSED"
		absPrecision := precision
		if absPrecision < 0 {
			absPrecision = -absPrecision
		}

		if absPrecision > timerTarget {
			status = "FAILED"
		} else {
			timerTargetsMet++
		}

		if absPrecision > worstTimer {
			worstTimer = absPrecision
		}

		report.TimerTests = append(report.TimerTests, TimerPerformance{
			TestName:  test,
			Precision: precision,
			Target:    timerTarget,
			Status:    status,
		})
	}

	// Build summary
	report.Summary = PerformanceSummary{
		AllTargetsMet:          apiTargetsMet == len(report.APIEndpoints) && timerTargetsMet == len(report.TimerTests),
		WorstAPIResponseTime:   worstAPI,
		WorstTimerPrecision:    worstTimer,
		APITargetsMetCount:     apiTargetsMet,
		TimerTargetsMetCount:   timerTargetsMet,
		TotalAPITests:          len(report.APIEndpoints),
		TotalTimerTests:        len(report.TimerTests),
	}

	return report
}

// buildEnvironmentInfo creates environment information
func (trg *TestReportGenerator) buildEnvironmentInfo() EnvironmentInfo {
	return EnvironmentInfo{
		BackendURL:    "http://localhost:3000/v1", // Would be configurable
		TestUser:      "test@example.com",         // Would be configurable
		ExecutionTime: trg.Results.StartTime,
		Platform:      "Linux/Docker",
		GoVersion:     "1.21+",
		TestFramework: "Manual Test Suite v1.0",
	}
}

// identifyIssues analyzes results and identifies issues
func (trg *TestReportGenerator) identifyIssues() []IssueReport {
	var issues []IssueReport

	// Check for failed scenarios
	for _, scenario := range trg.Results.Scenarios {
		if !scenario.Passed {
			for _, step := range scenario.Steps {
				if !step.Passed {
					issues = append(issues, IssueReport{
						Severity:    "HIGH",
						Scenario:    scenario.Name,
						Step:        step.Name,
						Description: step.ErrorMsg,
						Impact:      "Scenario cannot complete successfully",
						Suggestion:  "Review implementation and fix the underlying issue",
					})
				}
			}
		}
	}

	// Check for performance issues
	for endpoint, duration := range trg.Results.Performance.APIResponseTimes {
		if duration > 150*time.Millisecond {
			issues = append(issues, IssueReport{
				Severity:    "MEDIUM",
				Scenario:    "Performance",
				Step:        fmt.Sprintf("API %s", endpoint),
				Description: fmt.Sprintf("Response time %v exceeds 150ms target", duration),
				Impact:      "Poor user experience, potential timeout issues",
				Suggestion:  "Optimize API endpoint, add caching, review database queries",
			})
		}
	}

	for test, precision := range trg.Results.Performance.TimerPrecision {
		absPrecision := precision
		if absPrecision < 0 {
			absPrecision = -absPrecision
		}

		if absPrecision > 1*time.Second {
			issues = append(issues, IssueReport{
				Severity:    "HIGH",
				Scenario:    "Performance",
				Step:        fmt.Sprintf("Timer %s", test),
				Description: fmt.Sprintf("Timer precision %v exceeds ±1s target", precision),
				Impact:      "Inaccurate Pomodoro sessions, user trust issues",
				Suggestion:  "Review timer implementation, check system clock accuracy",
			})
		}
	}

	return issues
}

// generateRecommendations provides actionable recommendations
func (trg *TestReportGenerator) generateRecommendations(report *TestReport) []string {
	var recommendations []string

	// Overall recommendations based on success rate
	if report.Summary.SuccessRate < 100 {
		recommendations = append(recommendations, "Address all failing test scenarios before production deployment")
	}

	if report.Summary.SuccessRate < 80 {
		recommendations = append(recommendations, "Consider implementing additional unit tests to catch issues earlier")
	}

	// Performance recommendations
	if !report.Performance.Summary.AllTargetsMet {
		recommendations = append(recommendations, "Optimize performance to meet all response time and precision targets")
	}

	if report.Performance.Summary.WorstAPIResponseTime > 200*time.Millisecond {
		recommendations = append(recommendations, "Implement caching layer for frequently accessed endpoints")
	}

	// Security recommendations
	recommendations = append(recommendations, "Implement rate limiting to prevent abuse")
	recommendations = append(recommendations, "Add input validation and sanitization for all endpoints")
	recommendations = append(recommendations, "Enable HTTPS in production environment")

	// Monitoring recommendations
	recommendations = append(recommendations, "Set up application monitoring and alerting")
	recommendations = append(recommendations, "Implement health checks for all critical services")
	recommendations = append(recommendations, "Add structured logging for better debugging")

	// Testing recommendations
	recommendations = append(recommendations, "Automate this manual test suite in CI/CD pipeline")
	recommendations = append(recommendations, "Add load testing to validate performance under stress")
	recommendations = append(recommendations, "Implement cross-browser testing for web components")

	return recommendations
}

// SaveJSONReport saves the report as JSON
func (trg *TestReportGenerator) SaveJSONReport(report *TestReport, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create report file: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(report); err != nil {
		return fmt.Errorf("failed to encode report: %w", err)
	}

	return nil
}

// SaveHTMLReport saves the report as HTML
func (trg *TestReportGenerator) SaveHTMLReport(report *TestReport, filename string) error {
	htmlTemplate := `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pomodoro Genie - Manual Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; border-bottom: 2px solid #4CAF50; padding-bottom: 20px; margin-bottom: 30px; }
        .status-passed { color: #4CAF50; font-weight: bold; }
        .status-failed { color: #f44336; font-weight: bold; }
        .status-partial { color: #ff9800; font-weight: bold; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .summary-card { background: #f9f9f9; padding: 15px; border-radius: 8px; text-align: center; }
        .scenarios { margin: 30px 0; }
        .scenario { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 8px; }
        .scenario.passed { border-left: 4px solid #4CAF50; }
        .scenario.failed { border-left: 4px solid #f44336; }
        .steps { margin: 10px 0; }
        .step { padding: 5px 10px; margin: 5px 0; border-radius: 4px; }
        .step.passed { background: #e8f5e8; }
        .step.failed { background: #fde8e8; }
        .performance { margin: 30px 0; }
        .performance table { width: 100%; border-collapse: collapse; }
        .performance th, .performance td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        .performance th { background: #f5f5f5; }
        .issues { margin: 30px 0; }
        .issue { margin: 10px 0; padding: 15px; border-radius: 8px; }
        .issue.high { background: #ffebee; border-left: 4px solid #f44336; }
        .issue.medium { background: #fff3e0; border-left: 4px solid #ff9800; }
        .recommendations { margin: 30px 0; }
        .recommendations ul { list-style-type: none; padding: 0; }
        .recommendations li { margin: 10px 0; padding: 10px; background: #e3f2fd; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🍅 Pomodoro Genie - Manual Test Report</h1>
            <p>Generated on {{.GeneratedAt.Format "2006-01-02 15:04:05"}}</p>
            <p>Test Duration: {{.TestDuration.Round (time.Millisecond)}}</p>
            <h2 class="status-{{.Summary.OverallStatus | lower}}">Overall Status: {{.Summary.OverallStatus}}</h2>
        </div>

        <div class="summary">
            <div class="summary-card">
                <h3>Scenarios</h3>
                <p>{{.Summary.PassedScenarios}}/{{.Summary.TotalScenarios}} Passed</p>
                <p>Success Rate: {{printf "%.1f" .Summary.SuccessRate}}%</p>
            </div>
            <div class="summary-card">
                <h3>Steps</h3>
                <p>{{.Summary.PassedSteps}}/{{.Summary.TotalSteps}} Passed</p>
            </div>
            <div class="summary-card">
                <h3>Performance</h3>
                <p>API: {{.Performance.Summary.APITargetsMetCount}}/{{.Performance.Summary.TotalAPITests}} Targets Met</p>
                <p>Timer: {{.Performance.Summary.TimerTargetsMetCount}}/{{.Performance.Summary.TotalTimerTests}} Targets Met</p>
            </div>
            <div class="summary-card">
                <h3>Issues</h3>
                <p>{{len .Issues}} Issues Found</p>
            </div>
        </div>

        <div class="scenarios">
            <h2>Test Scenarios</h2>
            {{range .Scenarios}}
            <div class="scenario {{.Status | lower}}">
                <h3>{{.Name}} - <span class="status-{{.Status | lower}}">{{.Status}}</span></h3>
                <p>Duration: {{.Duration.Round (time.Millisecond)}} | Steps: {{.StepsPassed}}/{{.StepsTotal}} Passed</p>

                <div class="steps">
                    {{range .Steps}}
                    <div class="step {{.Status | lower}}">
                        <strong>{{.Name}}</strong> - {{.Status}}
                        {{if .ResponseTime}} ({{.ResponseTime.Round (time.Millisecond)}}){{end}}
                        {{if .ErrorMessage}} - {{.ErrorMessage}}{{end}}
                    </div>
                    {{end}}
                </div>
            </div>
            {{end}}
        </div>

        <div class="performance">
            <h2>Performance Analysis</h2>

            <h3>API Response Times</h3>
            <table>
                <tr><th>Endpoint</th><th>Response Time</th><th>Target</th><th>Status</th></tr>
                {{range .Performance.APIEndpoints}}
                <tr>
                    <td>{{.Endpoint}}</td>
                    <td>{{.ResponseTime.Round (time.Millisecond)}}</td>
                    <td>{{.Target.Round (time.Millisecond)}}</td>
                    <td class="status-{{.Status | lower}}">{{.Status}}</td>
                </tr>
                {{end}}
            </table>

            <h3>Timer Precision</h3>
            <table>
                <tr><th>Test</th><th>Precision</th><th>Target</th><th>Status</th></tr>
                {{range .Performance.TimerTests}}
                <tr>
                    <td>{{.TestName}}</td>
                    <td>{{if lt .Precision 0}}-{{end}}{{.Precision.Round (time.Millisecond)}}</td>
                    <td>±{{.Target.Round (time.Millisecond)}}</td>
                    <td class="status-{{.Status | lower}}">{{.Status}}</td>
                </tr>
                {{end}}
            </table>
        </div>

        {{if .Issues}}
        <div class="issues">
            <h2>Issues Found</h2>
            {{range .Issues}}
            <div class="issue {{.Severity | lower}}">
                <h4>{{.Severity}} - {{.Scenario}}: {{.Step}}</h4>
                <p><strong>Description:</strong> {{.Description}}</p>
                <p><strong>Impact:</strong> {{.Impact}}</p>
                <p><strong>Suggestion:</strong> {{.Suggestion}}</p>
            </div>
            {{end}}
        </div>
        {{end}}

        <div class="recommendations">
            <h2>Recommendations</h2>
            <ul>
                {{range .Recommendations}}
                <li>{{.}}</li>
                {{end}}
            </ul>
        </div>

        <div class="environment">
            <h2>Environment Information</h2>
            <p><strong>Backend URL:</strong> {{.Environment.BackendURL}}</p>
            <p><strong>Test User:</strong> {{.Environment.TestUser}}</p>
            <p><strong>Platform:</strong> {{.Environment.Platform}}</p>
            <p><strong>Go Version:</strong> {{.Environment.GoVersion}}</p>
            <p><strong>Test Framework:</strong> {{.Environment.TestFramework}}</p>
        </div>
    </div>
</body>
</html>`

	tmpl, err := template.New("report").Funcs(template.FuncMap{
		"lower": func(s string) string {
			return fmt.Sprintf("%s", s)
		},
	}).Parse(htmlTemplate)
	if err != nil {
		return fmt.Errorf("failed to parse template: %w", err)
	}

	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create HTML file: %w", err)
	}
	defer file.Close()

	if err := tmpl.Execute(file, report); err != nil {
		return fmt.Errorf("failed to execute template: %w", err)
	}

	return nil
}