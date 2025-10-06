# Component Validation Contract

## Purpose
This contract defines validation rules and test criteria for UI component specifications to ensure implementation readiness and constitutional compliance.

## Component Specification Validation

### Required Component Metadata
```markdown
Every component specification MUST include:
- component_name: Unique PascalCase identifier
- component_type: [navigation|content|interaction|display]
- complexity_level: [simple|moderate|complex]
- dependencies: List of required services/components
- estimated_implementation_time: Hours for development
```

**Validation Script Pattern**:
```bash
# Test that component name follows PascalCase convention
if ! [[ "$component_name" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
  echo "FAIL: Component name must be PascalCase"
  exit 1
fi

# Test that component type is valid
valid_types=("navigation" "content" "interaction" "display")
if [[ ! " ${valid_types[@]} " =~ " ${component_type} " ]]; then
  echo "FAIL: Invalid component type"
  exit 1
fi
```

### Props/Inputs Validation Contract
```markdown
Each component prop MUST specify:
| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| [name] | [string|number|boolean|object|array] | [true|false] | [value|null] | [rules] | [purpose] |
```

**Validation Rules**:
- Property names must be camelCase
- Type must be one of: string, number, boolean, object, array
- Required props cannot have default values
- Validation rules must be testable (regex, range, enum)
- Description must explain business purpose

**Test Pattern**:
```javascript
// Example prop validation test
const propValidation = {
  projectId: {
    type: 'string',
    required: true,
    validation: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
    description: 'UUID of the project this component displays'
  }
};

function validateProp(propName, value, spec) {
  if (spec.required && (value === undefined || value === null)) {
    throw new Error(`Required prop ${propName} is missing`);
  }
  if (value !== undefined && typeof value !== spec.type) {
    throw new Error(`Prop ${propName} must be of type ${spec.type}`);
  }
  if (spec.validation && !spec.validation.test(value)) {
    throw new Error(`Prop ${propName} fails validation`);
  }
}
```

### Visual State Validation Contract
```markdown
Interactive components MUST document these states:
- default: Normal appearance
- hover: Mouse over appearance
- active: Currently pressed/selected
- focus: Keyboard focus appearance
- disabled: Non-interactive appearance
- loading: Processing/waiting appearance (if applicable)

Display components MUST document these states:
- default: Normal appearance
- empty: No data to display
- error: Error condition appearance
- loading: Data fetching appearance
```

**State Transition Validation**:
```markdown
State transitions MUST be documented:
- Which user actions trigger state changes
- Which system events cause state changes
- Whether states can be combined (e.g., focus + hover)
- Animation duration and easing for transitions
```

### Accessibility Validation Contract
```markdown
ALL components MUST specify:

Keyboard Navigation:
- Tab order: Where component appears in tab sequence
- Enter behavior: What happens when Enter is pressed
- Arrow key behavior: Navigation within component (if applicable)
- Escape behavior: How to exit component focus

Screen Reader Support:
- aria-label: Descriptive label for component purpose
- aria-role: Semantic role (button, listbox, etc.)
- aria-state: Dynamic state announcements
- Live regions: For dynamic content updates

Focus Management:
- Focus indicator: Visual indication of keyboard focus
- Focus trapping: For modal-like components
- Focus restoration: Where focus goes after component interaction
```

**Accessibility Test Pattern**:
```javascript
// Keyboard navigation test
function testKeyboardNavigation(component) {
  // Tab to component
  fireEvent.keyDown(document, { key: 'Tab' });
  expect(component).toHaveFocus();

  // Test Enter key
  fireEvent.keyDown(component, { key: 'Enter' });
  expect(onEnterCallback).toHaveBeenCalled();

  // Test Escape key
  fireEvent.keyDown(component, { key: 'Escape' });
  expect(component).not.toHaveFocus();
}

// Screen reader test
function testScreenReader(component) {
  expect(component).toHaveAttribute('aria-label');
  expect(component).toHaveAttribute('role');
  // Additional assertions for dynamic states
}
```

### Responsive Behavior Validation Contract
```markdown
Each component MUST specify behavior at:
- Mobile (<768px): Layout, interaction changes
- Tablet (768-1024px): Layout adaptations
- Desktop (>1024px): Full feature display

Required responsive documentation:
- Breakpoint behavior: How component changes at each breakpoint
- Touch interactions: Mobile-specific gestures (if applicable)
- Space constraints: How component adapts to limited space
- Performance impact: Loading/rendering differences by device
```

**Responsive Validation Test**:
```css
/* Test component responsive behavior */
@media (max-width: 767px) {
  .component-mobile-test {
    /* Mobile styles that should be applied */
  }
}

@media (min-width: 768px) and (max-width: 1024px) {
  .component-tablet-test {
    /* Tablet styles that should be applied */
  }
}

@media (min-width: 1025px) {
  .component-desktop-test {
    /* Desktop styles that should be applied */
  }
}
```

## Integration Validation Contract

### Data Binding Validation
```markdown
Components that display backend data MUST specify:
- API endpoint: Which backend endpoint provides data
- Data transformation: How API response maps to component props
- Error handling: What displays when API fails
- Loading state: What displays while fetching data
- Cache strategy: When to refetch vs use cached data
```

**Data Binding Test Pattern**:
```javascript
// Mock API response test
function testDataBinding(component, apiResponse) {
  // Test successful data loading
  mockApi.get('/v1/projects').mockResolvedValue(apiResponse);
  render(component);

  expect(screen.getByText('Loading...')).toBeInTheDocument();

  await waitFor(() => {
    expect(screen.getByText(apiResponse.data[0].name)).toBeInTheDocument();
  });

  // Test error handling
  mockApi.get('/v1/projects').mockRejectedValue(new Error('API Error'));
  render(component);

  await waitFor(() => {
    expect(screen.getByText('Error loading projects')).toBeInTheDocument();
  });
}
```

### Performance Validation Contract
```markdown
Each component MUST specify:
- Render time target: Maximum time from props to display
- Memory usage: Estimated memory footprint
- Re-render triggers: Which prop changes cause re-render
- Optimization strategy: Memoization, virtualization, etc.
```

**Performance Test Pattern**:
```javascript
// Performance benchmark test
function testComponentPerformance(component) {
  const startTime = performance.now();

  render(component);

  const renderTime = performance.now() - startTime;
  expect(renderTime).toBeLessThan(100); // 100ms render target

  // Memory usage test
  const initialMemory = performance.memory.usedJSHeapSize;
  unmount(component);
  const finalMemory = performance.memory.usedJSHeapSize;

  expect(finalMemory - initialMemory).toBeLessThan(1024 * 1024); // 1MB max
}
```

## Validation Automation

### Contract Test Generation
```bash
#!/bin/bash
# Auto-generate validation tests from component specs

for component_spec in docs/components/*.md; do
  component_name=$(basename "$component_spec" .md)

  # Generate prop validation test
  generate_prop_tests "$component_spec" > "tests/contract/${component_name}_props.test.js"

  # Generate accessibility test
  generate_a11y_tests "$component_spec" > "tests/contract/${component_name}_a11y.test.js"

  # Generate responsive test
  generate_responsive_tests "$component_spec" > "tests/contract/${component_name}_responsive.test.js"
done
```

### Continuous Validation
```yaml
# GitHub Actions workflow for contract validation
name: Component Contract Validation
on: [push, pull_request]

jobs:
  validate-contracts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate component specifications
        run: |
          # Check all components have required sections
          ./scripts/validate-component-specs.sh

      - name: Run contract tests
        run: |
          npm test -- --testPathPattern=contract

      - name: Validate accessibility requirements
        run: |
          npm run test:a11y
```

This validation contract ensures all component specifications are complete, testable, and ready for implementation while maintaining constitutional compliance.