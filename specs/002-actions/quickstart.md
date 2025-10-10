# Quickstart: GitHub Actions Pipeline Reliability

## Overview
This guide helps you implement and validate reliable GitHub Actions workflows with proper error handling, monitoring, and recovery mechanisms.

## Prerequisites
- GitHub repository with Actions enabled
- Existing Flutter/Go project structure
- Repository secrets configured (if needed)

## Quick Setup

### 1. Validate Current Workflows
```bash
# Check existing workflow syntax
yamllint .github/workflows/*.yml

# Validate against schema
./scripts/validation/validate-workflows.sh

# Run workflow test
gh workflow run "Build macOS App" --ref main
```

### 2. Add Reliability Features
```bash
# Create monitoring scripts
mkdir -p scripts/{setup,validation,monitoring}

# Add workflow validation
cp contracts/workflow-schema.yaml .github/workflow-schema.yaml

# Set up monitoring
./scripts/setup/init-monitoring.sh
```

### 3. Test Error Handling
```bash
# Simulate network failure
gh workflow run "Build macOS App" --ref main -f simulate_network_error=true

# Check error reporting
./scripts/monitoring/check-errors.sh

# Verify retry mechanisms
./scripts/validation/test-retry-logic.sh
```

## Validation Steps

### Workflow Reliability Test
1. **Trigger Test Run**:
   ```bash
   gh workflow run "Build macOS App" --ref main
   ```

2. **Monitor Execution**:
   ```bash
   gh run list --workflow="Build macOS App" --limit=1
   gh run view --log
   ```

3. **Verify Artifacts**:
   ```bash
   gh run list --workflow="Build macOS App" --limit=1 --json databaseId | \
   jq -r '.[0].databaseId' | \
   xargs -I {} gh api repos/:owner/:repo/actions/runs/{}/artifacts
   ```

### Error Handling Test
1. **Introduce Deliberate Failure**:
   ```bash
   # Temporarily break a dependency
   git commit -m "test: introduce build failure"
   git push
   ```

2. **Verify Error Detection**:
   ```bash
   # Check if error was properly categorized
   ./scripts/monitoring/get-error-reports.sh
   ```

3. **Validate Recovery**:
   ```bash
   # Fix the issue and verify retry works
   git revert HEAD
   git push
   ```

### Performance Validation
1. **Baseline Measurement**:
   ```bash
   # Run 3 consecutive builds
   for i in {1..3}; do
     gh workflow run "Build macOS App" --ref main
     sleep 30
   done
   ```

2. **Check Metrics**:
   ```bash
   ./scripts/monitoring/performance-report.sh
   ```

3. **Verify SLA Compliance**:
   ```bash
   # Should complete in <10 minutes
   ./scripts/validation/check-performance-sla.sh
   ```

## Success Criteria

### ✅ Reliability
- [ ] Workflow completes successfully on clean runs
- [ ] Artifacts are generated and accessible
- [ ] Build time is within 10-minute SLA
- [ ] No manual intervention required

### ✅ Error Handling
- [ ] Transient failures trigger automatic retry
- [ ] Permanent failures generate clear error reports
- [ ] Failed runs don't block subsequent executions
- [ ] Error notifications reach appropriate stakeholders

### ✅ Monitoring
- [ ] Workflow status is tracked and reported
- [ ] Performance metrics are collected
- [ ] Success rate exceeds 95% over 7 days
- [ ] Error trends are identifiable

### ✅ Recovery
- [ ] Failed workflows can be manually restarted
- [ ] Partial failures don't corrupt subsequent runs
- [ ] Recovery procedures are documented
- [ ] Rollback mechanisms work correctly

## Troubleshooting

### Common Issues

**Workflow Timeout**:
```bash
# Check runner availability
gh api /repos/:owner/:repo/actions/runners

# Verify step timeouts
grep -r "timeout-minutes" .github/workflows/
```

**Artifact Upload Failure**:
```bash
# Check artifact size limits
du -sh build/output/

# Verify upload permissions
gh auth status
```

**Dependency Resolution**:
```bash
# Clear caches
gh cache list
gh cache delete-all

# Validate dependencies
./scripts/validation/check-dependencies.sh
```

### Emergency Procedures

**Complete Workflow Failure**:
1. Check GitHub Status: https://www.githubstatus.com/
2. Review recent commits for breaking changes
3. Temporarily disable problematic workflows
4. Escalate to infrastructure team if needed

**Security Alert**:
1. Rotate repository secrets immediately
2. Review workflow logs for sensitive data
3. Audit recent workflow changes
4. Report to security team

## Next Steps
- Set up automated monitoring alerts
- Implement advanced retry strategies
- Add performance optimization
- Configure stakeholder notifications