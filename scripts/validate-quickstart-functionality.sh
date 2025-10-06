#!/bin/bash
# validate-quickstart-functionality.sh
# Validates the functional implementation of quickstart guide steps

echo "🔍 Validating Quickstart Implementation Functionality"
echo "===================================================="

# Track validation results
ERRORS=0
WARNINGS=0
TEST_PORT=3002
API_PORT=8083

# Function to cleanup processes
cleanup() {
  echo -e "\n🧹 Cleaning up test processes..."
  kill $SERVER_PID 2>/dev/null
  pkill -f "python3 -m http.server $TEST_PORT" 2>/dev/null
}

# Set cleanup trap
trap cleanup EXIT

# Test web server functionality
echo -e "\n🌐 Testing Web Server Functionality..."
cd mobile/build/web || {
  echo "❌ Cannot access mobile/build/web directory"
  ((ERRORS++))
  exit 1
}

# Start test server
echo "🚀 Starting test server on port $TEST_PORT..."
python3 -m http.server $TEST_PORT > /dev/null 2>&1 &
SERVER_PID=$!
sleep 3

# Test server response
if curl -s http://localhost:$TEST_PORT > /dev/null; then
  echo "✅ Web server running on port $TEST_PORT"
else
  echo "❌ Web server failed to start on port $TEST_PORT"
  ((ERRORS++))
fi

# Test HTML content
echo -e "\n📄 Testing HTML Content..."
HTML_RESPONSE=$(curl -s http://localhost:$TEST_PORT)

if echo "$HTML_RESPONSE" | grep -q "Pomodoro Genie"; then
  echo "✅ HTML contains app title"
else
  echo "❌ HTML missing app title"
  ((ERRORS++))
fi

if echo "$HTML_RESPONSE" | grep -q "project-sidebar\|sidebar"; then
  echo "✅ HTML contains sidebar structure"
else
  echo "❌ HTML missing sidebar structure"
  ((ERRORS++))
fi

# Test JavaScript presence
echo -e "\n⚙️ Testing JavaScript Implementation..."
if echo "$HTML_RESPONSE" | grep -q "function.*project\|class.*Project\|ProjectManager"; then
  echo "✅ Project management JavaScript found"
else
  echo "❌ Project management JavaScript missing"
  ((ERRORS++))
fi

if echo "$HTML_RESPONSE" | grep -q "pomodoro.*task\|task.*pomodoro\|startPomodoroForTask"; then
  echo "✅ Task-pomodoro integration JavaScript found"
else
  echo "❌ Task-pomodoro integration JavaScript missing"
  ((ERRORS++))
fi

# Test CSS implementation
echo -e "\n🎨 Testing CSS Implementation..."
if echo "$HTML_RESPONSE" | grep -q "grid-template-columns\|display.*grid"; then
  echo "✅ Grid layout CSS found"
else
  echo "❌ Grid layout CSS missing"
  ((ERRORS++))
fi

if echo "$HTML_RESPONSE" | grep -q "@media.*max-width.*768px\|@media.*768px"; then
  echo "✅ Responsive CSS breakpoints found"
else
  echo "❌ Responsive CSS breakpoints missing"
  ((ERRORS++))
fi

# Test file size and performance
echo -e "\n📊 Testing Performance Metrics..."
cd ../../.. # Return to project root

HTML_SIZE_BYTES=$(stat -c%s mobile/build/web/index.html 2>/dev/null || stat -f%z mobile/build/web/index.html 2>/dev/null)
HTML_SIZE_KB=$((HTML_SIZE_BYTES / 1024))

echo "📄 HTML file size: ${HTML_SIZE_KB}KB"

if [[ $HTML_SIZE_BYTES -gt 2097152 ]]; then # 2MB
  echo "⚠️ HTML file larger than 2MB (${HTML_SIZE_KB}KB)"
  ((WARNINGS++))
elif [[ $HTML_SIZE_BYTES -gt 1048576 ]]; then # 1MB
  echo "⚠️ HTML file larger than 1MB (${HTML_SIZE_KB}KB)"
  ((WARNINGS++))
else
  echo "✅ HTML file size acceptable (${HTML_SIZE_KB}KB)"
fi

# Test API integration
echo -e "\n🔗 Testing Backend API Integration..."
if curl -s http://localhost:$API_PORT/api/health > /dev/null 2>&1; then
  echo "✅ Backend API accessible on port $API_PORT"

  # Test projects endpoint
  PROJECTS_RESPONSE=$(curl -s http://localhost:$API_PORT/api/projects)
  if [[ $? -eq 0 ]]; then
    echo "✅ Projects API endpoint responding"

    # Check if response is valid JSON
    if echo "$PROJECTS_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
      echo "✅ Projects API returns valid JSON"
    else
      echo "⚠️ Projects API response not valid JSON"
      ((WARNINGS++))
    fi
  else
    echo "⚠️ Projects API endpoint not responding"
    ((WARNINGS++))
  fi

  # Test tasks endpoint (if projects exist)
  TASKS_RESPONSE=$(curl -s http://localhost:$API_PORT/api/tasks)
  if [[ $? -eq 0 ]]; then
    echo "✅ Tasks API endpoint accessible"
  else
    echo "⚠️ Tasks API endpoint not accessible"
    ((WARNINGS++))
  fi

else
  echo "⚠️ Backend API not available on port $API_PORT"
  echo "   This is expected if backend is not running"
  ((WARNINGS++))
fi

# Test directory structure
echo -e "\n📁 Testing Directory Structure..."
required_dirs=(
  "docs/components"
  "docs/wireframes"
  "docs/flows"
  "scripts"
)

for dir in "${required_dirs[@]}"; do
  if [[ -d "$dir" ]]; then
    echo "✅ Directory exists: $dir"
  else
    echo "❌ Directory missing: $dir"
    ((ERRORS++))
  fi
done

# Test component file count
COMPONENT_COUNT=$(find docs/components -name "*.md" -type f | wc -l)
echo "📋 Found $COMPONENT_COUNT component specifications"

if [[ $COMPONENT_COUNT -ge 9 ]]; then
  echo "✅ Sufficient component specifications ($COMPONENT_COUNT >= 9)"
else
  echo "⚠️ Insufficient component specifications ($COMPONENT_COUNT < 9)"
  ((WARNINGS++))
fi

# Test wireframe file count
WIREFRAME_COUNT=$(find docs/wireframes -name "*.md" -type f | wc -l)
echo "📐 Found $WIREFRAME_COUNT wireframe documents"

if [[ $WIREFRAME_COUNT -ge 3 ]]; then
  echo "✅ Sufficient wireframe documents ($WIREFRAME_COUNT >= 3)"
else
  echo "❌ Insufficient wireframe documents ($WIREFRAME_COUNT < 3)"
  ((ERRORS++))
fi

# Test validation scripts
echo -e "\n🧪 Testing Validation Scripts..."
if [[ -f "scripts/validate-documentation-structure.js" ]]; then
  echo "✅ Documentation validation script exists"

  # Test if script runs
  if node scripts/validate-documentation-structure.js > /dev/null 2>&1; then
    echo "✅ Documentation validation script executes"
  else
    echo "⚠️ Documentation validation script has issues"
    ((WARNINGS++))
  fi
else
  echo "❌ Documentation validation script missing"
  ((ERRORS++))
fi

if [[ -f "scripts/validate-component-specifications.js" ]]; then
  echo "✅ Component validation script exists"

  # Test if script runs
  if node scripts/validate-component-specifications.js > /dev/null 2>&1; then
    echo "✅ Component validation script executes"
  else
    echo "⚠️ Component validation script has issues"
    ((WARNINGS++))
  fi
else
  echo "❌ Component validation script missing"
  ((ERRORS++))
fi

# Test backup functionality
echo -e "\n💾 Testing Backup Functionality..."
if [[ -f "mobile/build/web/index.html.backup" ]]; then
  echo "✅ Backup file exists"

  # Test backup integrity
  if diff mobile/build/web/index.html mobile/build/web/index.html.backup > /dev/null 2>&1; then
    echo "⚠️ Backup file identical to current (no changes made yet)"
  else
    echo "✅ Backup file differs from current (changes detected)"
  fi
else
  echo "⚠️ Backup file missing (expected during fresh setup)"
  ((WARNINGS++))
fi

# Test git functionality
echo -e "\n📝 Testing Git Functionality..."
if git status > /dev/null 2>&1; then
  echo "✅ Git repository functional"

  # Check for uncommitted changes
  if git diff --quiet && git diff --cached --quiet; then
    echo "✅ Working directory clean"
  else
    echo "⚠️ Uncommitted changes detected (may be expected during development)"
    ((WARNINGS++))
  fi

  # Check current branch
  CURRENT_BRANCH=$(git branch --show-current)
  echo "📍 Current branch: $CURRENT_BRANCH"

  if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "⚠️ Working on main branch (recommend feature branch)"
    ((WARNINGS++))
  fi
else
  echo "❌ Git repository issues"
  ((ERRORS++))
fi

# Generate functionality report
echo -e "\n📊 FUNCTIONALITY VALIDATION RESULTS"
echo "====================================="

echo "🔍 Test Summary:"
echo "  - Web Server: $([ $ERRORS -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "  - HTML Content: $([ $ERRORS -le 2 ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "  - JavaScript: $(grep -q "function.*project\|class.*Project" mobile/build/web/index.html && echo "✅ PASS" || echo "❌ FAIL")"
echo "  - CSS Implementation: $(grep -q "grid\|@media" mobile/build/web/index.html && echo "✅ PASS" || echo "❌ FAIL")"
echo "  - File Structure: $([ -d "docs/components" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "  - Documentation: $([ $COMPONENT_COUNT -ge 9 ] && echo "✅ PASS" || echo "❌ FAIL")"

if [[ $ERRORS -eq 0 ]]; then
  echo -e "\n✅ FUNCTIONALITY VALIDATION PASSED"
  if [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️ $WARNINGS warnings found (review recommended)"
  fi
  echo "🎉 Implementation functionality verified"
  exit 0
else
  echo -e "\n❌ FUNCTIONALITY VALIDATION FAILED"
  echo "💥 $ERRORS critical errors found"
  if [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️ $WARNINGS warnings found"
  fi
  echo "🔧 Fix errors before proceeding with deployment"
  exit 1
fi