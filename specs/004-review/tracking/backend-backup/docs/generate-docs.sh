#!/bin/bash

# Pomodoro Genie API Documentation Generator
# Generates HTML documentation from OpenAPI specification

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWAGGER_FILE="$SCRIPT_DIR/swagger.yaml"
OUTPUT_DIR="$SCRIPT_DIR/generated"
HTML_FILE="$OUTPUT_DIR/index.html"
SERVE_PORT=8080

# Options
SERVE_DOCS=false
OPEN_BROWSER=false
GENERATOR="redoc"
VALIDATE_ONLY=false

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --serve             Serve documentation locally"
    echo "  --open              Open browser after generation"
    echo "  --generator TYPE    Documentation generator (redoc|swagger|both) [default: redoc]"
    echo "  --port PORT         Port for local server [default: 8080]"
    echo "  --validate-only     Only validate the OpenAPI spec"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Generate HTML documentation"
    echo "  $0 --serve --open   # Generate, serve, and open in browser"
    echo "  $0 --generator both # Generate both Redoc and Swagger UI"
    echo "  $0 --validate-only  # Only validate the spec"
}

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --serve)
            SERVE_DOCS=true
            shift
            ;;
        --open)
            OPEN_BROWSER=true
            shift
            ;;
        --generator)
            GENERATOR="$2"
            shift 2
            ;;
        --port)
            SERVE_PORT="$2"
            shift 2
            ;;
        --validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check if swagger file exists
    if [[ ! -f "$SWAGGER_FILE" ]]; then
        error "OpenAPI specification not found: $SWAGGER_FILE"
        exit 1
    fi

    # Check for Node.js and npm
    if ! command -v npm &> /dev/null; then
        error "npm is required but not installed. Please install Node.js and npm."
        exit 1
    fi

    # Check for required npm packages
    local missing_packages=()

    if [[ "$GENERATOR" == "redoc" || "$GENERATOR" == "both" ]]; then
        if ! npm list -g redoc-cli &> /dev/null; then
            missing_packages+=("redoc-cli")
        fi
    fi

    if [[ "$GENERATOR" == "swagger" || "$GENERATOR" == "both" ]]; then
        if ! npm list -g swagger-ui-serve &> /dev/null; then
            missing_packages+=("swagger-ui-serve")
        fi
    fi

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        warning "Missing required packages: ${missing_packages[*]}"
        log "Installing missing packages..."

        for package in "${missing_packages[@]}"; do
            if ! npm install -g "$package"; then
                error "Failed to install $package"
                exit 1
            fi
        done
    fi

    # Check for swagger-parser (optional, for validation)
    if ! npm list -g swagger-parser &> /dev/null; then
        warning "swagger-parser not found. Spec validation will be limited."
        log "To install: npm install -g swagger-parser"
    fi

    success "Prerequisites check passed"
}

# Validate OpenAPI specification
validate_spec() {
    log "Validating OpenAPI specification..."

    # Basic YAML syntax validation
    if command -v python3 &> /dev/null; then
        python3 -c "
import yaml
import sys
try:
    with open('$SWAGGER_FILE', 'r') as f:
        yaml.safe_load(f)
    print('✓ YAML syntax is valid')
except yaml.YAMLError as e:
    print(f'✗ YAML syntax error: {e}', file=sys.stderr)
    sys.exit(1)
"
    elif command -v python &> /dev/null; then
        python -c "
import yaml
import sys
try:
    with open('$SWAGGER_FILE', 'r') as f:
        yaml.safe_load(f)
    print('✓ YAML syntax is valid')
except yaml.YAMLError as e:
    print('✗ YAML syntax error: ' + str(e))
    sys.exit(1)
"
    else
        warning "Python not found. Skipping YAML validation."
    fi

    # OpenAPI specification validation (if swagger-parser is available)
    if npm list -g swagger-parser &> /dev/null; then
        log "Running OpenAPI specification validation..."
        if swagger-parser validate "$SWAGGER_FILE"; then
            success "OpenAPI specification is valid"
        else
            error "OpenAPI specification validation failed"
            exit 1
        fi
    else
        warning "swagger-parser not available. Skipping OpenAPI validation."
    fi

    # Check for common issues
    log "Checking for common specification issues..."

    # Check for required fields
    if ! grep -q "openapi:" "$SWAGGER_FILE"; then
        error "Missing 'openapi' field in specification"
        exit 1
    fi

    if ! grep -q "info:" "$SWAGGER_FILE"; then
        error "Missing 'info' section in specification"
        exit 1
    fi

    if ! grep -q "paths:" "$SWAGGER_FILE"; then
        error "Missing 'paths' section in specification"
        exit 1
    fi

    # Check for version
    local api_version=$(grep "version:" "$SWAGGER_FILE" | head -1 | awk '{print $2}' | tr -d '"')
    if [[ -n "$api_version" ]]; then
        log "API version: $api_version"
    else
        warning "API version not found or not specified"
    fi

    success "Specification validation completed"
}

# Setup output directory
setup_output_directory() {
    log "Setting up output directory..."

    mkdir -p "$OUTPUT_DIR"

    # Clean previous generated files
    rm -rf "${OUTPUT_DIR:?}"/*

    success "Output directory ready: $OUTPUT_DIR"
}

# Generate Redoc documentation
generate_redoc() {
    log "Generating Redoc documentation..."

    local redoc_output="$OUTPUT_DIR/redoc.html"

    if redoc-cli build "$SWAGGER_FILE" --output "$redoc_output" --title "Pomodoro Genie API Documentation"; then
        success "Redoc documentation generated: $redoc_output"

        # Create a symlink for index.html if this is the primary generator
        if [[ "$GENERATOR" == "redoc" ]]; then
            ln -sf "$(basename "$redoc_output")" "$HTML_FILE"
        fi

        return 0
    else
        error "Failed to generate Redoc documentation"
        return 1
    fi
}

# Generate Swagger UI documentation
generate_swagger_ui() {
    log "Generating Swagger UI documentation..."

    local swagger_output="$OUTPUT_DIR/swagger-ui"
    mkdir -p "$swagger_output"

    # Create a simple HTML file that loads Swagger UI
    cat > "$swagger_output/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Pomodoro Genie API - Swagger UI</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css" />
    <style>
        html {
            box-sizing: border-box;
            overflow: -moz-scrollbars-vertical;
            overflow-y: scroll;
        }
        *, *:before, *:after {
            box-sizing: inherit;
        }
        body {
            margin:0;
            background: #fafafa;
        }
    </style>
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
    <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-standalone-preset.js"></script>
    <script>
    window.onload = function() {
        const ui = SwaggerUIBundle({
            url: '../swagger.yaml',
            dom_id: '#swagger-ui',
            deepLinking: true,
            presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
            ],
            plugins: [
                SwaggerUIBundle.plugins.DownloadUrl
            ],
            layout: "StandaloneLayout"
        });
    };
    </script>
</body>
</html>
EOF

    # Copy the swagger spec to the output directory
    cp "$SWAGGER_FILE" "$OUTPUT_DIR/"

    success "Swagger UI documentation generated: $swagger_output/index.html"

    # Create a symlink for index.html if this is the primary generator
    if [[ "$GENERATOR" == "swagger" ]]; then
        ln -sf "swagger-ui/index.html" "$HTML_FILE"
    fi

    return 0
}

# Generate both documentations
generate_both() {
    log "Generating both Redoc and Swagger UI documentation..."

    local success_count=0

    if generate_redoc; then
        ((success_count++))
    fi

    if generate_swagger_ui; then
        ((success_count++))
    fi

    if [[ $success_count -gt 0 ]]; then
        # Create an index page that links to both
        cat > "$HTML_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pomodoro Genie API Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            margin-bottom: 3rem;
        }
        .logo {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }
        .description {
            color: #666;
            margin-bottom: 2rem;
        }
        .docs-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-top: 2rem;
        }
        .doc-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 2rem;
            text-align: center;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .doc-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .doc-card h2 {
            margin-top: 0;
            color: #333;
        }
        .doc-card p {
            color: #666;
            margin-bottom: 1.5rem;
        }
        .btn {
            display: inline-block;
            padding: 0.75rem 1.5rem;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            transition: background 0.2s;
        }
        .btn:hover {
            background: #0056b3;
        }
        .btn-secondary {
            background: #6c757d;
        }
        .btn-secondary:hover {
            background: #545b62;
        }
        .footer {
            margin-top: 3rem;
            text-align: center;
            color: #666;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">🍅 Pomodoro Genie API</div>
        <p class="description">
            Complete REST API documentation for the Pomodoro Genie task and time management application.
            Choose your preferred documentation format below.
        </p>
    </div>

    <div class="docs-grid">
        <div class="doc-card">
            <h2>Redoc Documentation</h2>
            <p>
                Clean, responsive documentation with a three-panel design.
                Great for browsing and understanding the API structure.
            </p>
            <a href="redoc.html" class="btn">View Redoc Docs</a>
        </div>

        <div class="doc-card">
            <h2>Swagger UI</h2>
            <p>
                Interactive documentation with a "try it out" feature.
                Perfect for testing API endpoints directly from the browser.
            </p>
            <a href="swagger-ui/index.html" class="btn btn-secondary">View Swagger UI</a>
        </div>
    </div>

    <div class="footer">
        <p>Generated from OpenAPI specification • Last updated: DATE_PLACEHOLDER</p>
    </div>
</body>
</html>
EOF

        # Replace date placeholder
        sed -i.bak "s/DATE_PLACEHOLDER/$(date)/" "$HTML_FILE" && rm "$HTML_FILE.bak"

        success "Combined documentation index generated: $HTML_FILE"
        return 0
    else
        error "Failed to generate any documentation"
        return 1
    fi
}

# Generate documentation based on selected generator
generate_documentation() {
    setup_output_directory

    case $GENERATOR in
        "redoc")
            generate_redoc
            ;;
        "swagger")
            generate_swagger_ui
            ;;
        "both")
            generate_both
            ;;
        *)
            error "Unknown generator: $GENERATOR"
            exit 1
            ;;
    esac
}

# Serve documentation locally
serve_documentation() {
    if [[ ! -f "$HTML_FILE" ]]; then
        error "No documentation found. Generate documentation first."
        exit 1
    fi

    log "Starting local server on port $SERVE_PORT..."

    # Check if port is available
    if lsof -Pi :$SERVE_PORT -sTCP:LISTEN -t >/dev/null; then
        warning "Port $SERVE_PORT is already in use"
        read -p "Use a different port? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SERVE_PORT=$((SERVE_PORT + 1))
            while lsof -Pi :$SERVE_PORT -sTCP:LISTEN -t >/dev/null; do
                SERVE_PORT=$((SERVE_PORT + 1))
            done
            log "Using port $SERVE_PORT instead"
        else
            exit 1
        fi
    fi

    # Start simple HTTP server
    if command -v python3 &> /dev/null; then
        cd "$OUTPUT_DIR"
        python3 -m http.server $SERVE_PORT &
        SERVER_PID=$!
    elif command -v python &> /dev/null; then
        cd "$OUTPUT_DIR"
        python -m SimpleHTTPServer $SERVE_PORT &
        SERVER_PID=$!
    elif command -v php &> /dev/null; then
        cd "$OUTPUT_DIR"
        php -S localhost:$SERVE_PORT &
        SERVER_PID=$!
    elif command -v node &> /dev/null; then
        # Create a simple Node.js server
        cat > "$OUTPUT_DIR/server.js" << EOF
const http = require('http');
const fs = require('fs');
const path = require('path');

const server = http.createServer((req, res) => {
    let filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
    const ext = path.extname(filePath).toLowerCase();

    const mimeTypes = {
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'text/javascript',
        '.json': 'application/json',
        '.yaml': 'text/yaml',
        '.yml': 'text/yaml'
    };

    const contentType = mimeTypes[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404);
            res.end('File not found');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

server.listen($SERVE_PORT, () => {
    console.log('Server running on port $SERVE_PORT');
});
EOF

        cd "$OUTPUT_DIR"
        node server.js &
        SERVER_PID=$!
    else
        error "No suitable HTTP server found. Please install Python, PHP, or Node.js."
        exit 1
    fi

    # Wait a moment for server to start
    sleep 2

    local server_url="http://localhost:$SERVE_PORT"
    success "Documentation server started: $server_url"

    # Open browser if requested
    if [[ "$OPEN_BROWSER" == "true" ]]; then
        log "Opening browser..."
        if command -v open &> /dev/null; then
            open "$server_url"
        elif command -v xdg-open &> /dev/null; then
            xdg-open "$server_url"
        elif command -v start &> /dev/null; then
            start "$server_url"
        else
            warning "Could not open browser automatically. Please visit: $server_url"
        fi
    fi

    # Set up signal handlers for cleanup
    trap 'kill $SERVER_PID 2>/dev/null; exit' INT TERM

    log "Press Ctrl+C to stop the server"
    wait $SERVER_PID
}

# Main execution
main() {
    log "Starting API documentation generation"

    check_prerequisites
    validate_spec

    if [[ "$VALIDATE_ONLY" == "true" ]]; then
        success "OpenAPI specification validation completed successfully"
        exit 0
    fi

    generate_documentation

    if [[ "$SERVE_DOCS" == "true" ]]; then
        serve_documentation
    else
        log "Documentation generated successfully"
        log "Generated files:"
        find "$OUTPUT_DIR" -type f -name "*.html" | while read -r file; do
            log "  - $file"
        done

        if [[ "$OPEN_BROWSER" == "true" ]]; then
            log "Opening documentation in browser..."
            if command -v open &> /dev/null; then
                open "$HTML_FILE"
            elif command -v xdg-open &> /dev/null; then
                xdg-open "$HTML_FILE"
            elif command -v start &> /dev/null; then
                start "$HTML_FILE"
            else
                warning "Could not open browser automatically"
            fi
        fi

        success "Documentation generation completed"
        log "To serve locally, run: $0 --serve"
    fi
}

# Run main function
main "$@"