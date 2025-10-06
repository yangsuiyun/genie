#!/usr/bin/env node

/**
 * Component Specification Validation Script
 * Based on contracts/component-validation.md
 *
 * This script validates that UI component specifications follow the required
 * format and completeness standards. Expected to FAIL initially (TDD approach).
 */

const fs = require('fs');
const path = require('path');

class ComponentValidator {
    constructor() {
        this.errors = [];
        this.warnings = [];
    }

    /**
     * Validate all component specifications in docs/components/
     */
    validateAllComponents() {
        const componentsDir = 'docs/components';

        if (!fs.existsSync(componentsDir)) {
            this.addError(`Components directory does not exist: ${componentsDir}`);
            return false;
        }

        const files = fs.readdirSync(componentsDir)
            .filter(file => file.endsWith('.md') && file !== 'component-template.md');

        if (files.length === 0) {
            this.addError('No component specification files found in docs/components/');
            return false;
        }

        console.log(`Found ${files.length} component specifications to validate:`);
        files.forEach(file => console.log(`  - ${file}`));

        let allValid = true;
        for (const file of files) {
            const filePath = path.join(componentsDir, file);
            const isValid = this.validateComponent(filePath);
            allValid = allValid && isValid;
        }

        return allValid;
    }

    /**
     * Validate individual component specification
     */
    validateComponent(filePath) {
        console.log(`\n🔍 Validating component: ${filePath}`);

        const content = fs.readFileSync(filePath, 'utf8');
        const componentName = path.basename(filePath, '.md');

        // Validate component metadata
        this.validateComponentMetadata(content, componentName, filePath);

        // Validate props/inputs
        this.validatePropsInputs(content, componentName, filePath);

        // Validate visual states
        this.validateVisualStates(content, componentName, filePath);

        // Validate accessibility requirements
        this.validateAccessibility(content, componentName, filePath);

        // Validate responsive behavior
        this.validateResponsiveBehavior(content, componentName, filePath);

        // Validate integration points
        this.validateIntegration(content, componentName, filePath);

        return this.errors.length === 0;
    }

    /**
     * Validate component metadata
     */
    validateComponentMetadata(content, componentName, filePath) {
        // Check component name follows PascalCase
        const expectedName = componentName.split('-')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join('');

        if (!content.includes(expectedName)) {
            this.addError(`Component name should be PascalCase: ${expectedName} in ${filePath}`);
        }

        // Required metadata fields
        const requiredFields = [
            'component_name',
            'component_type',
            'complexity_level',
            'dependencies',
            'estimated_implementation_time'
        ];

        // Check if metadata section exists
        if (!content.includes('## Component Metadata') && !content.includes('## Purpose')) {
            this.addError(`Missing component metadata section in ${filePath}`);
        }

        // Validate component type
        const validTypes = ['navigation', 'content', 'interaction', 'display'];
        let hasValidType = false;
        for (const type of validTypes) {
            if (content.toLowerCase().includes(type)) {
                hasValidType = true;
                break;
            }
        }
        if (!hasValidType) {
            this.addError(`Component must specify type (navigation/content/interaction/display) in ${filePath}`);
        }
    }

    /**
     * Validate props/inputs section
     */
    validatePropsInputs(content, componentName, filePath) {
        if (!content.includes('### Props/Inputs') && !content.includes('## Props/Inputs')) {
            this.addError(`Missing Props/Inputs section in ${filePath}`);
            return;
        }

        // Check for props table
        if (!content.includes('| Property |') && !content.includes('|prop|')) {
            this.addError(`Props/Inputs section missing table format in ${filePath}`);
        }

        // Validate required table columns
        const requiredColumns = ['Property', 'Type', 'Required', 'Default', 'Description'];
        for (const column of requiredColumns) {
            if (!content.includes(column)) {
                this.addWarning(`Props table missing ${column} column in ${filePath}`);
            }
        }

        // Check for valid prop types
        const validTypes = ['string', 'number', 'boolean', 'object', 'array'];
        let hasTypedProps = false;
        for (const type of validTypes) {
            if (content.includes(type)) {
                hasTypedProps = true;
                break;
            }
        }
        if (!hasTypedProps) {
            this.addWarning(`Props should specify types (string/number/boolean/object/array) in ${filePath}`);
        }
    }

    /**
     * Validate visual states
     */
    validateVisualStates(content, componentName, filePath) {
        if (!content.includes('### Visual States') && !content.includes('## Visual States')) {
            this.addError(`Missing Visual States section in ${filePath}`);
            return;
        }

        // Required states for interactive components
        const requiredInteractiveStates = ['default', 'hover', 'active', 'focus', 'disabled'];
        // Required states for display components
        const requiredDisplayStates = ['default', 'empty', 'error', 'loading'];

        // Check if component is interactive (has buttons, inputs, etc.)
        const isInteractive = content.toLowerCase().includes('button') ||
                             content.toLowerCase().includes('input') ||
                             content.toLowerCase().includes('click') ||
                             content.toLowerCase().includes('interaction');

        const requiredStates = isInteractive ? requiredInteractiveStates : requiredDisplayStates;

        for (const state of requiredStates) {
            if (!content.toLowerCase().includes(state)) {
                this.addError(`Missing visual state: ${state} in ${filePath}`);
            }
        }

        // Check for state transition documentation
        if (isInteractive && !content.includes('transition')) {
            this.addWarning(`Interactive component should document state transitions in ${filePath}`);
        }
    }

    /**
     * Validate accessibility requirements
     */
    validateAccessibility(content, componentName, filePath) {
        if (!content.includes('### Accessibility') && !content.includes('## Accessibility')) {
            this.addError(`Missing Accessibility section in ${filePath}`);
            return;
        }

        // Required accessibility elements
        const requiredA11y = [
            'Keyboard Navigation',
            'Screen Reader',
            'Focus Management'
        ];

        for (const requirement of requiredA11y) {
            if (!content.includes(requirement)) {
                this.addError(`Missing accessibility requirement: ${requirement} in ${filePath}`);
            }
        }

        // Check for ARIA attributes
        const ariaAttributes = ['aria-label', 'aria-role', 'aria-state'];
        let hasAria = false;
        for (const attr of ariaAttributes) {
            if (content.includes(attr)) {
                hasAria = true;
                break;
            }
        }
        if (!hasAria) {
            this.addWarning(`Should specify ARIA attributes for accessibility in ${filePath}`);
        }

        // Check for keyboard navigation details
        if (!content.includes('Tab') && !content.includes('Enter') && !content.includes('Escape')) {
            this.addWarning(`Should specify keyboard interactions (Tab, Enter, Escape) in ${filePath}`);
        }
    }

    /**
     * Validate responsive behavior
     */
    validateResponsiveBehavior(content, componentName, filePath) {
        if (!content.includes('### Responsive Behavior') && !content.includes('## Responsive')) {
            this.addError(`Missing Responsive Behavior section in ${filePath}`);
            return;
        }

        // Required breakpoints
        const requiredBreakpoints = ['<768px', '768-1024px', '>1024px'];
        for (const breakpoint of requiredBreakpoints) {
            if (!content.includes(breakpoint)) {
                this.addError(`Missing responsive breakpoint: ${breakpoint} in ${filePath}`);
            }
        }

        // Check for responsive behavior description
        const responsiveBehaviors = ['Layout', 'Touch', 'Space', 'Performance'];
        for (const behavior of responsiveBehaviors) {
            if (!content.includes(behavior)) {
                this.addWarning(`Should describe ${behavior} responsive behavior in ${filePath}`);
            }
        }
    }

    /**
     * Validate integration points
     */
    validateIntegration(content, componentName, filePath) {
        // Check for data binding if component displays backend data
        if (content.includes('backend') || content.includes('API') || content.includes('data')) {
            const requiredIntegration = [
                'API endpoint',
                'Data transformation',
                'Error handling',
                'Loading state'
            ];

            for (const requirement of requiredIntegration) {
                if (!content.toLowerCase().includes(requirement.toLowerCase())) {
                    this.addWarning(`Should specify ${requirement} for data integration in ${filePath}`);
                }
            }
        }

        // Check for performance requirements
        if (!content.includes('performance') && !content.includes('Performance')) {
            this.addWarning(`Should specify performance requirements in ${filePath}`);
        }
    }

    /**
     * Add validation error
     */
    addError(message) {
        this.errors.push(`❌ ERROR: ${message}`);
    }

    /**
     * Add validation warning
     */
    addWarning(message) {
        this.warnings.push(`⚠️  WARNING: ${message}`);
    }

    /**
     * Print validation results
     */
    printResults() {
        console.log('\n📋 COMPONENT VALIDATION RESULTS');
        console.log('='.repeat(50));

        if (this.errors.length > 0) {
            console.log('\n❌ ERRORS:');
            this.errors.forEach(error => console.log(error));
        }

        if (this.warnings.length > 0) {
            console.log('\n⚠️  WARNINGS:');
            this.warnings.forEach(warning => console.log(warning));
        }

        if (this.errors.length === 0 && this.warnings.length === 0) {
            console.log('\n✅ All component validations passed!');
            return true;
        }

        console.log(`\n📊 Summary: ${this.errors.length} errors, ${this.warnings.length} warnings`);
        return false;
    }
}

/**
 * Main execution
 */
function main() {
    const validator = new ComponentValidator();

    console.log('🔍 Component Specification Validation');
    console.log('Based on contracts/component-validation.md');
    console.log('Expected to FAIL initially (TDD approach)\n');

    const allValid = validator.validateAllComponents();
    const success = validator.printResults();

    if (!success) {
        console.log('\n💡 TDD Status: FAILING AS EXPECTED');
        console.log('   Next steps: Create component specifications to pass these tests');
        process.exit(1);
    } else {
        console.log('\n✅ TDD Status: PASSING - Component specifications complete!');
        process.exit(0);
    }
}

if (require.main === module) {
    main();
}

module.exports = ComponentValidator;