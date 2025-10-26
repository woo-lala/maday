import SwiftUI
import Combine

struct RecordView: View {
    @State private var tasks: [TaskItem]
    @State private var selectedTab: TabItem.Tab = .home
    @State private var selectedTaskID: UUID?
    @State private var activeTaskID: UUID?
    @State private var isTimerRunning = false
    @State private var sessionElapsed: TimeInterval = 0
    @State private var lastTickDate: Date?
    @State private var showAddTask = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        let initialTasks: [TaskItem] = [
            TaskItem(title: "Work on Project Dayflow", tag: .work, detail: "Finalize sprint backlog and sync with design"),
            TaskItem(title: "Read Atomic Habits", tag: .personal, detail: "Read 20 pages before bed"),
            TaskItem(title: "30 min HIIT Session", tag: .fitness, detail: "Power session from the Daily Burn plan"),
            TaskItem(title: "Review YouTube Analytics", tag: .work, detail: "Check watch time and retention charts")
        ]
        _tasks = State(initialValue: initialTasks)
        _selectedTaskID = State(initialValue: initialTasks.first?.id)
    }

    private var totalTrackedTime: TimeInterval {
        tasks.reduce(0) { $0 + $1.trackedTime }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        appBar
                        tasksSection
                        timerSection
                        timerControls
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }

                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.top, 8)
                    .background(Color.white)
            }
            .background(Color.white.edgesIgnoringSafeArea(.bottom))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAddTask) {
                addTaskDestination
            }
        }
        .onReceive(timer) { date in
            accumulateElapsed(currentDate: date)
        }
    }

    private var appBar: some View {
        HStack {
            Text("Today")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Tasks")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    Button {
                        handleTaskSelection(task.id)
                    } label: {
                        TaskCardView(
                            task: task,
                            isSelected: selectedTaskID == task.id,
                            isActive: activeTaskID == task.id,
                            trackedTime: task.trackedTime
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                showAddTask = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Task")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .cornerRadius(10)
            }
        }
    }

    private var addTaskDestination: some View {
        AddTaskView(tasks: $tasks) { newTask in
            selectedTaskID = newTask.id
            activeTaskID = nil
            sessionElapsed = 0
            isTimerRunning = false
            lastTickDate = nil
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var timerSection: some View {
        TimerSectionView(
            currentTime: sessionElapsed,
            totalTime: totalTrackedTime
        )
    }

    private var timerControls: some View {
        TimerControlView(
            onStart: startTimer,
            onPause: pauseTimer,
            onStop: stopTimer,
            canStart: canStartTimer,
            canPause: canPauseTimer,
            canStop: canStopTimer
        )
    }

    private var canStartTimer: Bool {
        !isTimerRunning && selectedTaskID != nil
    }

    private var canPauseTimer: Bool {
        isTimerRunning
    }

    private var canStopTimer: Bool {
        sessionElapsed > 0 || isTimerRunning
    }

    private func handleTaskSelection(_ id: UUID) {
        if activeTaskID != nil && activeTaskID != id {
            accumulateElapsed()
            isTimerRunning = false
            lastTickDate = nil
            sessionElapsed = 0
            activeTaskID = nil
        }
        selectedTaskID = id
    }

    private func startTimer() {
        guard let selectedID = selectedTaskID, !isTimerRunning else { return }

        if activeTaskID != selectedID {
            activeTaskID = selectedID
            sessionElapsed = 0
        }

        lastTickDate = Date()
        isTimerRunning = true
    }

    private func pauseTimer() {
        guard isTimerRunning else { return }
        accumulateElapsed()
        isTimerRunning = false
        lastTickDate = nil
    }

    private func stopTimer() {
        guard activeTaskID != nil || sessionElapsed > 0 else { return }
        accumulateElapsed()
        isTimerRunning = false
        lastTickDate = nil
        sessionElapsed = 0
        activeTaskID = nil
    }

    private func accumulateElapsed(currentDate: Date = Date()) {
        guard let activeID = activeTaskID else {
            lastTickDate = nil
            return
        }

        if !isTimerRunning {
            lastTickDate = currentDate
            return
        }

        guard let lastTick = lastTickDate else {
            lastTickDate = currentDate
            return
        }

        let delta = currentDate.timeIntervalSince(lastTick)
        guard delta > 0 else {
            lastTickDate = currentDate
            return
        }

        sessionElapsed += delta
        updateTask(with: activeID) { item in
            item.trackedTime += delta
        }
        lastTickDate = currentDate
    }

    private func updateTask(with id: UUID, mutate: (inout TaskItem) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        mutate(&tasks[index])
    }
}

private struct TaskCardView: View {
    let task: TaskItem
    let isSelected: Bool
    let isActive: Bool
    let trackedTime: TimeInterval

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.square")
                .foregroundColor(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("Tracked: \(formattedTrackedTime(trackedTime))")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            TagBadge(tag: task.tag)

            Image(systemName: isActive ? "timer.circle.fill" : "timer")
                .foregroundColor(isActive ? Theme.primary : Theme.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .cornerRadius(16)
        .shadow(color: Theme.shadow, radius: 2, x: 0, y: 0)
    }

    private var backgroundColor: Color {
        isActive ? Theme.primary.opacity(0.12) : Color.white
    }

    private var borderColor: Color {
        if isActive {
            return Theme.primary
        }
        if isSelected {
            return Theme.primaryStrong.opacity(0.9)
        }
        return Color.clear
    }

    private var borderWidth: CGFloat {
        if isActive {
            return 2
        }
        return isSelected ? 2 : 0
    }

    private func formattedTrackedTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

private struct TimerSectionView: View {
    let currentTime: TimeInterval
    let totalTime: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedTime(currentTime))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Text("Total Time Today: \(formattedTotal(totalTime))")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Theme.shadow, radius: 2, x: 0, y: 0)
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formattedTotal(_ time: TimeInterval) -> String {
        let totalMinutes = Int(time) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

private struct TimerControlView: View {
    let onStart: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    let canStart: Bool
    let canPause: Bool
    let canStop: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onStart) {
                buttonLabel(
                    "Start",
                    background: Theme.primaryStrong,
                    foreground: .white
                )
            }
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)

            Button(action: onPause) {
                buttonLabel(
                    "Pause",
                    background: Theme.secondaryStrong,
                    foreground: .white
                )
            }
            .disabled(!canPause)
            .opacity(canPause ? 1 : 0.5)

            Button(action: onStop) {
                buttonLabel(
                    "Stop",
                    background: Theme.neutralButton,
                    foreground: Theme.textSecondary,
                    borderColor: Theme.textSecondary.opacity(0.35)
                )
            }
            .disabled(!canStop)
            .opacity(canStop ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private func buttonLabel(
        _ title: String,
        background: Color,
        foreground: Color,
        borderColor: Color? = nil
    ) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 108, height: 48)
            .foregroundColor(foreground)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : 1.2)
            )
    }
}

private struct CustomTabBar: View {
    @Binding var selectedTab: TabItem.Tab

    private let tabs: [TabItem] = [
        TabItem(tab: .home, label: "Home", icon: "house.fill"),
        TabItem(tab: .report, label: "Report", icon: "chart.bar.xaxis"),
        TabItem(tab: .compare, label: "Compare", icon: "chart.line.uptrend.xyaxis"),
        TabItem(tab: .activity, label: "Activity", icon: "figure.walk"),
        TabItem(tab: .settings, label: "Settings", icon: "gearshape")
    ]

    var body: some View {
        HStack {
            ForEach(tabs) { item in
                Button {
                    selectedTab = item.tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(item.label)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(selectedTab == item.tab ? Theme.primary : Theme.textSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct TaskItem: Identifiable {
    enum Tag: String {
        case work = "Work"
        case fitness = "Fit"
        case youtube = "YouTube"
        case learn = "Learn"
        case personal = "Personal"

        var color: Color {
            switch self {
            case .work:
                return Theme.primary
            case .fitness:
                return Color(red: 90 / 255, green: 200 / 255, blue: 150 / 255)
            case .youtube:
                return Theme.secondary
            case .learn:
                return Color(red: 132 / 255, green: 94 / 255, blue: 247 / 255)
            case .personal:
                return Theme.secondary
            }
        }
    }

    let id = UUID()
    let title: String
    let tag: Tag
    var trackedTime: TimeInterval = 0
    var detail: String = ""
}

private struct TagBadge: View {
    let tag: TaskItem.Tag

    var body: some View {
        Text(tag.rawValue)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tag.color.opacity(0.12))
            .foregroundColor(tag.color)
            .cornerRadius(10)
    }
}

private struct TabItem: Identifiable {
    enum Tab {
        case home, report, compare, activity, settings
    }

    let id = UUID()
    let tab: Tab
    let label: String
    let icon: String
}

enum Theme {
    static let primary = Color(red: 91 / 255, green: 141 / 255, blue: 239 / 255)
    static let secondary = Color(red: 233 / 255, green: 78 / 255, blue: 61 / 255)
    static let primaryStrong = Color(red: 70 / 255, green: 117 / 255, blue: 224 / 255)
    static let secondaryStrong = Color(red: 204 / 255, green: 65 / 255, blue: 51 / 255)
    static let neutralButton = Color(red: 235 / 255, green: 237 / 255, blue: 244 / 255)
    static let textPrimary = Color(red: 23 / 255, green: 26 / 255, blue: 31 / 255)
    static let textSecondary = Color(red: 86 / 255, green: 93 / 255, blue: 109 / 255)
    static let shadow = Color.black.opacity(0.1)
    static let inputBorder = Color(red: 222 / 255, green: 225 / 255, blue: 230 / 255)
}

#Preview {
    RecordView()
        .background(Color.white)
}
