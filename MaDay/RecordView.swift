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
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        appBar
                        tasksSection
                        timerSection
                        timerControls
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.top, AppSpacing.large)
                    .padding(.bottom, AppSpacing.xLarge)
                }

                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.top, AppSpacing.small)
                    .background(AppColor.surface)
            }
            .background(AppColor.background.ignoresSafeArea(edges: .bottom))
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
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.textPrimary)
            Spacer()
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("My Tasks")
                .sectionTitleStyle()

            VStack(spacing: AppSpacing.smallPlus) {
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

            AppButton(style: .primary) {
                showAddTask = true
            } label: {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus")
                        .font(AppFont.button())
                    Text("Add Task")
                }
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
        .sectionCardStyle()
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
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: "checkmark.square")
                .foregroundColor(AppColor.textSecondary)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(task.title)
                    .font(AppFont.heading())
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("Tracked: \(formattedTrackedTime(trackedTime))")
                    .font(AppFont.caption())
                    .foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            TagBadge(tag: task.tag)

            Image(systemName: isActive ? "timer.circle.fill" : "timer")
                .foregroundColor(isActive ? AppColor.primary : AppColor.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .cornerRadius(AppRadius.standard)
        .shadow(color: AppShadow.card, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
    }

    private var backgroundColor: Color {
        isActive ? AppColor.primary.opacity(0.12) : AppColor.surface
    }

    private var borderColor: Color {
        if isActive {
            return AppColor.primary
        }
        if isSelected {
            return AppColor.primaryStrong.opacity(0.9)
        }
        return AppColor.clear
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
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(formattedTime(currentTime))
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.textPrimary)

            Text("Total Time Today: \(formattedTotal(totalTime))")
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
        }
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
        HStack(spacing: AppSpacing.small) {
            AppButton(style: .primary, action: onStart) {
                Text("Start")
            }
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)

            AppButton(style: .secondary, action: onPause) {
                Text("Pause")
            }
            .disabled(!canPause)
            .opacity(canPause ? 1 : 0.5)

            AppButton(style: .neutral, action: onStop) {
                Text("Stop")
            }
            .disabled(!canStop)
            .opacity(canStop ? 1 : 0.5)
        }
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
                    VStack(spacing: AppSpacing.xSmall) {
                        Image(systemName: item.icon)
                            .font(AppFont.heading())
                        Text(item.label)
                            .font(AppFont.caption())
                    }
                    .foregroundColor(selectedTab == item.tab ? AppColor.primary : AppColor.textSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
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
                return AppColor.primary
            case .fitness:
                return AppColor.fitness
            case .youtube:
                return AppColor.secondary
            case .learn:
                return AppColor.learning
            case .personal:
                return AppColor.secondary
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
            .font(AppFont.badge())
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(tag.color.opacity(0.12))
            .foregroundColor(tag.color)
            .cornerRadius(AppRadius.standard)
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

#Preview {
    RecordView()
        .background(AppColor.background)
}
