#!/bin/bash
# validate-quickstart-structure.sh
# Validates the structural implementation of quickstart guide steps

echo "🔍 Validating Quickstart Implementation Structure"
echo "=============================================="

# Track validation results
ERRORS=0
WARNINGS=0

# Check required files exist
echo -e "\n📁 Checking Required Files..."
files=(
  "mobile/build/web/index.html"
  "docs/frontend-design.md"
  "docs/migration-checklist.md"
  "docs/implementation-roadmap.md"
  "docs/backend-integration.md"
)

for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "✅ Found: $file"
  else
    echo "❌ Missing: $file"
    ((ERRORS++))
  fi
done

# Check backup files
echo -e "\n💾 Checking Backup Files..."
if [[ -f "mobile/build/web/index.html.backup" ]]; then
  echo "✅ Backup file exists: index.html.backup"
else
  echo "⚠️ Backup file missing (expected during fresh setup)"
  ((WARNINGS++))
fi

if [[ -d "mobile/build/web.backup" ]]; then
  echo "✅ Backup directory exists: web.backup"
else
  echo "⚠️ Backup directory missing (expected during fresh setup)"
  ((WARNINGS++))
fi

# Check HTML structure for new implementation
echo -e "\n🏗️ Checking HTML Structure Implementation..."
if grep -q "project-sidebar" mobile/build/web/index.html; then
  echo "✅ Sidebar structure implemented"
else
  echo "❌ Sidebar structure missing"
  ((ERRORS++))
fi

if grep -q "bottom-nav" mobile/build/web/index.html; then
  echo "❌ Bottom navigation still present (should be removed)"
  ((ERRORS++))
else
  echo "✅ Bottom navigation removed"
fi

if grep -q "pomodoro-modal" mobile/build/web/index.html; then
  echo "✅ Pomodoro modal structure found"
else
  echo "❌ Pomodoro modal structure missing"
  ((ERRORS++))
fi

# Check CSS structure
echo -e "\n🎨 Checking CSS Structure..."
if grep -q "display: grid" mobile/build/web/index.html; then
  echo "✅ Grid layout implementation found"
else
  echo "❌ Grid layout implementation missing"
  ((ERRORS++))
fi

if grep -q "@media.*768px" mobile/build/web/index.html; then
  echo "✅ Responsive breakpoints found"
else
  echo "❌ Responsive breakpoints missing"
  ((ERRORS++))
fi

# Check JavaScript structure
echo -e "\n⚙️ Checking JavaScript Structure..."
if grep -q "ProjectManager\|projectManager" mobile/build/web/index.html; then
  echo "✅ Project management code found"
else
  echo "❌ Project management code missing"
  ((ERRORS++))
fi

if grep -q "startPomodoroForTask\|pomodoro.*task" mobile/build/web/index.html; then
  echo "✅ Task-pomodoro integration found"
else
  echo "❌ Task-pomodoro integration missing"
  ((ERRORS++))
fi

# Check component specifications
echo -e "\n📋 Checking Component Specifications..."
component_files=(
  "docs/components/project-sidebar.md"
  "docs/components/project-list.md"
  "docs/components/daily-stats.md"
  "docs/components/task-list.md"
  "docs/components/task-card.md"
  "docs/components/pomodoro-modal.md"
  "docs/components/timer-display.md"
  "docs/components/task-actions.md"
  "docs/components/project-header.md"
)

FOUND_COMPONENTS=0
for component in "${component_files[@]}"; do
  if [[ -f "$component" ]]; then
    ((FOUND_COMPONENTS++))
  fi
done

echo "✅ Found $FOUND_COMPONENTS component specifications"
if [[ $FOUND_COMPONENTS -lt 9 ]]; then
  echo "⚠️ Missing component specifications (expected: 9, found: $FOUND_COMPONENTS)"
  ((WARNINGS++))
fi

# Check wireframe documentation
echo -e "\n📐 Checking Wireframe Documentation..."
wireframe_files=(
  "docs/wireframes/main-layout.md"
  "docs/wireframes/sidebar-layout.md"
  "docs/wireframes/mobile-layout.md"
)

FOUND_WIREFRAMES=0
for wireframe in "${wireframe_files[@]}"; do
  if [[ -f "$wireframe" ]]; then
    ((FOUND_WIREFRAMES++))
  fi
done

echo "✅ Found $FOUND_WIREFRAMES wireframe documents"
if [[ $FOUND_WIREFRAMES -lt 3 ]]; then
  echo "❌ Missing wireframe documentation (expected: 3, found: $FOUND_WIREFRAMES)"
  ((ERRORS++))
fi

# Check flow documentation
echo -e "\n🔄 Checking Flow Documentation..."
flow_files=(
  "docs/flows/task-pomodoro-flow.md"
  "docs/flows/project-switching-flow.md"
  "docs/flows/responsive-breakpoint-flow.md"
)

FOUND_FLOWS=0
for flow in "${flow_files[@]}"; do
  if [[ -f "$flow" ]]; then
    ((FOUND_FLOWS++))
  fi
done

echo "✅ Found $FOUND_FLOWS flow documents"
if [[ $FOUND_FLOWS -lt 3 ]]; then
  echo "❌ Missing flow documentation (expected: 3, found: $FOUND_FLOWS)"
  ((ERRORS++))
fi

# Check validation scripts
echo -e "\n🧪 Checking Validation Scripts..."
validation_scripts=(
  "scripts/validate-documentation-structure.js"
  "scripts/validate-component-specifications.js"
)

for script in "${validation_scripts[@]}"; do
  if [[ -f "$script" ]]; then
    echo "✅ Found: $script"
  else
    echo "❌ Missing: $script"
    ((ERRORS++))
  fi
done

# Check git status
echo -e "\n📝 Checking Git Status..."
if git status > /dev/null 2>&1; then
  echo "✅ Git repository valid"

  # Check if we're on a feature branch
  CURRENT_BRANCH=$(git branch --show-current)
  if [[ "$CURRENT_BRANCH" == *"003"* ]] || [[ "$CURRENT_BRANCH" == *"frontend"* ]]; then
    echo "✅ On feature branch: $CURRENT_BRANCH"
  else
    echo "⚠️ Not on a feature branch (current: $CURRENT_BRANCH)"
    ((WARNINGS++))
  fi
else
  echo "❌ Git repository issues detected"
  ((ERRORS++))
fi

# Final results
echo -e "\n📊 VALIDATION RESULTS"
echo "====================="

if [[ $ERRORS -eq 0 ]]; then
  echo "✅ Structure validation PASSED"
  if [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️ $WARNINGS warnings found (acceptable)"
  fi
  echo "🎉 Ready for implementation testing"
  exit 0
else
  echo "❌ Structure validation FAILED"
  echo "💥 $ERRORS critical errors found"
  if [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️ $WARNINGS warnings found"
  fi
  echo "🔧 Fix errors before proceeding with implementation"
  exit 1
fi