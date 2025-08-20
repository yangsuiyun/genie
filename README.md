# 🍅 Pomodoro Timer

A cross-platform desktop productivity timer based on the Pomodoro Technique, built with Wails (Go + Vue 3).

## Features

- ✅ **Timer Functionality**: 25-minute work sessions with 5-minute breaks
- ✅ **State Management**: Visual indicators for work/break/paused states
- ✅ **Progress Tracking**: Dots showing completed pomodoros
- ✅ **Automatic Transitions**: Seamless switching between work and break modes
- ✅ **Modern UI**: Clean, minimalist design with gradient background

## Quick Start

### Prerequisites

- [Go](https://golang.org/dl/) 1.21+
- [Node.js](https://nodejs.org/) 18+
- [Wails v2](https://wails.io/docs/gettingstarted/installation)

### Development

```bash
# Start development server
./scripts/dev.sh

# Or manually:
cd frontend && npm install && cd ..
wails dev
```

### Building

```bash
# Build for production
./scripts/build.sh

# Or manually:
wails build
```

### Updating Dependencies

```bash
# Update all dependencies
./scripts/update.sh
```

## Project Structure

```
├── app.go              # Main application logic (Go)
├── main.go             # Entry point
├── frontend/           # Vue 3 frontend
│   ├── src/
│   │   ├── App.vue     # Main Vue component
│   │   └── main.ts     # Frontend entry point
│   └── package.json
├── scripts/            # Development scripts
├── docs/              # Documentation
└── wails.json         # Wails configuration
```

## Architecture

- **Backend**: Go with Wails framework for desktop integration
- **Frontend**: Vue 3 + TypeScript + Vite for modern web UI
- **Communication**: Wails bindings for Go ↔ Vue communication

## Configuration

Project settings can be configured in `wails.json`. See the [Wails documentation](https://wails.io/docs/reference/project-config) for details.

## Development Status

Current implementation: ~30% complete

✅ **Implemented:**
- Basic timer functionality
- Vue 3 frontend with controls
- State management and visual indicators
- Automatic work/break progression

🚧 **In Progress:**
- Settings customization UI
- Audio notifications
- System tray integration
- Analytics and statistics

📋 **Planned:**
- Desktop notifications
- Global keyboard shortcuts
- Data persistence
- Multi-language support

## Contributing

See [requirements document](docs/requirements/pomodoro-requirements.md) for detailed feature specifications.
