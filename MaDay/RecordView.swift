import SwiftUI
import Combine
import UniformTypeIdentifiers

struct RecordView: View {
    var showsTabBar: Bool = false
    var onSelectTab: ((TabItem) -> Void)? = nil

    @State private var tasks: [TaskItem]
    @State private var taskLibrary: [TaskItem]
    @State private var selectedTaskID: UUID?
    @State private var activeTaskID: UUID?
    @State private var isTimerRunning = false
    @State private var sessionElapsed: TimeInterval = 0
    @State private var lastTickDate: Date?
    @State private var showAddTask = false
    @State private var showGoalDialog = false
    @State private var goalPromptedTaskID: UUID?
    @State private var goalAcknowledgedTaskID: UUID?
    @State private var goalDismissedTaskIDs: Set<UUID> = []
    @State private var editingTask: TaskItem?
    @State private var draggingTask: TaskItem?
    @State private var localTabSelection: TabItem = .home

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(showsTabBar: Bool = false, onSelectTab: ((TabItem) -> Void)? = nil) {
        self.showsTabBar = showsTabBar
        self.onSelectTab = onSelectTab

        // Task library - these are templates
        let libraryTasks: [TaskItem] = [
            TaskItem(title: "Work on Project Dayflow", tag: .work, detail: "Finalize sprint backlog and sync with design", categoryTitle: "Work", categoryColor: TaskItem.Tag.work.color),
            TaskItem(title: "Read Atomic Habits", tag: .personal, detail: "Read 20 pages before bed", categoryTitle: "Personal", categoryColor: TaskItem.Tag.personal.color),
            TaskItem(title: "30 min HIIT Session", tag: .fitness, detail: "Power session from the Daily Burn plan", categoryTitle: "Fitness", categoryColor: TaskItem.Tag.fitness.color, goalTime: 60),
            TaskItem(title: "Review YouTube Analytics", tag: .work, detail: "Check watch time and retention charts", categoryTitle: "Work", categoryColor: TaskItem.Tag.work.color),
            TaskItem(title: "Deep Work Session", tag: .work, detail: "Focus on coding", categoryTitle: "Work", categoryColor: TaskItem.Tag.work.color, goalTime: 5400),
            TaskItem(title: "Quick Jog", tag: .fitness, detail: "Morning cardio", categoryTitle: "Fitness", categoryColor: TaskItem.Tag.fitness.color, goalTime: 1800),
            TaskItem(title: "Meditation", tag: .personal, detail: "Clear mind", categoryTitle: "Personal", categoryColor: TaskItem.Tag.personal.color, goalTime: 300)
        ]
        
        // Today's tasks - start with copies of some library tasks as examples
        let todayTasks: [TaskItem] = [
            libraryTasks[0].copy(),
            libraryTasks[2].copy(),
            libraryTasks[4].copy()
        ]
        
        _taskLibrary = State(initialValue: libraryTasks)
        _tasks = State(initialValue: todayTasks)
        _selectedTaskID = State(initialValue: todayTasks.first?.id)
    }

    private var totalTrackedTime: TimeInterval {
        tasks.reduce(0) { $0 + $1.trackedTime }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        appBar
                        tasksSection
                        timerSection
                        timerControls
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.top, AppSpacing.large)
                    .padding(.bottom, showsTabBar ? AppSpacing.xLarge + AppMetrics.buttonHeight : AppSpacing.xLarge)
                }
                .background(AppColor.background.ignoresSafeArea(edges: .bottom))

                if showsTabBar {
                    CommonTabBar(selectedTab: Binding(get: { localTabSelection }, set: { newValue in
                        localTabSelection = newValue
                        onSelectTab?(newValue)
                    }))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAddTask) {
                addTaskDestination
            }
            .sheet(item: $editingTask) { task in
                NavigationStack {
                    NewTaskView(tasks: $tasks, taskToEdit: task)
                }
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
                    .contextMenu {
                        Button {
                            editingTask = task
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onDrag {
                        draggingTask = task
                        return NSItemProvider(object: task.id.uuidString as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: TaskDropDelegate(target: task, tasks: $tasks, draggingTask: $draggingTask))
                }
            }
        }
    }

    private var addTaskDestination: some View {
        AddTaskView(tasks: $tasks, taskLibrary: $taskLibrary) { newTask in
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
        let activeTask = tasks.first { $0.id == activeTaskID }
        let selectedTask = tasks.first { $0.id == selectedTaskID }
        let targetTask = activeTask ?? selectedTask
        let shouldShowStopwatch = {
            guard let id = targetTask?.id else { return false }
            return goalAcknowledgedTaskID == id || goalDismissedTaskIDs.contains(id)
        }()
        
        return TimerSectionView(
            currentTime: sessionElapsed,
            totalTime: totalTrackedTime,
            goalTime: targetTask?.goalTime,
            trackedTime: targetTask?.trackedTime ?? 0,
            showStopwatchAfterGoal: shouldShowStopwatch
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
        .alert("목표 시간을 달성했어요.", isPresented: $showGoalDialog) {
            Button("이어하기") {
                resumeAfterGoalPrompt()
            }
            Button("종료하기", role: .destructive) {
                confirmStopTimer()
            }
        } message: {
            Text("계속 기록할까요?")
        }
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
            goalPromptedTaskID = nil
            goalAcknowledgedTaskID = nil
        }
        selectedTaskID = id
    }

    private func startTimer() {
        guard let selectedID = selectedTaskID, !isTimerRunning else { return }

        if activeTaskID != selectedID {
            activeTaskID = selectedID
            sessionElapsed = 0
            goalPromptedTaskID = nil
            goalAcknowledgedTaskID = nil
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

    private func confirmStopTimer() {
        // If a goal dialog was shown/handled, remember it to avoid re-prompting immediately.
        if showGoalDialog || goalPromptedTaskID != nil {
            goalAcknowledgedTaskID = goalPromptedTaskID ?? activeTaskID
            if let acknowledged = goalAcknowledgedTaskID {
                goalDismissedTaskIDs.insert(acknowledged)
            }
        }
        sessionElapsed = 0
        activeTaskID = nil
        lastTickDate = nil
        isTimerRunning = false
        showGoalDialog = false
        goalPromptedTaskID = nil
    }
    
    private func resumeAfterGoalPrompt() {
        sessionElapsed = 0
        isTimerRunning = true
        lastTickDate = Date()
        showGoalDialog = false
        goalAcknowledgedTaskID = activeTaskID
        if let activeID = activeTaskID {
            goalDismissedTaskIDs.insert(activeID)
        }
    }
    
    private func stopTimer() {
        // Compatibility helper for flows (e.g., delete) that need an immediate stop
        confirmStopTimer()
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
        checkGoal(for: activeID)
        lastTickDate = currentDate
    }

    private func updateTask(with id: UUID, mutate: (inout TaskItem) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        mutate(&tasks[index])
    }
    
    private func checkGoal(for id: UUID) {
        guard !showGoalDialog,
              goalPromptedTaskID != id,
              goalAcknowledgedTaskID != id,
              !goalDismissedTaskIDs.contains(id) else { return }
        guard let task = tasks.first(where: { $0.id == id }), let goal = task.goalTime, goal > 0 else { return }
        guard task.trackedTime >= goal else { return }
        
        // Goal reached: pause timer and prompt the user
        isTimerRunning = false
        lastTickDate = nil
        showGoalDialog = true
        goalPromptedTaskID = id
    }

    private func toggleCompletion(for id: UUID) {
        updateTask(with: id) { item in
            item.isCompleted.toggle()
        }
    }

    private func deleteTask(_ task: TaskItem) {
        if activeTaskID == task.id {
            stopTimer()
        }
        if selectedTaskID == task.id {
            selectedTaskID = nil
        }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
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

            TagBadge(title: task.categoryTitle ?? task.tag.rawValue, color: task.categoryColor ?? task.tag.color)
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
    var goalTime: TimeInterval? = nil
    var trackedTime: TimeInterval = 0
    var showStopwatchAfterGoal: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            if let goal = goalTime {
                if showStopwatchAfterGoal {
                    Text(formattedTime(currentTime))
                        .font(AppFont.timerDisplay())
                        .foregroundColor(AppColor.textPrimary)
                } else {
                    // Timer Mode: Show remaining time
                    let remaining = max(goal - trackedTime, 0)
                    Text(formattedGoalTime(remaining))
                        .font(AppFont.timerDisplay())
                        .foregroundColor(AppColor.textPrimary)
                }
            } else {
                // Stopwatch Mode: Show current session time
                Text(formattedTime(currentTime))
                    .font(AppFont.timerDisplay())
                    .foregroundColor(AppColor.textPrimary)
            }

            Text("Total Time Today: \(formattedTotal(totalTime))")
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(abs(time))
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
    
    private func formattedGoalTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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

private struct TaskDropDelegate: DropDelegate {
    let target: TaskItem
    @Binding var tasks: [TaskItem]
    @Binding var draggingTask: TaskItem?

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.text])
    }

    func dropEntered(info: DropInfo) {
        guard let draggingTask, draggingTask.id != target.id else { return }
        if let fromIndex = tasks.firstIndex(where: { $0.id == draggingTask.id }),
           let toIndex = tasks.firstIndex(where: { $0.id == target.id }) {
            withAnimation(.easeInOut(duration: 0.15)) {
                let item = tasks.remove(at: fromIndex)
                tasks.insert(item, at: toIndex)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingTask = nil
        return true
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
    var title: String
    var tag: Tag
    var trackedTime: TimeInterval = 0
    var detail: String = ""
    var isCompleted: Bool = false
    var categoryTitle: String? = nil
    var categoryColor: Color? = nil
    var goalTime: TimeInterval? = nil
    
    // Create a copy of the task with a new ID (for adding library tasks to today's list)
    func copy() -> TaskItem {
        TaskItem(
            title: title,
            tag: tag,
            trackedTime: 0, // Reset tracked time for new instance
            detail: detail,
            isCompleted: false, // Reset completion status
            categoryTitle: categoryTitle,
            categoryColor: categoryColor,
            goalTime: goalTime
        )
    }
}

private struct TagBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(AppFont.callout())
            .fontWeight(.semibold)
            .padding(.horizontal, AppSpacing.smallPlus)
            .padding(.vertical, AppSpacing.xSmall)
            .background(
                Capsule()
                    .fill(color)
            )
            .foregroundColor(AppColor.white)
    }
}

#Preview {
    RecordView(showsTabBar: true)
        .background(AppColor.background)
}
