import SwiftUI
import Combine
import UniformTypeIdentifiers
import CoreData

struct RecordView: View {
    var showsTabBar: Bool = false
    var onSelectTab: ((TabItem) -> Void)? = nil

    @State private var dailyTasks: [DailyTaskEntity] = []
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
    @State private var editingTask: DailyTaskEntity?
    @State private var draggingTask: DailyTaskEntity?
    @State private var localTabSelection: TabItem = .home
    @State private var contextSaveSubscription: AnyCancellable?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var tasks: [TaskDisplay] {
        dailyTasks.compactMap { TaskDisplay(entity: $0) }
    }

    private var totalTrackedTime: TimeInterval {
        dailyTasks.reduce(0) { $0 + TimeInterval($1.realTime) }
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
            .onAppear {
                fetchTodayTasks()
                contextSaveSubscription = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
                    .receive(on: RunLoop.main)
                    .sink { _ in fetchTodayTasks() }
            }
            .onDisappear {
                contextSaveSubscription?.cancel()
            }
        }
        .onReceive(timer) { date in
            accumulateElapsed(currentDate: date)
        }
    }

    private var appBar: some View {
        HStack {
            Text("record.title.today")
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.textPrimary)
            Spacer()
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("record.section.my_tasks")
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
                            onToggleComplete: { toggleCompletion(for: task.id) },
                            onToggleChecklistItem: nil
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteTask(id: task.id)
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var addTaskDestination: some View {
        AddTaskView(tasks: .constant([]), taskLibrary: .constant([])) { _ in
            fetchTodayTasks()
            selectedTaskID = dailyTasks.first?.id
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
        .alert("record.timer.goal_reached.title", isPresented: $showGoalDialog) {
            Button("record.timer.goal_reached.continue") {
                resumeAfterGoalPrompt()
            }
            Button("record.timer.goal_reached.stop", role: .destructive) {
                confirmStopTimer()
            }
        } message: {
            Text("record.timer.goal_reached.message")
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
        // Accumulate any remaining elapsed time if timer is still running
        if isTimerRunning {
            accumulateElapsed()
        }
        
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
        if let task = dailyTasks.first(where: { $0.id == activeID }) {
            let newTimeDouble = Double(task.realTime) + delta
            let newTime = Int64(newTimeDouble.rounded())
            task.realTime = newTime
            updateDailyTask(with: activeID, realTime: newTime)
        }
        checkGoal(for: activeID)
        lastTickDate = currentDate
    }

private func updateDailyTask(with id: UUID, realTime: Int64? = nil, isCompleted: Bool? = nil, checklistState: [Bool]? = nil) {
    guard let index = dailyTasks.firstIndex(where: { $0.id == id }) else { return }
    let task = dailyTasks[index]
    CoreDataManager.shared.updateDailyTask(task,
                                           realTime: realTime,
                                           isCompleted: isCompleted,
                                           checklistState: checklistState ?? task.checklistState,
                                           descriptionText: task.descriptionText,
                                           priority: task.priority)
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
        if let task = dailyTasks.first(where: { $0.id == id }) {
            let newValue = !task.isCompleted
            task.isCompleted = newValue
            updateDailyTask(with: id, isCompleted: newValue)
        }
    }

    private func deleteTask(id: UUID) {
        if activeTaskID == id {
            stopTimer()
        }
        if selectedTaskID == id {
            selectedTaskID = nil
        }
        if let entity = dailyTasks.first(where: { $0.id == id }) {
            CoreDataManager.shared.deleteDailyTask(entity)
        }
        fetchTodayTasks()
    }
    
    private func toggleChecklistItem(taskId: UUID, itemIndex: Int) {
        guard let index = dailyTasks.firstIndex(where: { $0.id == taskId }) else { return }
        let entity = dailyTasks[index]
        let texts = entity.task?.defaultChecklist ?? []
        guard itemIndex < texts.count else { return }
        var states = entity.checklistState ?? Array(repeating: false, count: texts.count)
        if itemIndex < states.count {
            states[itemIndex].toggle()
        } else {
            // pad if lengths mismatch
            states = texts.enumerated().map { idx, _ in
                idx == itemIndex ? true : (states.indices.contains(idx) ? states[idx] : false)
            }
        }
        entity.checklistState = states
        updateDailyTask(with: taskId, checklistState: states)
    }
    
    private func fetchTodayTasks() {
        dailyTasks = CoreDataManager.shared.fetchDailyTasks(for: Date())
        if let selected = selectedTaskID, !dailyTasks.contains(where: { $0.id == selected }) {
            selectedTaskID = dailyTasks.first?.id
        } else if selectedTaskID == nil {
            selectedTaskID = dailyTasks.first?.id
        }
    }
}

private struct TaskDisplay: Identifiable {
    let id: UUID
    let title: String
    let detail: String
    let checklist: [ChecklistItem]
    let isCompleted: Bool
    let categoryTitle: String?
    let categoryColor: Color?
    let goalTime: TimeInterval?
    let trackedTime: TimeInterval
    let tag: TaskItem.Tag
    
    init?(entity: DailyTaskEntity) {
        guard let id = entity.id else { return nil }
        self.id = id
        self.title = entity.task?.title ?? entity.descriptionText ?? "Untitled"
        self.detail = entity.descriptionText ?? ""
        let texts = entity.task?.defaultChecklist ?? []
        let states = entity.checklistState ?? Array(repeating: false, count: texts.count)
        self.checklist = texts.enumerated().map { idx, text in
            ChecklistItem(id: UUID(), text: text, isCompleted: states.indices.contains(idx) ? states[idx] : false)
        }
        self.isCompleted = entity.isCompleted
        let catName = entity.task?.category?.name
        let catColorHex = entity.task?.category?.color ?? entity.task?.color
        self.categoryTitle = catName ?? entity.task?.title
        self.categoryColor = catColorHex.map { Color(hex: $0) }
        let goalSeconds = entity.goalTime
        self.goalTime = goalSeconds > 0 ? TimeInterval(goalSeconds) : nil
        self.trackedTime = TimeInterval(entity.realTime)
        self.tag = .work
    }
}

private struct TaskCardView: View {
    let task: TaskDisplay
    let isSelected: Bool
    let isActive: Bool
    let trackedTime: TimeInterval
    let onToggleComplete: () -> Void
    var onToggleChecklistItem: ((Int) -> Void)? = nil
    
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

                    Text("record.task.accumulated \(formattedTrackedTime(trackedTime))")
                        .font(AppFont.caption())
                        .foregroundColor(task.isCompleted ? AppColor.textSecondary.opacity(0.6) : AppColor.textSecondary)
                }

                Spacer()

                TagBadge(title: task.categoryTitle ?? task.tag.rawValue, color: task.categoryColor ?? task.tag.color)
                
                // Toggle button - always reserve space but only show when selected and has content
                Button {
                    if isSelected && (!task.checklist.isEmpty || !task.detail.isEmpty) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.textSecondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .opacity(isSelected && (!task.checklist.isEmpty || !task.detail.isEmpty) ? 1 : 0)
                .disabled(!(isSelected && (!task.checklist.isEmpty || !task.detail.isEmpty)))
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
            
            // Expanded details section
            if isSelected && isExpanded && (!task.checklist.isEmpty || !task.detail.isEmpty) {
                Divider()
                    .background(AppColor.border)
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    if !task.checklist.isEmpty {
                        ForEach(task.checklist.indices, id: \.self) { index in
                            HStack(spacing: AppSpacing.small) {
                                Button {
                                    onToggleChecklistItem?(index)
                                } label: {
                                    Image(systemName: task.checklist[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(task.checklist[index].isCompleted ? AppColor.primary : AppColor.textSecondary)
                                }
                                .buttonStyle(.plain)
                                
                                Text(task.checklist[index].text)
                                    .font(AppFont.bodyRegular())
                                    .foregroundColor(task.checklist[index].isCompleted ? AppColor.textSecondary : AppColor.textPrimary)
                                    .strikethrough(task.checklist[index].isCompleted)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    } else {
                        Text(task.detail)
                            .font(AppFont.bodyRegular())
                            .foregroundColor(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, AppSpacing.mediumPlus)
                .padding(.vertical, AppSpacing.medium)
            }
        }
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .cornerRadius(AppRadius.standard)
        .shadow(color: AppShadow.card, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        .onChange(of: isSelected) { oldValue, newValue in
            // When task becomes selected, automatically expand if it has content
            if newValue && (!task.checklist.isEmpty || !task.detail.isEmpty) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded = true
                }
            } else if !newValue {
                // When deselected, collapse
                isExpanded = false
            }
        }
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

            Text("record.timer.total_today \(formattedTotal(totalTime))")
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
                    Text("record.timer.start")
                }
            }
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)

            AppButton(style: .neutral, action: onPause) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "pause.fill")
                    Text("record.timer.pause")
                }
            }
            .disabled(!canPause)
            .opacity(canPause ? 1 : 0.5)

            AppButton(style: .destructive, action: onStop) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "stop.fill")
                    Text("record.timer.stop")
                }
            }
            .disabled(!canStop)
            .opacity(canStop ? 1 : 0.5)
        }
    }
}

struct ChecklistItem: Identifiable, Codable {
    var id = UUID()
    var text: String
    var isCompleted: Bool = false
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
    var checklist: [ChecklistItem] = []
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
            checklist: checklist,
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
