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
                    .padding(.horizontal, AppSpacing.mediumPlus)
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
            HStack {
                Text("My Tasks")
                    .sectionTitleStyle()

                Spacer()

                Button {
                    showAddTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.white)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .fill(AppColor.primary)
                        )
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: AppSpacing.smallPlus) {
                ForEach(tasks) { task in
                    Button {
                        handleTaskSelection(task.id)
                    } label: {
                        TaskCardView(
                            task: task,
                            isSelected: selectedTaskID == task.id,
                            isActive: activeTaskID == task.id,
                            trackedTime: task.trackedTime,
                            onToggleComplete: { toggleCompletion(for: task.id) }
                        )
                    }
                    .buttonStyle(.plain)
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
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
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

    private func toggleCompletion(for id: UUID) {
        updateTask(with: id) { item in
            item.isCompleted.toggle()
        }
    }
}

private struct TaskCardView: View {
    let task: TaskItem
    let isSelected: Bool
    let isActive: Bool
    let trackedTime: TimeInterval
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(task.isCompleted ? AppColor.primaryStrong : AppColor.textSecondary.opacity(0.7))

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(task.title)
                    .font(AppFont.body())
                    .foregroundColor(task.isCompleted ? AppColor.textSecondary : AppColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .strikethrough(task.isCompleted, color: AppColor.textSecondary)

                Text("Tracked: \(formattedTrackedTime(trackedTime))")
                    .font(AppFont.caption())
                    .foregroundColor(task.isCompleted ? AppColor.textSecondary.opacity(0.6) : AppColor.textSecondary)
            }

            Spacer()

            TagBadge(tag: task.tag)
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
        if isActive {
            return AppColor.primary.opacity(0.22)
        }
        if isSelected {
            return AppColor.primary.opacity(0.12)
        }
        return AppColor.surface
    }

    private var borderColor: Color {
        if isActive {
            return AppColor.primaryStrong
        }
        if isSelected {
            return AppColor.primaryStrong.opacity(0.9)
        }
        return AppColor.clear
    }

    private var borderWidth: CGFloat {
        if isActive {
            return 2.5
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
        VStack(spacing: AppSpacing.small) {
            Text(formattedTime(currentTime))
                .font(AppFont.timerDisplay())
                .foregroundColor(AppColor.textPrimary)

            Text("Total Time Today: \(formattedTotal(totalTime))")
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
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
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
            }
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)

            AppButton(style: .neutral, action: onPause) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "pause.fill")
                    Text("Pause")
                }
            }
            .disabled(!canPause)
            .opacity(canPause ? 1 : 0.5)

            AppButton(style: .destructive, action: onStop) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
            }
            .disabled(!canStop)
            .opacity(canStop ? 1 : 0.5)
        }
    }
}

private struct CustomTabBar: View {
    @Binding var selectedTab: TabItem.Tab

    private let tabs: [TabItem] = [
        TabItem(tab: .home, label: "Record", icon: "timer"),
        TabItem(tab: .report, label: "Report", icon: "chart.bar"),
        TabItem(tab: .compare, label: "Compare", icon: "chart.line.uptrend.xyaxis"),
        TabItem(tab: .activity, label: "Activity", icon: "tag"),
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
        .padding(.horizontal, AppSpacing.mediumPlus)
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
        case shopping = "Shopping"
        case cooking = "Cooking"

        var color: Color {
            switch self {
            case .work:
                return AppColor.work
            case .fitness:
                return AppColor.fitness
            case .youtube:
                return AppColor.youtube
            case .learn:
                return AppColor.learning
            case .personal:
                return AppColor.personal
            case .shopping:
                return AppColor.shopping
            case .cooking:
                return AppColor.cooking
            }
        }
    }

    let id = UUID()
    let title: String
    let tag: Tag
    var trackedTime: TimeInterval = 0
    var detail: String = ""
    var isCompleted: Bool = false
}

private struct TagBadge: View {
    let tag: TaskItem.Tag

    var body: some View {
        AppBadge(title: tag.rawValue, color: tag.color)
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
