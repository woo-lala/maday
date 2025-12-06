import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var tasks: [TaskItem]
    @Binding var taskLibrary: [TaskItem]
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @State private var filterExpanded = false
    @State private var selectedFilter: TaskCategoryFilter = .all
    @State private var selectedTaskIDs: Set<UUID> = []
    @State private var editingTask: TaskItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        categoryFilter
                        existingTasksSection
                    }
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.top, AppSpacing.large)
                    .padding(.bottom, AppSpacing.xLarge)
                }
        }
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
        .navigationTitle("add_task.title")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTask) { task in
            NavigationStack {
                NewTaskView(tasks: $taskLibrary, taskToEdit: task)
            }
        }
    }
    }




    private var categoryFilter: some View {
        // ... (unchanged)
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    filterExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(AppColor.primary)
                    Text(selectedFilter.title)
                        .font(AppFont.body())
                        .foregroundColor(AppColor.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                        .rotationEffect(filterExpanded ? .degrees(180) : .zero)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: filterExpanded)
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.smallPlus)
            }
            .buttonStyle(.plain)

            if filterExpanded {
                Divider()
                    .padding(.horizontal, AppSpacing.medium)

                VStack(spacing: AppSpacing.small) {
                    ForEach(TaskCategoryFilter.allCases) { filter in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                selectedFilter = filter
                                filterExpanded = false
                            }
                        } label: {
                            HStack(spacing: AppSpacing.small) {
                                Circle()
                                    .fill(filter.category.color)
                                    .frame(width: AppSpacing.smallPlus, height: AppSpacing.smallPlus)
                                Text(filter.title)
                                    .font(AppFont.bodyRegular())
                                    .foregroundColor(AppColor.textPrimary)
                                Spacer()
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColor.primary)
                                        .font(AppFont.caption())
                                }
                            }
                            .padding(.horizontal, AppSpacing.small)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.smallPlus)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                        .fill(AppColor.surface)
                )
        )
    }

    private var existingTasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("add_task.section.existing")
                .sectionTitleStyle()

            if displayCategories.isEmpty {
                Text("add_task.empty.category")
                    .font(AppFont.bodyRegular())
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppSpacing.small)
            } else {
                ForEach(displayCategories, id: \.self) { category in
                    Section {
                        VStack(spacing: AppSpacing.smallPlus) {
                            ForEach(filteredTasks(for: category)) { task in
                                Button {
                                    toggleSelection(for: task.id)
                                } label: {
                                    ExistingTaskCard(
                                        task: task,
                                        indicatorColor: category.color,
                                        isSelected: selectedTaskIDs.contains(task.id)
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        editingTask = task
                                    } label: {
                                        Label("common.edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteTask(task)
                                    } label: {
                                        Label("common.delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        AppSectionHeader(title: category.title, indicatorColor: category.color)
                            .padding(.bottom, AppSpacing.xSmall)
                    }
                }
            }

            NavigationLink {
                NewTaskView(tasks: $taskLibrary, onTaskCreated: { newTask in
                    // When a new task is created in library, select it in AddTaskView so user can add it
                    toggleSelection(for: newTask.id)
                })
            } label: {
                Text("add_task.create_new")
                    .font(AppFont.caption())
                    .foregroundColor(AppColor.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var saveButtonBar: some View {
        VStack(spacing: AppSpacing.small) {
            AppButton(style: .primary) {
                addSelectedTask()
            } label: {
                Text("common.add")
            }
            .disabled(selectedTaskIDs.isEmpty)
            .opacity(selectedTaskIDs.isEmpty ? 0.6 : 1)

            AppColor.clear
                .frame(height: AppSpacing.xSmall)
        }
        .padding(.horizontal, AppSpacing.mediumPlus)
        .padding(.top, AppSpacing.smallPlus)
        .padding(.bottom, AppSpacing.small)
        .background(AppColor.surface.shadow(color: AppShadow.card.opacity(0.5), radius: 4, x: 0, y: -2))
    }

    private var displayCategories: [TaskCategory] {
        let base: [TaskCategory]
        switch selectedFilter {
        case .all:
            base = TaskCategory.allCases
        default:
            base = [selectedFilter.category]
        }
        return base.filter { !filteredTasks(for: $0).isEmpty }
    }

    private func filteredTasks(for category: TaskCategory) -> [TaskItem] {
        taskLibrary.filter { category.matches(tag: $0.tag) }
    }

    private func toggleSelection(for id: UUID) {
        if selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        } else {
            selectedTaskIDs.insert(id)
        }
    }

    private func addSelectedTask() {
        guard !selectedTaskIDs.isEmpty else { return }

        for id in selectedTaskIDs {
             if let template = taskLibrary.first(where: { $0.id == id }) {
                let newTask = template.copy()
                tasks.append(newTask)
                onTaskCreated?(newTask)
            }
        }
        
        selectedTaskIDs.removeAll()
        dismiss()
    }

    private func deleteTask(_ task: TaskItem) {
        if let index = taskLibrary.firstIndex(where: { $0.id == task.id }) {
            taskLibrary.remove(at: index)
        }
        if selectedTaskIDs.contains(task.id) {
            selectedTaskIDs.remove(task.id)
        }
    }
}

enum TaskCategory: String, CaseIterable, Identifiable {
    case work
    case personal
    case fitness
    case learn
    case youtube
    case cooking
    case shopping

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: return NSLocalizedString("category.work", comment: "")
        case .personal: return NSLocalizedString("category.personal", comment: "")
        case .fitness: return NSLocalizedString("category.fitness", comment: "")
        case .learn: return NSLocalizedString("category.learn", comment: "")
        case .youtube: return NSLocalizedString("category.youtube", comment: "")
        case .cooking: return NSLocalizedString("category.cooking", comment: "")
        case .shopping: return NSLocalizedString("category.shopping", comment: "")
        }
    }

    var color: Color {
        switch self {
        case .work: return AppColor.work
        case .personal: return AppColor.personal
        case .fitness: return AppColor.fitness
        case .learn: return AppColor.learning
        case .youtube: return AppColor.youtube
        case .cooking: return AppColor.cooking
        case .shopping: return AppColor.shopping
        }
    }

    var tag: TaskItem.Tag {
        switch self {
        case .work: return .work
        case .personal: return .personal
        case .fitness: return .fitness
        case .learn: return .learn
        case .youtube: return .youtube
        case .cooking: return .cooking
        case .shopping: return .shopping
        }
    }

    func matches(tag: TaskItem.Tag) -> Bool {
        return self.tag == tag
    }
}

enum TaskCategoryFilter: String, CaseIterable, Identifiable {
    case all
    case work
    case personal
    case fitness
    case learn
    case youtube
    case cooking
    case shopping

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return NSLocalizedString("category.all", comment: "")
        case .work: return NSLocalizedString("category.work", comment: "")
        case .personal: return NSLocalizedString("category.personal", comment: "")
        case .fitness: return NSLocalizedString("category.fitness", comment: "")
        case .learn: return NSLocalizedString("category.learn", comment: "")
        case .youtube: return NSLocalizedString("category.youtube", comment: "")
        case .cooking: return NSLocalizedString("category.cooking", comment: "")
        case .shopping: return NSLocalizedString("category.shopping", comment: "")
        }
    }

    var category: TaskCategory {
        switch self {
        case .all: return .work // unused when .all
        case .work: return .work
        case .personal: return .personal
        case .fitness: return .fitness
        case .learn: return .learn
        case .youtube: return .youtube
        case .cooking: return .cooking
        case .shopping: return .shopping
        }
    }
}

private struct ExistingTaskCard: View {
    let task: TaskItem
    let indicatorColor: Color
    let isSelected: Bool
    
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: AppSpacing.medium, height: AppSpacing.medium)
                    .shadow(color: indicatorColor.opacity(0.25), radius: 2, x: 0, y: 1)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(task.title)
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let goal = task.goalTime {
                            Text("add_task.card.goal \(formattedGoalTime(goal))")
                                .font(AppFont.caption())
                                .foregroundColor(AppColor.primary)
                                .fontWeight(.medium)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                
                // Toggle button - always reserve space but only show when has content
                Button {
                    if !task.checklist.isEmpty || !task.detail.isEmpty {
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
                .opacity(!task.checklist.isEmpty || !task.detail.isEmpty ? 1 : 0)
                .disabled(task.checklist.isEmpty && task.detail.isEmpty)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
            
            // Expanded details section
            if isExpanded && (!task.checklist.isEmpty || !task.detail.isEmpty) {
                Divider()
                    .background(AppColor.border)
                    .padding(.horizontal, AppSpacing.medium)
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    if !task.checklist.isEmpty {
                        ForEach(task.checklist.indices, id: \.self) { index in
                            HStack(spacing: AppSpacing.small) {
                                Image(systemName: task.checklist[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(task.checklist[index].isCompleted ? AppColor.primary : AppColor.textSecondary)
                                
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
        .background(
            RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                .fill(isSelected ? AppColor.primary.opacity(0.12) : AppColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                .stroke(isSelected ? AppColor.primary : AppColor.clear, lineWidth: isSelected ? 2 : 0)
        )
        .shadow(color: AppShadow.card, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)

    }
    
    private func formattedGoalTime(_ time: TimeInterval) -> String {
        let totalMinutes = Int(time) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    AddTaskView(tasks: .constant([
        TaskItem(title: "Work on Project Dayflow", tag: .work, detail: "Finalize sprint backlog"),
        TaskItem(title: "Call with Mom", tag: .personal, detail: "Weekly check-in")
    ]), taskLibrary: .constant([
        TaskItem(title: "Work on Project Dayflow", tag: .work, detail: "Finalize sprint backlog"),
        TaskItem(title: "Call with Mom", tag: .personal, detail: "Weekly check-in"),
        TaskItem(title: "Library Task", tag: .fitness, detail: "Extra task", goalTime: 3600),
        TaskItem(title: "Deep Work Session", tag: .work, detail: "Focus on coding", goalTime: 5400),
        TaskItem(title: "Quick Jog", tag: .fitness, detail: "Morning cardio", goalTime: 1800),
        TaskItem(title: "Meditation", tag: .personal, detail: "Clear mind", goalTime: 300)
    ]))
}
