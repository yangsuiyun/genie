#!/usr/bin/env node

/**
 * Documentation Structure Validation Script
 * Based on contracts/documentation-structure.md
 *
 * This script validates that design documentation follows the required structure
 * and content standards. Expected to FAIL initially (TDD approach).
 */

const fs = require('fs');
const path = require('path');

class DocumentationValidator {
    constructor() {
        this.errors = [];
        this.warnings = [];
    }

    /**
     * Validate a design document against structure contract
     */
    validateDocument(filePath) {
        console.log(`\n🔍 Validating: ${filePath}`);

        if (!fs.existsSync(filePath)) {
            this.addError(`Document does not exist: ${filePath}`);
            return false;
        }

        const content = fs.readFileSync(filePath, 'utf8');
        const lines = content.split('\n');

        // Validate required sections
        this.validateDesignOverview(content, filePath);
        this.validateComponentSpecifications(content, filePath);
        this.validateInteractionFlows(content, filePath);
        this.validateIntegrationPoints(content, filePath);

        return this.errors.length === 0;
    }

    /**
     * Validate Design Overview Section
     */
    validateDesignOverview(content, filePath) {
        const requiredSections = [
            '## 🎯 Design Goals',
            '## 🏗️ Architecture Overview',
            '## 📱 Responsive Strategy'
        ];

        for (const section of requiredSections) {
            if (!content.includes(section)) {
                this.addError(`Missing required section: ${section} in ${filePath}`);
            }
        }

        // Validate responsive breakpoints
        const breakpoints = ['<768px', '768-1024px', '>1024px'];
        let breakpointCount = 0;
        for (const bp of breakpoints) {
            if (content.includes(bp)) breakpointCount++;
        }

        if (breakpointCount < 3) {
            this.addError(`Must specify exactly 3 responsive breakpoints in ${filePath}`);
        }
    }

    /**
     * Validate Component Specifications
     */
    validateComponentSpecifications(content, filePath) {
        const componentSections = content.match(/## \w+Component/g) || [];

        for (const section of componentSections) {
            const componentName = section.replace('## ', '').replace('Component', '');

            // Check required subsections
            const requiredSubsections = [
                '### Purpose',
                '### Props/Inputs',
                '### Visual States',
                '### Accessibility',
                '### Responsive Behavior',
                '### Wireframe'
            ];

            for (const subsection of requiredSubsections) {
                if (!content.includes(subsection)) {
                    this.addError(`Component ${componentName} missing: ${subsection} in ${filePath}`);
                }
            }

            // Validate visual states
            const requiredStates = ['Default', 'Hover', 'Active', 'Disabled'];
            for (const state of requiredStates) {
                if (!content.includes(`**${state}**`)) {
                    this.addWarning(`Component ${componentName} missing visual state: ${state} in ${filePath}`);
                }
            }

            // Validate keyboard navigation
            if (!content.includes('Keyboard Navigation') && !content.includes('keyboard navigation')) {
                this.addError(`Component ${componentName} missing keyboard navigation spec in ${filePath}`);
            }
        }
    }

    /**
     * Validate Interaction Flows
     */
    validateInteractionFlows(content, filePath) {
        const flowSections = content.match(/## \w+.*Flow/g) || [];

        for (const section of flowSections) {
            const flowName = section.replace('## ', '');

            const requiredSubsections = [
                '### Trigger Conditions',
                '### Success Path',
                '### Error Paths',
                '### Performance Requirements',
                '### Accessibility Flow'
            ];

            for (const subsection of requiredSubsections) {
                if (!content.includes(subsection)) {
                    this.addError(`Flow ${flowName} missing: ${subsection} in ${filePath}`);
                }
            }

            // Validate success path has steps
            const successMatch = content.match(/### Success Path([\s\S]*?)###/);
            if (successMatch) {
                const steps = (successMatch[1].match(/\d+\./g) || []).length;
                if (steps < 3) {
                    this.addError(`Flow ${flowName} success path must have at least 3 steps in ${filePath}`);
                }
            }
        }
    }

    /**
     * Validate Integration Points
     */
    validateIntegrationPoints(content, filePath) {
        if (content.includes('## Backend Integration')) {
            const requiredSubsections = [
                '### API Endpoints Used',
                '### Data Flow',
                '### Error Handling',
                '### Offline Behavior'
            ];

            for (const subsection of requiredSubsections) {
                if (!content.includes(subsection)) {
                    this.addError(`Backend Integration missing: ${subsection} in ${filePath}`);
                }
            }
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
        console.log('\n📋 VALIDATION RESULTS');
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
            console.log('\n✅ All validations passed!');
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
    const validator = new DocumentationValidator();

    // Files to validate
    const documentsToValidate = [
        'docs/frontend-project-architecture.md',
        'docs/frontend-design.md'
    ];

    console.log('🔍 Documentation Structure Validation');
    console.log('Based on contracts/documentation-structure.md');
    console.log('Expected to FAIL initially (TDD approach)\n');

    let allValid = true;
    for (const doc of documentsToValidate) {
        const isValid = validator.validateDocument(doc);
        allValid = allValid && isValid;
    }

    const success = validator.printResults();

    if (!success) {
        console.log('\n💡 TDD Status: FAILING AS EXPECTED');
        console.log('   Next steps: Create documentation to pass these tests');
        process.exit(1);
    } else {
        console.log('\n✅ TDD Status: PASSING - Documentation complete!');
        process.exit(0);
    }
}

if (require.main === module) {
    main();
}

module.exports = DocumentationValidator;