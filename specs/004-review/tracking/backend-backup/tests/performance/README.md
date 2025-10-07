# Performance Testing

This directory contains performance tests for the Pomodoro Genie backend API and database operations.

## Overview

The performance tests ensure that the backend meets the following requirements:
- **API Response Time**: < 150ms for all endpoints
- **Database Query Time**: < 50ms for simple queries, < 200ms for complex queries
- **Throughput**: > 500 requests/second under normal load
- **Error Rate**: < 1% under normal conditions
- **Memory Usage**: < 100MB (tested in memory_usage_test.go)

## Test Structure

```
backend/tests/performance/
├── api_performance_test.go       # API endpoint performance tests
├── database_performance_test.go  # Database operation performance tests
├── memory_usage_test.go          # Memory usage validation tests
├── run_performance_tests.sh      # Test runner script
└── README.md                     # This file
```

## Performance Test Categories

### 1. API Performance Tests (`api_performance_test.go`)

Tests all major API endpoints under various load conditions:

- **Authentication Endpoints**:
  - User registration
  - User login
  - Token refresh

- **Task Management**:
  - Create tasks
  - List tasks with pagination
  - Get individual tasks
  - Update tasks
  - Delete tasks

- **Pomodoro Sessions**:
  - Start sessions
  - Update sessions
  - List sessions
  - Session history

- **Reports**:
  - Generate reports
  - Analytics queries

### 2. Database Performance Tests (`database_performance_test.go`)

Tests database operations and query performance:

- **CRUD Operations**:
  - Insert performance
  - Query performance
  - Update performance
  - Delete performance

- **Complex Queries**:
  - Filtered searches
  - Pagination
  - Analytics aggregations
  - Reporting queries

- **Batch Operations**:
  - Batch inserts
  - Batch updates
  - Bulk operations

- **Concurrent Access**:
  - Multiple simultaneous connections
  - Connection pool efficiency
  - Transaction performance

### 3. Memory Usage Tests (`memory_usage_test.go`)

Monitors memory consumption:

- **Baseline Memory Usage**: Application startup memory
- **Request Processing**: Memory per request
- **Memory Leaks**: Long-running operation monitoring
- **Garbage Collection**: GC pressure and efficiency

## Running Performance Tests

### Prerequisites

1. **Go Environment**: Go 1.21+ installed
2. **Dependencies**: All Go modules installed (`go mod download`)
3. **Database**: Supabase instance running (for integration tests)
4. **Test Data**: Database seeded with test data

### Quick Start

```bash
# Run all performance tests
./run_performance_tests.sh

# Run specific test category
go test -v -run TestAuthEndpointsPerformance
go test -v -run TestDatabasePerformance
go test -v -run TestMemoryUsage

# Run with benchmarking
go test -v -bench=. -benchtime=30s

# Run sustained load tests (takes longer)
go test -v -run TestSustainedLoad -timeout=5m
```

### Test Configuration

#### Environment Variables

```bash
# Database connection
export SUPABASE_URL="your-supabase-url"
export SUPABASE_KEY="your-supabase-key"

# Test configuration
export PERF_TEST_DURATION="30s"      # Sustained test duration
export PERF_CONCURRENT_USERS="100"   # Max concurrent users
export PERF_TARGET_RPS="500"         # Target requests per second
export PERF_ERROR_THRESHOLD="0.01"   # 1% error rate threshold
```

#### Test Thresholds

Performance thresholds are defined as constants in each test file:

```go
const (
    MaxAPIResponseTime    = 150 * time.Millisecond
    MaxDBQueryTime        = 50 * time.Millisecond
    MaxConcurrentUsers    = 100
    MinThroughput         = 500 // requests per second
    AcceptableErrorRate   = 0.01 // 1%
)
```

## Test Scenarios

### 1. Normal Load Testing

Simulates typical application usage:
- 10-50 concurrent users
- Mixed API operations
- Realistic data volumes
- 30-second test duration

### 2. Peak Load Testing

Tests performance under high load:
- 100+ concurrent users
- Sustained high request rate
- Stress testing of all endpoints
- Resource utilization monitoring

### 3. Endurance Testing

Tests stability over extended periods:
- Moderate concurrent load
- Extended test duration (5+ minutes)
- Memory leak detection
- Performance degradation monitoring

### 4. Spike Testing

Tests response to sudden load increases:
- Rapid scaling from low to high load
- Recovery time measurement
- System stability validation

## Performance Metrics

### Response Time Metrics

- **Average Response Time**: Mean response time across all requests
- **Median Response Time**: 50th percentile response time
- **P95 Response Time**: 95th percentile response time
- **P99 Response Time**: 99th percentile response time
- **Max Response Time**: Worst-case response time

### Throughput Metrics

- **Requests Per Second (RPS)**: Total requests processed per second
- **Successful RPS**: Successful requests per second
- **Failed RPS**: Failed requests per second

### Error Metrics

- **Error Rate**: Percentage of failed requests
- **Error Types**: Breakdown of error categories
- **Timeout Rate**: Percentage of requests that timed out

### Resource Metrics

- **CPU Usage**: Processor utilization
- **Memory Usage**: RAM consumption and growth
- **Database Connections**: Connection pool utilization
- **Goroutine Count**: Concurrent goroutine monitoring

## Continuous Integration

### GitHub Actions Integration

```yaml
name: Performance Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *' # Daily at 2 AM

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v3
        with:
          go-version: '1.21'

      - name: Run Performance Tests
        run: |
          cd backend/tests/performance
          ./run_performance_tests.sh
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_KEY: ${{ secrets.SUPABASE_KEY }}

      - name: Upload Performance Report
        uses: actions/upload-artifact@v3
        with:
          name: performance-report
          path: backend/tests/performance/reports/
```

### Performance Monitoring

Set up alerts for performance regressions:

1. **Response Time Alerts**: Alert if P95 response time > 300ms
2. **Error Rate Alerts**: Alert if error rate > 2%
3. **Throughput Alerts**: Alert if RPS drops below 400
4. **Memory Alerts**: Alert if memory usage > 150MB

## Troubleshooting

### Common Issues

1. **High Response Times**:
   - Check database query performance
   - Review middleware overhead
   - Verify connection pool settings
   - Monitor garbage collection pressure

2. **High Error Rates**:
   - Check database connection limits
   - Review rate limiting configuration
   - Verify authentication middleware
   - Check resource constraints

3. **Low Throughput**:
   - Increase connection pool size
   - Optimize database queries
   - Review CPU and memory limits
   - Check network latency

4. **Memory Leaks**:
   - Review goroutine lifecycle
   - Check database connection cleanup
   - Monitor request context handling
   - Verify cache eviction policies

### Performance Optimization Tips

1. **Database Optimization**:
   - Add appropriate indexes
   - Optimize query patterns
   - Use connection pooling
   - Implement query caching

2. **API Optimization**:
   - Enable response compression
   - Implement request caching
   - Optimize JSON serialization
   - Use efficient middleware

3. **Resource Management**:
   - Tune garbage collector
   - Optimize memory allocation
   - Monitor goroutine usage
   - Implement circuit breakers

## Reporting

Performance test results are automatically generated in multiple formats:

### HTML Reports
- Interactive charts and graphs
- Response time distributions
- Throughput analysis
- Error breakdowns

### JSON Reports
- Machine-readable metrics
- Historical trend data
- CI/CD integration data
- Alert threshold comparisons

### CSV Export
- Raw performance data
- Statistical analysis
- Spreadsheet import
- Custom analysis tools

## Best Practices

1. **Consistent Testing Environment**:
   - Use identical hardware/containers
   - Control network conditions
   - Ensure consistent data volumes
   - Isolate from other processes

2. **Realistic Test Data**:
   - Use production-like data volumes
   - Include realistic user patterns
   - Test with actual payload sizes
   - Consider data distribution

3. **Regular Testing**:
   - Run tests on every commit
   - Schedule daily performance runs
   - Monitor long-term trends
   - Set performance budgets

4. **Comprehensive Monitoring**:
   - Monitor all system resources
   - Track application metrics
   - Log performance anomalies
   - Set up alerting

## Resources

- [Go Performance Testing Guide](https://golang.org/doc/diagnostics.html)
- [Database Performance Best Practices](https://supabase.com/docs/guides/platform/performance)
- [HTTP Load Testing Tools](https://github.com/wg/wrk)
- [Performance Monitoring Tools](https://prometheus.io/)