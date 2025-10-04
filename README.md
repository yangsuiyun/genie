# 🍅 Pomodoro Genie

A comprehensive task and time management application built with the Pomodoro Technique at its core. Boost your productivity with focused work sessions, intelligent task management, and detailed analytics across all your devices.

## ✨ Features

### 🎯 Core Functionality
- **Pomodoro Timer**: Customizable work and break intervals with precision timing (±1s accuracy)
- **Task Management**: Full CRUD operations with subtasks, priorities, and due dates
- **Cross-Device Sync**: Real-time synchronization across mobile, web, and desktop
- **Smart Notifications**: Contextual reminders and session alerts
- **Analytics & Reports**: Detailed productivity insights and custom reports

### 🏗️ Technical Highlights
- **High Performance**: Sub-150ms API response times, <100MB memory usage
- **Scalable Architecture**: Microservices with Go backend, Flutter frontend
- **Real-time Updates**: WebSocket connections and push notifications
- **Offline Support**: Local storage with intelligent sync resolution
- **Comprehensive Testing**: Unit, integration, E2E, and performance tests

## 🚀 Quick Start

### Prerequisites

- **Go**: 1.21+ ([Download](https://golang.org/dl/))
- **Flutter**: 3.16+ ([Install Guide](https://docs.flutter.dev/get-started/install))
- **Node.js**: 18+ ([Download](https://nodejs.org/))
- **Docker**: Latest ([Install Guide](https://docs.docker.com/get-docker/))

### 🏃‍♂️ 5-Minute Setup

```bash
# 1. Clone the repository
git clone https://github.com/pomodoro-genie/pomodoro-genie.git
cd pomodoro-genie

# 2. Start the database
docker-compose up -d

# 3. Start the backend
cd backend
go mod download
go run main.go

# 4. Start the mobile app (in a new terminal)
cd mobile
flutter pub get
flutter run

# 🎉 You're ready to go! The app should open automatically.
```

### 🔧 Detailed Setup

#### Backend (Go)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
go mod download

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
go run cmd/migrate/main.go

# Start the server
go run main.go
```

The backend will be available at `http://localhost:3000`

#### Mobile App (Flutter)

```bash
# Navigate to mobile directory
cd mobile

# Install dependencies
flutter pub get

# Generate code (if needed)
flutter packages pub run build_runner build

# Run on connected device/emulator
flutter run

# Or build for specific platform
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

#### Desktop App (Tauri)

```bash
# Navigate to desktop directory
cd desktop

# Install Rust dependencies
cargo build

# Install npm dependencies
npm install

# Start development server
npm run tauri dev

# Build for production
npm run tauri build
```

#### Database (Supabase)

```bash
# Start local Supabase instance
docker-compose up -d

# Access Supabase Studio at http://localhost:54323
# Default credentials are in docker-compose.yml
```

## 📁 Project Structure

```
pomodoro-genie/
├── backend/                 # Go API server
│   ├── cmd/                # CLI tools and utilities
│   ├── internal/           # Private application code
│   │   ├── handlers/       # HTTP request handlers
│   │   ├── services/       # Business logic layer
│   │   ├── models/         # Data models
│   │   ├── middleware/     # HTTP middleware
│   │   └── config/         # Configuration management
│   ├── tests/              # Test suites
│   │   ├── unit/          # Unit tests
│   │   ├── integration/   # Integration tests
│   │   └── performance/   # Performance tests
│   ├── docs/              # API documentation
│   └── migrations/        # Database migrations
├── mobile/                 # Flutter app (iOS/Android/Web)
│   ├── lib/               # Dart source code
│   │   ├── screens/       # UI screens
│   │   ├── providers/     # State management (Riverpod)
│   │   ├── services/      # Business logic
│   │   ├── models/        # Data models
│   │   └── widgets/       # Reusable UI components
│   └── test/              # Flutter tests
│       ├── widget/        # Widget tests
│       ├── e2e/          # End-to-end tests
│       └── timer/        # Timer precision tests
├── desktop/               # Tauri desktop app
│   ├── src-tauri/        # Rust backend
│   ├── src/              # Web frontend
│   └── dist/             # Built assets
├── shared/               # Shared code and specifications
│   ├── proto/           # Protocol buffers
│   └── types/           # Shared type definitions
├── specs/               # Project specifications
└── docker-compose.yml  # Local development stack
```

## 🏃‍♂️ Development Workflow

### Running Tests

```bash
# Backend tests
cd backend
go test ./...                    # All tests
go test ./tests/unit/...         # Unit tests
go test ./tests/integration/...  # Integration tests
go test ./tests/performance/...  # Performance tests

# Mobile tests
cd mobile
flutter test                     # All tests
flutter test test/widget/        # Widget tests
flutter test test/timer/         # Timer precision tests

# E2E tests
cd mobile/test/e2e
./run_tests.sh                  # Maestro E2E tests
```

### API Documentation

```bash
# Generate and serve API docs
cd backend/docs
./generate-docs.sh --serve --open

# Or view online at: http://localhost:8080
```

### Performance Monitoring

```bash
# Run performance tests
cd backend/tests/performance
./run_performance_tests.sh

# Monitor API performance
cd backend
go run cmd/monitor/main.go
```

### Code Quality

```bash
# Backend linting and formatting
cd backend
golangci-lint run
go fmt ./...

# Mobile linting and formatting
cd mobile
flutter analyze
dart format .

# Desktop linting
cd desktop
cargo clippy
npm run lint
```

## 🚀 Deployment

### Production Deployment

```bash
# Build all components
make build-all

# Deploy with Docker
docker-compose -f docker-compose.prod.yml up -d

# Or deploy individually
make deploy-backend
make deploy-mobile
make deploy-desktop
```

### Environment Configuration

Create environment files for each component:

**Backend (.env)**:
```env
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/pomodoro
JWT_SECRET=your-secret-key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
```

**Mobile (lib/config/env.dart)**:
```dart
class Environment {
  static const String apiBaseUrl = 'https://api.yourapp.com';
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

## 📊 Performance Benchmarks

### API Performance
- **Average Response Time**: <150ms
- **95th Percentile**: <300ms
- **Throughput**: >500 requests/second
- **Memory Usage**: <100MB under load

### Mobile Performance
- **App Launch Time**: <3 seconds
- **Timer Precision**: ±1 second accuracy
- **Sync Speed**: <2 seconds for typical datasets
- **Offline Capability**: Full functionality without network

### Database Performance
- **Query Response**: <50ms for simple queries
- **Complex Analytics**: <200ms
- **Concurrent Users**: 1000+ supported
- **Data Sync**: Real-time with <500ms latency

## 🧪 Testing Strategy

### Test Coverage
- **Backend**: >90% line coverage
- **Mobile**: >85% widget coverage
- **E2E**: Critical user journeys covered
- **Performance**: All endpoints under load

### Test Types
- **Unit Tests**: Individual function/component testing
- **Integration Tests**: API endpoint and database testing
- **Widget Tests**: Flutter UI component testing
- **E2E Tests**: Full user workflow testing with Maestro
- **Performance Tests**: Load testing and benchmarking
- **Timer Precision Tests**: Accuracy validation (±1s requirement)

## 📱 Platform Support

### Mobile
- **iOS**: 13.0+
- **Android**: API 21+ (Android 5.0)
- **Web**: Modern browsers (Chrome 89+, Safari 14+, Firefox 88+)

### Desktop
- **Windows**: 10+
- **macOS**: 10.15+
- **Linux**: Ubuntu 18.04+

### API Clients
- **REST API**: Full OpenAPI 3.0 specification
- **WebSocket**: Real-time updates
- **SDKs**: JavaScript, Python, Go, Swift, Dart

## 🔧 Configuration

### Pomodoro Settings
```yaml
default_work_duration: 1500      # 25 minutes
default_short_break: 300         # 5 minutes
default_long_break: 1200         # 20 minutes
sessions_until_long_break: 4
auto_start_breaks: true
timer_precision_tolerance: 1     # ±1 second
```

### Sync Configuration
```yaml
sync_interval: 300               # 5 minutes
conflict_resolution: "last_write_wins"
offline_queue_size: 1000
retry_attempts: 3
```

### Notification Settings
```yaml
session_complete: true
break_reminders: true
task_due_alerts: true
daily_summary: true
quiet_hours:
  start: "22:00"
  end: "08:00"
```

## 🛠️ Troubleshooting

### Common Issues

**Backend won't start**:
```bash
# Check Go version
go version  # Should be 1.21+

# Verify environment variables
cat .env

# Check database connection
go run cmd/health/main.go
```

**Mobile app build fails**:
```bash
# Clean Flutter cache
flutter clean
flutter pub get

# Check Flutter doctor
flutter doctor

# Update dependencies
flutter pub upgrade
```

**Timer precision issues**:
```bash
# Run timer precision tests
cd mobile/test/timer
./run_timer_tests.sh

# Check system performance
flutter run --profile
```

**Sync not working**:
```bash
# Check network connectivity
curl -I https://api.yourapp.com/health

# Verify authentication
curl -H "Authorization: Bearer $TOKEN" https://api.yourapp.com/sync/status

# Check local storage
flutter logs | grep sync
```

### Getting Help

- **Documentation**: [docs.pomodoro-genie.com](https://docs.pomodoro-genie.com)
- **API Reference**: [api.pomodoro-genie.com/docs](https://api.pomodoro-genie.com/docs)
- **GitHub Issues**: [github.com/pomodoro-genie/issues](https://github.com/pomodoro-genie/pomodoro-genie/issues)
- **Discord Community**: [discord.gg/pomodoro-genie](https://discord.gg/pomodoro-genie)
- **Stack Overflow**: Tag questions with `pomodoro-genie`

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Process
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Run the test suite: `make test-all`
5. Commit with conventional commits: `git commit -m "feat: add amazing feature"`
6. Push to your fork: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Standards
- **Go**: Follow standard Go conventions, use `golangci-lint`
- **Dart**: Follow Effective Dart guidelines, use `dart format`
- **Rust**: Follow Rust conventions, use `cargo clippy`
- **Testing**: Maintain >90% coverage for new code
- **Documentation**: Update docs for API changes

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Pomodoro Technique**: Created by Francesco Cirillo
- **Flutter Team**: For the amazing cross-platform framework
- **Go Team**: For the efficient backend language
- **Supabase**: For the excellent database and real-time features
- **Contributors**: All the amazing people who help improve this project

## 📈 Roadmap

### Version 2.0 (Q2 2024)
- [ ] AI-powered task prioritization
- [ ] Team collaboration features
- [ ] Advanced analytics dashboard
- [ ] Third-party app integrations

### Version 2.1 (Q3 2024)
- [ ] Voice commands and control
- [ ] Habit tracking integration
- [ ] Custom productivity methods
- [ ] Enhanced reporting features

### Long-term Vision
- [ ] Machine learning productivity insights
- [ ] IoT device integration
- [ ] Enterprise features
- [ ] Open API ecosystem

---

<div align="center">

**Built with ❤️ using Go, Flutter, and the Pomodoro Technique**

[🏠 Homepage](https://pomodoro-genie.com) • [📖 Documentation](https://docs.pomodoro-genie.com) • [🐛 Report Bug](https://github.com/pomodoro-genie/pomodoro-genie/issues) • [💡 Request Feature](https://github.com/pomodoro-genie/pomodoro-genie/discussions)

</div>