#!/bin/bash
# validate-quickstart-performance.sh
# Validates the performance characteristics of quickstart implementation

echo "🔍 Validating Quickstart Implementation Performance"
echo "=================================================="

# Track validation results
ERRORS=0
WARNINGS=0
TEST_PORT=3002

# Function to cleanup processes
cleanup() {
  echo -e "\n🧹 Cleaning up test processes..."
  kill $SERVER_PID 2>/dev/null
  pkill -f "python3 -m http.server $TEST_PORT" 2>/dev/null
}

# Set cleanup trap
trap cleanup EXIT

# File size analysis
echo -e "\n📄 File Size Analysis..."

# Check main HTML file
if [[ -f "mobile/build/web/index.html" ]]; then
  HTML_SIZE_BYTES=$(stat -c%s mobile/build/web/index.html 2>/dev/null || stat -f%z mobile/build/web/index.html 2>/dev/null)
  HTML_SIZE_KB=$((HTML_SIZE_BYTES / 1024))
  HTML_SIZE_MB=$((HTML_SIZE_KB / 1024))

  echo "📄 Main HTML file: ${HTML_SIZE_KB}KB"

  if [[ $HTML_SIZE_BYTES -gt 3145728 ]]; then # 3MB
    echo "❌ HTML file too large (${HTML_SIZE_KB}KB > 3MB)"
    ((ERRORS++))
  elif [[ $HTML_SIZE_BYTES -gt 2097152 ]]; then # 2MB
    echo "⚠️ HTML file large (${HTML_SIZE_KB}KB > 2MB)"
    ((WARNINGS++))
  elif [[ $HTML_SIZE_BYTES -gt 1048576 ]]; then # 1MB
    echo "⚠️ HTML file moderate (${HTML_SIZE_KB}KB > 1MB)"
    ((WARNINGS++))
  else
    echo "✅ HTML file size acceptable (${HTML_SIZE_KB}KB)"
  fi
else
  echo "❌ Main HTML file not found"
  ((ERRORS++))
fi

# Check for large assets
echo -e "\n📦 Asset Size Analysis..."
cd mobile/build/web 2>/dev/null || {
  echo "❌ Cannot access web directory"
  ((ERRORS++))
  cd ../..
}

# Find large files
LARGE_FILES=$(find . -size +500k -type f 2>/dev/null | wc -l)
if [[ $LARGE_FILES -gt 0 ]]; then
  echo "⚠️ Found $LARGE_FILES files larger than 500KB:"
  find . -size +500k -type f -exec ls -lh {} \; 2>/dev/null | while read -r line; do
    echo "   $line"
  done
  ((WARNINGS++))
else
  echo "✅ No large assets found (all files < 500KB)"
fi

# Count total files
TOTAL_FILES=$(find . -type f | wc -l)
TOTAL_SIZE_KB=$(du -sk . 2>/dev/null | cut -f1)
echo "📊 Total files: $TOTAL_FILES"
echo "📊 Total size: ${TOTAL_SIZE_KB}KB"

if [[ $TOTAL_SIZE_KB -gt 10240 ]]; then # 10MB
  echo "⚠️ Total size large (${TOTAL_SIZE_KB}KB > 10MB)"
  ((WARNINGS++))
else
  echo "✅ Total size acceptable (${TOTAL_SIZE_KB}KB)"
fi

cd ../../.. # Return to project root

# Network performance testing
echo -e "\n🌐 Network Performance Testing..."

# Start test server
echo "🚀 Starting test server for performance testing..."
cd mobile/build/web
python3 -m http.server $TEST_PORT > /dev/null 2>&1 &
SERVER_PID=$!
sleep 3

# Test initial load time
echo "⏱️ Testing initial load time..."
LOAD_START=$(date +%s%N)
if curl -s http://localhost:$TEST_PORT > /dev/null; then
  LOAD_END=$(date +%s%N)
  LOAD_TIME_MS=$(( (LOAD_END - LOAD_START) / 1000000 ))

  echo "📊 Load time: ${LOAD_TIME_MS}ms"

  if [[ $LOAD_TIME_MS -gt 5000 ]]; then # 5 seconds
    echo "❌ Load time too slow (${LOAD_TIME_MS}ms > 5000ms)"
    ((ERRORS++))
  elif [[ $LOAD_TIME_MS -gt 2000 ]]; then # 2 seconds
    echo "⚠️ Load time slow (${LOAD_TIME_MS}ms > 2000ms)"
    ((WARNINGS++))
  else
    echo "✅ Load time acceptable (${LOAD_TIME_MS}ms)"
  fi
else
  echo "❌ Failed to measure load time"
  ((ERRORS++))
fi

# Test multiple requests (simulate user interaction)
echo -e "\n🔄 Testing Multiple Request Performance..."
TOTAL_TIME=0
REQUEST_COUNT=5

for i in $(seq 1 $REQUEST_COUNT); do
  REQUEST_START=$(date +%s%N)
  curl -s http://localhost:$TEST_PORT > /dev/null
  REQUEST_END=$(date +%s%N)
  REQUEST_TIME=$(( (REQUEST_END - REQUEST_START) / 1000000 ))
  TOTAL_TIME=$((TOTAL_TIME + REQUEST_TIME))
done

AVERAGE_TIME=$((TOTAL_TIME / REQUEST_COUNT))
echo "📊 Average request time: ${AVERAGE_TIME}ms ($REQUEST_COUNT requests)"

if [[ $AVERAGE_TIME -gt 1000 ]]; then # 1 second
  echo "❌ Average request time too slow (${AVERAGE_TIME}ms > 1000ms)"
  ((ERRORS++))
elif [[ $AVERAGE_TIME -gt 500 ]]; then # 500ms
  echo "⚠️ Average request time slow (${AVERAGE_TIME}ms > 500ms)"
  ((WARNINGS++))
else
  echo "✅ Average request time acceptable (${AVERAGE_TIME}ms)"
fi

cd ../../.. # Return to project root

# Memory usage estimation
echo -e "\n🧠 Memory Usage Analysis..."

# Estimate JavaScript memory usage
JS_SIZE=0
if grep -q "<script>" mobile/build/web/index.html; then
  # Extract inline JavaScript size
  JS_CONTENT=$(sed -n '/<script>/,/<\/script>/p' mobile/build/web/index.html)
  JS_SIZE=$(echo "$JS_CONTENT" | wc -c)
  JS_SIZE_KB=$((JS_SIZE / 1024))

  echo "📊 Estimated JavaScript size: ${JS_SIZE_KB}KB"

  if [[ $JS_SIZE -gt 1048576 ]]; then # 1MB
    echo "⚠️ JavaScript size large (${JS_SIZE_KB}KB > 1MB)"
    ((WARNINGS++))
  else
    echo "✅ JavaScript size acceptable (${JS_SIZE_KB}KB)"
  fi
fi

# Estimate CSS memory usage
CSS_SIZE=0
if grep -q "<style>" mobile/build/web/index.html; then
  # Extract inline CSS size
  CSS_CONTENT=$(sed -n '/<style>/,/<\/style>/p' mobile/build/web/index.html)
  CSS_SIZE=$(echo "$CSS_CONTENT" | wc -c)
  CSS_SIZE_KB=$((CSS_SIZE / 1024))

  echo "📊 Estimated CSS size: ${CSS_SIZE_KB}KB"

  if [[ $CSS_SIZE -gt 524288 ]]; then # 512KB
    echo "⚠️ CSS size large (${CSS_SIZE_KB}KB > 512KB)"
    ((WARNINGS++))
  else
    echo "✅ CSS size acceptable (${CSS_SIZE_KB}KB)"
  fi
fi

# Code complexity analysis
echo -e "\n🔍 Code Complexity Analysis..."

# Count JavaScript functions
FUNCTION_COUNT=$(grep -c "function\|=>" mobile/build/web/index.html)
echo "📊 JavaScript functions: $FUNCTION_COUNT"

if [[ $FUNCTION_COUNT -gt 100 ]]; then
  echo "⚠️ High function count (${FUNCTION_COUNT} > 100)"
  ((WARNINGS++))
else
  echo "✅ Function count acceptable ($FUNCTION_COUNT)"
fi

# Count CSS rules (approximate)
CSS_RULE_COUNT=$(grep -c "{" mobile/build/web/index.html)
echo "📊 CSS rules (approx): $CSS_RULE_COUNT"

if [[ $CSS_RULE_COUNT -gt 500 ]]; then
  echo "⚠️ High CSS rule count (${CSS_RULE_COUNT} > 500)"
  ((WARNINGS++))
else
  echo "✅ CSS rule count acceptable ($CSS_RULE_COUNT)"
fi

# Check for performance anti-patterns
echo -e "\n⚠️ Performance Anti-Pattern Analysis..."

# Check for blocking operations
if grep -q "alert\|confirm\|prompt" mobile/build/web/index.html; then
  echo "⚠️ Blocking dialog operations found"
  ((WARNINGS++))
else
  echo "✅ No blocking dialog operations"
fi

# Check for synchronous AJAX
if grep -q "async.*false\|XMLHttpRequest.*false" mobile/build/web/index.html; then
  echo "⚠️ Synchronous AJAX operations found"
  ((WARNINGS++))
else
  echo "✅ No synchronous AJAX operations detected"
fi

# Check for excessive DOM queries
QUERYSELECTOR_COUNT=$(grep -c "querySelector\|getElementById" mobile/build/web/index.html)
echo "📊 DOM query operations: $QUERYSELECTOR_COUNT"

if [[ $QUERYSELECTOR_COUNT -gt 50 ]]; then
  echo "⚠️ High DOM query count (${QUERYSELECTOR_COUNT} > 50)"
  ((WARNINGS++))
else
  echo "✅ DOM query count acceptable ($QUERYSELECTOR_COUNT)"
fi

# Check for heavy calculations in loops
if grep -q "for.*for\|while.*while" mobile/build/web/index.html; then
  echo "⚠️ Nested loops detected (may impact performance)"
  ((WARNINGS++))
else
  echo "✅ No nested loops detected"
fi

# Resource optimization check
echo -e "\n🔧 Resource Optimization Analysis..."

# Check for minification opportunities
WHITESPACE_RATIO=$(grep -c "^[[:space:]]*$" mobile/build/web/index.html)
TOTAL_LINES=$(wc -l < mobile/build/web/index.html)
WHITESPACE_PERCENT=$((WHITESPACE_RATIO * 100 / TOTAL_LINES))

echo "📊 Whitespace lines: $WHITESPACE_RATIO/$TOTAL_LINES (${WHITESPACE_PERCENT}%)"

if [[ $WHITESPACE_PERCENT -gt 20 ]]; then
  echo "⚠️ High whitespace ratio (${WHITESPACE_PERCENT}% > 20%)"
  echo "💡 Consider minification for production"
  ((WARNINGS++))
else
  echo "✅ Whitespace ratio acceptable (${WHITESPACE_PERCENT}%)"
fi

# Check for external dependencies
EXTERNAL_DEPS=$(grep -c "http.*://" mobile/build/web/index.html)
echo "📊 External dependencies: $EXTERNAL_DEPS"

if [[ $EXTERNAL_DEPS -gt 5 ]]; then
  echo "⚠️ Many external dependencies (${EXTERNAL_DEPS} > 5)"
  ((WARNINGS++))
else
  echo "✅ External dependencies acceptable ($EXTERNAL_DEPS)"
fi

# Mobile performance considerations
echo -e "\n📱 Mobile Performance Analysis..."

# Check for touch event handling
if grep -q "touch\|Touch" mobile/build/web/index.html; then
  echo "✅ Touch event handling detected"
else
  echo "⚠️ No touch event handling detected"
  ((WARNINGS++))
fi

# Check for viewport meta tag
if grep -q "viewport" mobile/build/web/index.html; then
  echo "✅ Viewport meta tag present"
else
  echo "❌ Viewport meta tag missing"
  ((ERRORS++))
fi

# Check for responsive design
if grep -q "@media" mobile/build/web/index.html; then
  echo "✅ Responsive design CSS present"
else
  echo "❌ Responsive design CSS missing"
  ((ERRORS++))
fi

# Generate performance score
echo -e "\n🏆 Performance Score Calculation..."

# Calculate performance score (100 - penalties)
PERFORMANCE_SCORE=100
PERFORMANCE_SCORE=$((PERFORMANCE_SCORE - ERRORS * 20))
PERFORMANCE_SCORE=$((PERFORMANCE_SCORE - WARNINGS * 5))

# Ensure score doesn't go below 0
if [[ $PERFORMANCE_SCORE -lt 0 ]]; then
  PERFORMANCE_SCORE=0
fi

echo "📊 Performance Score: $PERFORMANCE_SCORE/100"

if [[ $PERFORMANCE_SCORE -ge 90 ]]; then
  echo "🏆 Excellent performance"
elif [[ $PERFORMANCE_SCORE -ge 80 ]]; then
  echo "🥇 Good performance"
elif [[ $PERFORMANCE_SCORE -ge 70 ]]; then
  echo "🥈 Acceptable performance"
elif [[ $PERFORMANCE_SCORE -ge 60 ]]; then
  echo "🥉 Fair performance (optimization recommended)"
else
  echo "🔴 Poor performance (optimization required)"
fi

# Final results
echo -e "\n📊 PERFORMANCE VALIDATION RESULTS"
echo "=================================="

echo "📈 Performance Summary:"
echo "  - File Size: $([ $HTML_SIZE_KB -lt 2048 ] && echo "✅ GOOD" || echo "⚠️ REVIEW")"
echo "  - Load Time: $([ ${LOAD_TIME_MS:-0} -lt 2000 ] && echo "✅ GOOD" || echo "⚠️ REVIEW")"
echo "  - Memory Usage: $([ ${JS_SIZE_KB:-0} -lt 1024 ] && echo "✅ GOOD" || echo "⚠️ REVIEW")"
echo "  - Code Quality: $([ $FUNCTION_COUNT -lt 100 ] && echo "✅ GOOD" || echo "⚠️ REVIEW")"
echo "  - Mobile Ready: $(grep -q "viewport.*@media" mobile/build/web/index.html && echo "✅ GOOD" || echo "❌ NEEDS WORK")"

if [[ $ERRORS -eq 0 ]] && [[ $PERFORMANCE_SCORE -ge 70 ]]; then
  echo -e "\n✅ PERFORMANCE VALIDATION PASSED"
  echo "🎯 Performance Score: $PERFORMANCE_SCORE/100"
  if [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️ $WARNINGS optimization opportunities identified"
  fi
  echo "🚀 Ready for production deployment"
  exit 0
else
  echo -e "\n❌ PERFORMANCE VALIDATION FAILED"
  echo "💥 $ERRORS critical performance issues found"
  echo "🎯 Performance Score: $PERFORMANCE_SCORE/100"
  if [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️ $WARNINGS additional optimization opportunities"
  fi
  echo "🔧 Address performance issues before deployment"
  exit 1
fi