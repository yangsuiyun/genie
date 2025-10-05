import Foundation
import Combine
import CoreData

// MARK: - PomodoroService Protocol

protocol PomodoroServiceProtocol {
    // MARK: - Session Management

    /// Starts a new Pomodoro session for a specific task
    /// - Parameters:
    ///   - task: Task to start session for
    ///   - duration: Session duration in seconds (default: 1500)
    /// - Returns: Created session
    /// - Throws: BusinessLogicError if session already active, ValidationError if invalid duration
    func startSession(for task: Task, duration: Int?) async throws -> PomodoroSession

    /// Gets the currently active session if any
    /// - Returns: Active session or nil
    /// - Throws: DataError if fetch fails
    func getActiveSession() async throws -> PomodoroSession?

    /// Pauses the active session
    /// - Throws: BusinessLogicError if no active session, DataError if pause fails
    func pauseActiveSession() async throws

    /// Resumes a paused session
    /// - Throws: BusinessLogicError if no paused session, DataError if resume fails
    func resumeActiveSession() async throws

    /// Completes the active session
    /// - Parameters:
    ///   - notes: Optional session notes
    /// - Throws: BusinessLogicError if no active session, DataError if completion fails
    func completeActiveSession(notes: String?) async throws

    /// Interrupts the active session (user stopped early)
    /// - Parameters:
    ///   - reason: Optional reason for interruption
    /// - Throws: BusinessLogicError if no active session, DataError if interruption fails
    func interruptActiveSession(reason: String?) async throws

    /// Cancels the active session (no time recorded)
    /// - Throws: BusinessLogicError if no active session, DataError if cancellation fails
    func cancelActiveSession() async throws

    // MARK: - Session History

    /// Fetches session history for a specific task
    /// - Parameters:
    ///   - task: Task to fetch sessions for
    ///   - limit: Maximum number of sessions (default: 100)
    /// - Returns: Array of sessions ordered by start time (newest first)
    /// - Throws: DataError if fetch fails
    func getSessionHistory(for task: Task, limit: Int?) async throws -> [PomodoroSession]

    /// Fetches session history for a specific project
    /// - Parameters:
    ///   - project: Project to fetch sessions for
    ///   - limit: Maximum number of sessions (default: 100)
    /// - Returns: Array of sessions ordered by start time (newest first)
    /// - Throws: DataError if fetch fails
    func getSessionHistory(for project: Project, limit: Int?) async throws -> [PomodoroSession]

    /// Fetches all session history with optional filtering
    /// - Parameters:
    ///   - startDate: Optional start date filter
    ///   - endDate: Optional end date filter
    ///   - status: Optional status filter
    ///   - limit: Maximum number of sessions (default: 100)
    /// - Returns: Array of filtered sessions
    /// - Throws: DataError if fetch fails
    func getAllSessionHistory(
        startDate: Date?,
        endDate: Date?,
        status: SessionStatus?,
        limit: Int?
    ) async throws -> [PomodoroSession]

    /// Deletes a session from history
    /// - Parameter session: Session to delete
    /// - Throws: BusinessLogicError if session is active, DataError if deletion fails
    func deleteSession(_ session: PomodoroSession) async throws

    // MARK: - Timer Observation

    /// Publisher for active session time updates
    /// Emits remaining time in seconds every second when session is active
    var activeSessionTimePublisher: AnyPublisher<TimeInterval, Never> { get }

    /// Publisher for session state changes
    /// Emits session status updates (active, paused, completed, etc.)
    var sessionStatePublisher: AnyPublisher<SessionState, Never> { get }

    /// Publisher for session completion events
    /// Emits when a session is completed or interrupted
    var sessionCompletionPublisher: AnyPublisher<PomodoroSession, Never> { get }

    // MARK: - Statistics

    /// Gets detailed statistics for a date range
    /// - Parameters:
    ///   - startDate: Range start date
    ///   - endDate: Range end date
    /// - Returns: Comprehensive session statistics
    /// - Throws: DataError if calculation fails
    func getSessionStatistics(from startDate: Date, to endDate: Date) async throws -> SessionStatistics

    /// Gets focus time statistics grouped by day
    /// - Parameters:
    ///   - startDate: Range start date
    ///   - endDate: Range end date
    /// - Returns: Daily focus time breakdown
    /// - Throws: DataError if calculation fails
    func getDailyFocusTime(from startDate: Date, to endDate: Date) async throws -> [Date: TimeInterval]

    /// Gets session completion trends
    /// - Parameters:
    ///   - startDate: Range start date
    ///   - endDate: Range end date
    /// - Returns: Completion rate trends over time
    /// - Throws: DataError if calculation fails
    func getCompletionTrends(from startDate: Date, to endDate: Date) async throws -> [Date: Double]

    // MARK: - Background Support

    /// Handles app moving to background (save state, schedule notifications)
    /// - Throws: DataError if background setup fails
    func handleAppWillEnterBackground() async throws

    /// Handles app returning to foreground (restore state, update timers)
    /// - Throws: DataError if foreground restoration fails
    func handleAppDidEnterForeground() async throws

    /// Schedules notification for session completion
    /// - Parameter session: Session to schedule notification for
    /// - Throws: NotificationError if scheduling fails
    func scheduleSessionNotification(for session: PomodoroSession) async throws

    /// Cancels scheduled notifications for a session
    /// - Parameter session: Session to cancel notifications for
    /// - Throws: NotificationError if cancellation fails
    func cancelSessionNotification(for session: PomodoroSession) async throws
}

// MARK: - Supporting Types

enum SessionStatus: String, CaseIterable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case interrupted = "interrupted"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .interrupted: return "Interrupted"
        case .cancelled: return "Cancelled"
        }
    }

    var isFinished: Bool {
        switch self {
        case .active, .paused: return false
        case .completed, .interrupted, .cancelled: return true
        }
    }
}

struct SessionState {
    let session: PomodoroSession?
    let status: SessionStatus
    let remainingTime: TimeInterval
    let progress: Double // 0.0 to 1.0
    let isPaused: Bool
}

struct SessionStatistics {
    let totalSessions: Int
    let completedSessions: Int
    let interruptedSessions: Int
    let cancelledSessions: Int
    let totalFocusTime: TimeInterval
    let averageSessionDuration: TimeInterval
    let completionRate: Double
    let longestStreak: Int // Days with at least one completed session
    let currentStreak: Int
    let averageSessionsPerDay: Double
    let mostProductiveTimeOfDay: Int? // Hour of day (0-23)
    let sessionsByStatus: [SessionStatus: Int]
}

// MARK: - Error Types

enum PomodoroServiceError: Error, LocalizedError {
    case validationError(String)
    case businessLogicError(String)
    case dataError(String)
    case notificationError(String)
    case notFound
    case sessionAlreadyActive
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .businessLogicError(let message):
            return "Business Logic Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .notificationError(let message):
            return "Notification Error: \(message)"
        case .notFound:
            return "Session not found"
        case .sessionAlreadyActive:
            return "A session is already active"
        case .noActiveSession:
            return "No active session"
        }
    }
}

// MARK: - PomodoroService Implementation

class PomodoroService: PomodoroServiceProtocol {
    private let context: NSManagedObjectContext
    private let validationService: ValidationService
    private let timerManager: TimerManager
    private let notificationManager: NotificationManager

    // Combine subjects for reactive updates
    private let sessionStateSubject = CurrentValueSubject<SessionState, Never>(
        SessionState(session: nil, status: .cancelled, remainingTime: 0, progress: 0, isPaused: false)
    )
    private let sessionCompletionSubject = PassthroughSubject<PomodoroSession, Never>()

    private var currentSession: PomodoroSession?
    private var cancellables = Set<AnyCancellable>()

    init(
        context: NSManagedObjectContext,
        validationService: ValidationService = ValidationService(),
        timerManager: TimerManager = TimerManager(),
        notificationManager: NotificationManager = NotificationManager()
    ) {
        self.context = context
        self.validationService = validationService
        self.timerManager = timerManager
        self.notificationManager = notificationManager

        setupTimerObservation()
        loadActiveSession()
    }

    // MARK: - Session Management

    func startSession(for task: Task, duration: Int?) async throws -> PomodoroSession {
        // Check if there's already an active session
        if let activeSession = try await getActiveSession() {
            throw PomodoroServiceError.sessionAlreadyActive
        }

        let sessionDuration = duration ?? 1500 // Default 25 minutes
        try validationService.validateSessionDuration(sessionDuration)

        return try await context.perform {
            let session = PomodoroSession(
                context: self.context,
                task: task,
                plannedDuration: sessionDuration
            )

            do {
                try self.context.save()
                self.currentSession = session

                // Start timer and schedule notification
                self.timerManager.startTimer(duration: TimeInterval(sessionDuration))
                try await self.scheduleSessionNotification(for: session)

                // Update state publishers
                self.updateSessionState()

                return session
            } catch {
                throw PomodoroServiceError.dataError("Failed to start session: \(error.localizedDescription)")
            }
        }
    }

    func getActiveSession() async throws -> PomodoroSession? {
        return try await context.perform {
            let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
            request.predicate = NSPredicate(format: "status IN %@", [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
            request.fetchLimit = 1

            do {
                let sessions = try self.context.fetch(request)
                let activeSession = sessions.first
                self.currentSession = activeSession
                return activeSession
            } catch {
                throw PomodoroServiceError.dataError("Failed to fetch active session: \(error.localizedDescription)")
            }
        }
    }

    func pauseActiveSession() async throws {
        guard let session = try await getActiveSession() else {
            throw PomodoroServiceError.noActiveSession
        }

        try await context.perform {
            try session.pause()

            do {
                try self.context.save()
                self.timerManager.pauseTimer()
                self.updateSessionState()
            } catch {
                throw PomodoroServiceError.dataError("Failed to pause session: \(error.localizedDescription)")
            }
        }
    }

    func resumeActiveSession() async throws {
        guard let session = try await getActiveSession() else {
            throw PomodoroServiceError.noActiveSession
        }

        try await context.perform {
            try session.resume()

            do {
                try self.context.save()
                self.timerManager.resumeTimer()
                self.updateSessionState()
            } catch {
                throw PomodoroServiceError.dataError("Failed to resume session: \(error.localizedDescription)")
            }
        }
    }

    func completeActiveSession(notes: String?) async throws {
        guard let session = try await getActiveSession() else {
            throw PomodoroServiceError.noActiveSession
        }

        try await context.perform {
            try session.complete(notes: notes)

            do {
                try self.context.save()
                self.timerManager.stopTimer()
                try await self.cancelSessionNotification(for: session)

                // Update task's last activity date
                session.task?.lastActivityDate = Date()
                try self.context.save()

                self.sessionCompletionSubject.send(session)
                self.currentSession = nil
                self.updateSessionState()
            } catch {
                throw PomodoroServiceError.dataError("Failed to complete session: \(error.localizedDescription)")
            }
        }
    }

    func interruptActiveSession(reason: String?) async throws {
        guard let session = try await getActiveSession() else {
            throw PomodoroServiceError.noActiveSession
        }

        try await context.perform {
            try session.interrupt(reason: reason)

            do {
                try self.context.save()
                self.timerManager.stopTimer()
                try await self.cancelSessionNotification(for: session)

                // Update task's last activity date
                session.task?.lastActivityDate = Date()
                try self.context.save()

                self.sessionCompletionSubject.send(session)
                self.currentSession = nil
                self.updateSessionState()
            } catch {
                throw PomodoroServiceError.dataError("Failed to interrupt session: \(error.localizedDescription)")
            }
        }
    }

    func cancelActiveSession() async throws {
        guard let session = try await getActiveSession() else {
            throw PomodoroServiceError.noActiveSession
        }

        try await context.perform {
            try session.cancel()

            do {
                try self.context.save()
                self.timerManager.stopTimer()
                try await self.cancelSessionNotification(for: session)

                self.currentSession = nil
                self.updateSessionState()
            } catch {
                throw PomodoroServiceError.dataError("Failed to cancel session: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Session History

    func getSessionHistory(for task: Task, limit: Int?) async throws -> [PomodoroSession] {
        let sessionLimit = limit ?? 100

        return try await context.perform {
            let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
            request.predicate = NSPredicate(format: "task == %@", task)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PomodoroSession.startTime, ascending: false)]
            request.fetchLimit = sessionLimit

            do {
                return try self.context.fetch(request)
            } catch {
                throw PomodoroServiceError.dataError("Failed to fetch session history: \(error.localizedDescription)")
            }
        }
    }

    func getSessionHistory(for project: Project, limit: Int?) async throws -> [PomodoroSession] {
        let sessionLimit = limit ?? 100

        return try await context.perform {
            let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
            request.predicate = NSPredicate(format: "task.project == %@", project)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PomodoroSession.startTime, ascending: false)]
            request.fetchLimit = sessionLimit

            do {
                return try self.context.fetch(request)
            } catch {
                throw PomodoroServiceError.dataError("Failed to fetch project session history: \(error.localizedDescription)")
            }
        }
    }

    func getAllSessionHistory(
        startDate: Date?,
        endDate: Date?,
        status: SessionStatus?,
        limit: Int?
    ) async throws -> [PomodoroSession] {
        if let start = startDate, let end = endDate {
            try validationService.validateDateRange(start: start, end: end)
        }

        let sessionLimit = limit ?? 100

        return try await context.perform {
            let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
            var predicates: [NSPredicate] = []

            if let start = startDate {
                predicates.append(NSPredicate(format: "startTime >= %@", start as NSDate))
            }

            if let end = endDate {
                predicates.append(NSPredicate(format: "startTime <= %@", end as NSDate))
            }

            if let status = status {
                predicates.append(NSPredicate(format: "status == %@", status.rawValue))
            }

            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            request.sortDescriptors = [NSSortDescriptor(keyPath: \PomodoroSession.startTime, ascending: false)]
            request.fetchLimit = sessionLimit

            do {
                return try self.context.fetch(request)
            } catch {
                throw PomodoroServiceError.dataError("Failed to fetch session history: \(error.localizedDescription)")
            }
        }
    }

    func deleteSession(_ session: PomodoroSession) async throws {
        guard !session.isActive else {
            throw PomodoroServiceError.businessLogicError("Cannot delete active session")
        }

        try await context.perform {
            self.context.delete(session)

            do {
                try self.context.save()
            } catch {
                throw PomodoroServiceError.dataError("Failed to delete session: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Timer Observation

    var activeSessionTimePublisher: AnyPublisher<TimeInterval, Never> {
        timerManager.remainingTimePublisher
    }

    var sessionStatePublisher: AnyPublisher<SessionState, Never> {
        sessionStateSubject.eraseToAnyPublisher()
    }

    var sessionCompletionPublisher: AnyPublisher<PomodoroSession, Never> {
        sessionCompletionSubject.eraseToAnyPublisher()
    }

    // MARK: - Statistics Implementation

    func getSessionStatistics(from startDate: Date, to endDate: Date) async throws -> SessionStatistics {
        try validationService.validateDateRange(start: startDate, end: endDate)

        return try await context.perform {
            let sessions = try self.getAllSessionHistorySync(
                startDate: startDate,
                endDate: endDate,
                status: nil
            )

            let totalSessions = sessions.count
            let completedSessions = sessions.filter { $0.sessionStatus == .completed }.count
            let interruptedSessions = sessions.filter { $0.sessionStatus == .interrupted }.count
            let cancelledSessions = sessions.filter { $0.sessionStatus == .cancelled }.count

            let focusTimeSessions = sessions.filter { $0.contributesToFocusTime }
            let totalFocusTime = focusTimeSessions.reduce(0) { total, session in
                return total + TimeInterval(session.actualDuration)
            }

            let averageSessionDuration: TimeInterval
            if !focusTimeSessions.isEmpty {
                averageSessionDuration = totalFocusTime / Double(focusTimeSessions.count)
            } else {
                averageSessionDuration = 0
            }

            let completionRate = totalSessions > 0 ? Double(completedSessions) / Double(totalSessions) : 0

            let sessionsByStatus = Dictionary(grouping: sessions) { $0.sessionStatus }
                .mapValues { $0.count }

            // Calculate streaks
            let streaks = self.calculateStreaks(sessions: sessions, in: startDate...endDate)

            // Calculate most productive time
            let mostProductiveHour = self.calculateMostProductiveHour(sessions: focusTimeSessions)

            // Calculate average sessions per day
            let daysDifference = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
            let averageSessionsPerDay = daysDifference > 0 ? Double(totalSessions) / Double(daysDifference) : 0

            return SessionStatistics(
                totalSessions: totalSessions,
                completedSessions: completedSessions,
                interruptedSessions: interruptedSessions,
                cancelledSessions: cancelledSessions,
                totalFocusTime: totalFocusTime,
                averageSessionDuration: averageSessionDuration,
                completionRate: completionRate,
                longestStreak: streaks.longest,
                currentStreak: streaks.current,
                averageSessionsPerDay: averageSessionsPerDay,
                mostProductiveTimeOfDay: mostProductiveHour,
                sessionsByStatus: sessionsByStatus
            )
        }
    }

    func getDailyFocusTime(from startDate: Date, to endDate: Date) async throws -> [Date: TimeInterval] {
        try validationService.validateDateRange(start: startDate, end: endDate)

        return try await context.perform {
            let sessions = try self.getAllSessionHistorySync(
                startDate: startDate,
                endDate: endDate,
                status: nil
            )

            let calendar = Calendar.current
            var dailyFocusTime: [Date: TimeInterval] = [:]

            let focusTimeSessions = sessions.filter { $0.contributesToFocusTime }

            for session in focusTimeSessions {
                guard let startTime = session.startTime else { continue }

                let dayStart = calendar.startOfDay(for: startTime)
                let focusTime = TimeInterval(session.actualDuration)

                dailyFocusTime[dayStart, default: 0] += focusTime
            }

            return dailyFocusTime
        }
    }

    func getCompletionTrends(from startDate: Date, to endDate: Date) async throws -> [Date: Double] {
        try validationService.validateDateRange(start: startDate, end: endDate)

        return try await context.perform {
            let sessions = try self.getAllSessionHistorySync(
                startDate: startDate,
                endDate: endDate,
                status: nil
            )

            let calendar = Calendar.current
            var dailyCompletionRates: [Date: Double] = [:]

            let sessionsByDay = Dictionary(grouping: sessions) { session -> Date in
                guard let startTime = session.startTime else { return Date.distantPast }
                return calendar.startOfDay(for: startTime)
            }

            for (day, daySessions) in sessionsByDay {
                guard day != Date.distantPast else { continue }

                let completedCount = daySessions.filter { $0.sessionStatus == .completed }.count
                let totalCount = daySessions.count

                let completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
                dailyCompletionRates[day] = completionRate
            }

            return dailyCompletionRates
        }
    }

    // MARK: - Background Support

    func handleAppWillEnterBackground() async throws {
        guard let session = currentSession else { return }

        try await context.perform {
            // Save current state
            session.updateProgress()

            do {
                try self.context.save()
            } catch {
                throw PomodoroServiceError.dataError("Failed to save state for background: \(error.localizedDescription)")
            }
        }

        // Schedule notification if session will complete in background
        if session.isActive {
            try await scheduleSessionNotification(for: session)
        }
    }

    func handleAppDidEnterForeground() async throws {
        guard let session = currentSession else { return }

        try await context.perform {
            // Update session progress for time spent in background
            session.updateProgress()

            // Check if session completed while in background
            if session.remainingTime <= 0 && session.isActive {
                try session.complete()
            }

            do {
                try self.context.save()
                self.updateSessionState()
            } catch {
                throw PomodoroServiceError.dataError("Failed to restore state from background: \(error.localizedDescription)")
            }
        }
    }

    func scheduleSessionNotification(for session: PomodoroSession) async throws {
        guard session.isActive else { return }

        let remainingTime = session.remainingTime
        guard remainingTime > 0 else { return }

        do {
            try await notificationManager.scheduleSessionCompletion(
                sessionId: session.id?.uuidString ?? UUID().uuidString,
                taskName: session.task?.name ?? "Task",
                in: remainingTime
            )
        } catch {
            throw PomodoroServiceError.notificationError("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    func cancelSessionNotification(for session: PomodoroSession) async throws {
        let sessionId = session.id?.uuidString ?? UUID().uuidString

        do {
            try await notificationManager.cancelSessionNotification(sessionId: sessionId)
        } catch {
            throw PomodoroServiceError.notificationError("Failed to cancel notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func setupTimerObservation() {
        timerManager.timerCompletedPublisher
            .sink { [weak self] in
                Task {
                    try? await self?.completeActiveSession(notes: "Session completed automatically")
                }
            }
            .store(in: &cancellables)

        timerManager.remainingTimePublisher
            .sink { [weak self] _ in
                self?.updateSessionState()
            }
            .store(in: &cancellables)
    }

    private func loadActiveSession() {
        Task {
            _ = try? await getActiveSession()
            updateSessionState()
        }
    }

    private func updateSessionState() {
        let state: SessionState

        if let session = currentSession {
            state = SessionState(
                session: session,
                status: session.sessionStatus,
                remainingTime: session.remainingTime,
                progress: session.progress,
                isPaused: session.isPaused
            )
        } else {
            state = SessionState(
                session: nil,
                status: .cancelled,
                remainingTime: 0,
                progress: 0,
                isPaused: false
            )
        }

        sessionStateSubject.send(state)
    }

    private func getAllSessionHistorySync(
        startDate: Date?,
        endDate: Date?,
        status: SessionStatus?
    ) throws -> [PomodoroSession] {
        let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
        var predicates: [NSPredicate] = []

        if let start = startDate {
            predicates.append(NSPredicate(format: "startTime >= %@", start as NSDate))
        }

        if let end = endDate {
            predicates.append(NSPredicate(format: "startTime <= %@", end as NSDate))
        }

        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \PomodoroSession.startTime, ascending: true)]

        return try context.fetch(request)
    }

    private func calculateStreaks(sessions: [PomodoroSession], in dateRange: ClosedRange<Date>) -> (longest: Int, current: Int) {
        let calendar = Calendar.current
        let completedSessions = sessions.filter { $0.sessionStatus == .completed }

        let daysWithSessions = Set(completedSessions.compactMap { session in
            session.startTime.map { calendar.startOfDay(for: $0) }
        })

        var longestStreak = 0
        var currentStreak = 0
        var streakCount = 0

        let today = calendar.startOfDay(for: Date())
        var currentDate = calendar.startOfDay(for: dateRange.lowerBound)

        while currentDate <= dateRange.upperBound {
            if daysWithSessions.contains(currentDate) {
                streakCount += 1
                longestStreak = max(longestStreak, streakCount)

                if currentDate <= today {
                    currentStreak = streakCount
                }
            } else {
                streakCount = 0
                if currentDate < today {
                    currentStreak = 0
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return (longest: longestStreak, current: currentStreak)
    }

    private func calculateMostProductiveHour(sessions: [PomodoroSession]) -> Int? {
        guard !sessions.isEmpty else { return nil }

        let calendar = Calendar.current
        let hourCounts = Dictionary(grouping: sessions) { session -> Int in
            guard let startTime = session.startTime else { return -1 }
            return calendar.component(.hour, from: startTime)
        }
        .filter { $0.key != -1 }
        .mapValues { $0.count }

        return hourCounts.max { $0.value < $1.value }?.key
    }
}

// MARK: - Validation Service

class ValidationService {
    func validateSessionDuration(_ duration: Int) throws {
        guard duration >= 300 && duration <= 7200 else {
            throw PomodoroServiceError.validationError("Session duration must be between 5 minutes (300s) and 2 hours (7200s)")
        }
    }

    func validateDateRange(start: Date, end: Date) throws {
        guard start <= end else {
            throw PomodoroServiceError.validationError("Start date must be before or equal to end date")
        }
    }
}

// MARK: - Timer Manager

class TimerManager {
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var plannedDuration: TimeInterval = 0
    private var isPaused: Bool = false
    private var isActive: Bool = false

    private let remainingTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let timerCompletedSubject = PassthroughSubject<Void, Never>()

    var remainingTimePublisher: AnyPublisher<TimeInterval, Never> {
        remainingTimeSubject.eraseToAnyPublisher()
    }

    var timerCompletedPublisher: AnyPublisher<Void, Never> {
        timerCompletedSubject.eraseToAnyPublisher()
    }

    var remainingTime: TimeInterval {
        guard isActive, let start = startTime else { return 0 }

        let now = Date()
        let elapsed = now.timeIntervalSince(start) - totalPausedDuration
        let remaining = max(0, plannedDuration - elapsed)

        return remaining
    }

    func startTimer(duration: TimeInterval) {
        guard !isActive else { return }

        plannedDuration = duration
        startTime = Date()
        totalPausedDuration = 0
        isPaused = false
        isActive = true

        startInternalTimer()
        remainingTimeSubject.send(remainingTime)
    }

    func pauseTimer() {
        guard isActive && !isPaused else { return }

        isPaused = true
        pausedTime = Date()
        stopInternalTimer()
    }

    func resumeTimer() {
        guard isActive && isPaused else { return }

        if let pausedStart = pausedTime {
            totalPausedDuration += Date().timeIntervalSince(pausedStart)
        }

        isPaused = false
        pausedTime = nil
        startInternalTimer()
        remainingTimeSubject.send(remainingTime)
    }

    func stopTimer() {
        guard isActive else { return }

        stopInternalTimer()
        resetState()
    }

    private func startInternalTimer() {
        stopInternalTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }

        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopInternalTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timerTick() {
        let remaining = remainingTime
        remainingTimeSubject.send(remaining)

        if remaining <= 0 {
            completeTimer()
        }
    }

    private func completeTimer() {
        isActive = false
        stopInternalTimer()
        remainingTimeSubject.send(0)
        timerCompletedSubject.send(())
        resetState()
    }

    private func resetState() {
        isActive = false
        isPaused = false
        startTime = nil
        pausedTime = nil
        totalPausedDuration = 0
        plannedDuration = 0
        remainingTimeSubject.send(0)
    }

    deinit {
        stopInternalTimer()
    }
}

// MARK: - Notification Manager

class NotificationManager {
    func scheduleSessionCompletion(sessionId: String, taskName: String, in timeInterval: TimeInterval) async throws {
        // Implementation would integrate with UserNotifications framework
        print("Scheduling notification for session \(sessionId) in \(timeInterval) seconds")
    }

    func cancelSessionNotification(sessionId: String) async throws {
        // Implementation would cancel scheduled notifications
        print("Cancelling notification for session \(sessionId)")
    }
}