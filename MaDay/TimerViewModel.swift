import Foundation
import Combine
import CoreData

enum TimerState {
    case idle       // no session started yet
    case running    // currently measuring
    case paused     // temporarily stopped
    case finished   // task fully stopped for the day
}

final class TimerViewModel: ObservableObject {
    @Published private(set) var timerState: TimerState = .idle
    @Published private(set) var elapsedTime: Int = 0
    @Published private(set) var activeDailyTask: DailyTaskEntity?
    @Published private(set) var currentSession: SessionEntity?

    private var timerCancellable: AnyCancellable?
    private var lastTick: Date?
    private var runningAccumulated: TimeInterval = 0
    private var baseElapsedSeconds: TimeInterval = 0

    func select(task: DailyTaskEntity?) {
        stopTimer()
        activeDailyTask = task
        baseElapsedSeconds = persistedElapsed(for: task)
        elapsedTime = Int(baseElapsedSeconds)
        timerState = task == nil ? .idle : .finished
    }

    func start(with task: DailyTaskEntity) {
        if activeDailyTask?.id != task.id {
            stopTimer()
            activeDailyTask = task
        }
        guard timerState == .idle || timerState == .finished else { return }

        baseElapsedSeconds = persistedElapsed(for: task)
        elapsedTime = Int(baseElapsedSeconds)
        runningAccumulated = 0
        lastTick = Date()
        currentSession = CoreDataManager.shared.createSession(for: task, start: lastTick ?? Date())
        timerState = .running
        startTicker()
    }

    func pause() {
        guard timerState == .running, let task = activeDailyTask, let session = currentSession else { return }
        captureDelta()
        CoreDataManager.shared.endSession(session, for: task, end: Date())
        baseElapsedSeconds = persistedElapsed(for: task)
        runningAccumulated = 0
        elapsedTime = Int(baseElapsedSeconds)
        currentSession = nil
        timerState = .paused
        stopTicker()
    }

    func resume() {
        guard timerState == .paused, let task = activeDailyTask else { return }
        baseElapsedSeconds = persistedElapsed(for: task)
        runningAccumulated = 0
        lastTick = Date()
        currentSession = CoreDataManager.shared.createSession(for: task, start: lastTick ?? Date())
        timerState = .running
        startTicker()
    }

    func stop() {
        guard let task = activeDailyTask else {
            resetState()
            return
        }

        if timerState == .running, let session = currentSession {
            captureDelta()
            CoreDataManager.shared.endSession(session, for: task, end: Date())
        }
        stopTimer()
        baseElapsedSeconds = persistedElapsed(for: task)
        elapsedTime = Int(baseElapsedSeconds)
        timerState = .finished
    }

    func liveElapsedTime(for entity: DailyTaskEntity) -> Int {
        guard let active = activeDailyTask, active.id == entity.id else {
            return Int(entity.realTime)
        }
        if timerState == .running {
            return Int(baseElapsedSeconds + runningAccumulated)
        }
        return elapsedTime
    }

    // MARK: - Private helpers

    init() {
        restoreActiveSession()
    }

    // MARK: - Private helpers

    private func startTicker() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.tick(date: date)
            }
    }

    private func stopTicker() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick(date: Date) {
        guard timerState == .running, let sessionStart = currentSession?.startTime else { return }
        // Use absolute difference from session start to handle background/suspension automatically
        runningAccumulated = date.timeIntervalSince(sessionStart)
        elapsedTime = Int(baseElapsedSeconds + runningAccumulated)
        lastTick = date
    }

    private func captureDelta() {
        // With absolute time calculation, we just need to update final state
        guard let start = currentSession?.startTime else { return }
        runningAccumulated = Date().timeIntervalSince(start)
    }

    private func stopTimer() {
        stopTicker()
        currentSession = nil
        runningAccumulated = 0
        lastTick = nil
    }
    
    private func restoreActiveSession() {
        // Attempt to find a recent session that has no endTime (technically invalid state in strict flow, but possible if crashed/killed)
        // For now, simpler approach: Just ensure we load the state if we are still in memory (handled by EnvironmentObject).
        // Extended persistence after app kill requires querying CoreData for open sessions.
        // Let's implement a basic check for the last session of the last modified daily task.
        
        // This is a "nice to have" for full resilience, but for now let's focus on the user's "navigation and background" request.
        // The EnvironmentObject move handles navigation.
        // The tick update handles background suspension.
    }

    private func resetState() {
        stopTimer()
        activeDailyTask = nil
        baseElapsedSeconds = 0
        elapsedTime = 0
        timerState = .idle
    }

    private func persistedElapsed(for task: DailyTaskEntity?) -> TimeInterval {
        guard let task = task else { return 0 }
        return TimeInterval(CoreDataManager.shared.totalSessionDuration(for: task))
    }
}
