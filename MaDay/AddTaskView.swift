import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var tasks: [TaskItem]
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @State private var filterExpanded = false
    @State private var selectedFilter: TaskCategoryFilter = .all
    @State private var selectedTaskID: UUID?

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
        .navigationTitle("Add Task")
        .navigationBarTitleDisplayMode(.inline)
    }
    }

    private var categoryFilter: some View {
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
                            HStack {
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
            Text("Existing Tasks")
                .sectionTitleStyle()

            if displayCategories.isEmpty {
                Text("No tasks in this category yet")
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
                                        isSelected: selectedTaskID == task.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        AppSectionHeader(title: category.title, indicatorColor: category.color)
                            .padding(.bottom, AppSpacing.xSmall)
                    }
                }
            }

            NavigationLink {
                NewTaskView(tasks: $tasks, onTaskCreated: onTaskCreated)
            } label: {
                Text("Or create a new task")
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
                Text("Add")
            }
            .disabled(selectedTaskID == nil)
            .opacity(selectedTaskID == nil ? 0.6 : 1)

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
        case .work:
            base = [.work]
        case .personal:
            base = [.personal]
        }
        return base.filter { !filteredTasks(for: $0).isEmpty }
    }

    private func filteredTasks(for category: TaskCategory) -> [TaskItem] {
        tasks.filter { category.matches(tag: $0.tag) }
    }

    private func toggleSelection(for id: UUID) {
        if selectedTaskID == id {
            selectedTaskID = nil
        } else {
            selectedTaskID = id
        }
    }

    private func addSelectedTask() {
        guard let selectedID = selectedTaskID,
              let template = tasks.first(where: { $0.id == selectedID }) else {
            return
        }

        let newTask = TaskItem(
            title: template.title,
            tag: template.tag,
            trackedTime: 0,
            detail: template.detail
        )
        tasks.append(newTask)
        onTaskCreated?(newTask)
        selectedTaskID = nil
        dismiss()
    }
}

enum TaskCategory: String, CaseIterable, Identifiable {
    case work
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        }
    }

    var color: Color {
        switch self {
        case .work: return AppColor.work
        case .personal: return AppColor.personal
        }
    }

    var tag: TaskItem.Tag {
        switch self {
        case .work: return .work
        case .personal: return .personal
        }
    }

    func matches(tag: TaskItem.Tag) -> Bool {
        switch (self, tag) {
        case (.work, .work): return true
        case (.personal, .personal), (.personal, .fitness), (.personal, .youtube), (.personal, .learn): return true
        default: return false
        }
    }
}

enum TaskCategoryFilter: String, CaseIterable, Identifiable {
    case all
    case work
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All Categories"
        case .work: return "Work"
        case .personal: return "Personal"
        }
    }
}

private struct ExistingTaskCard: View {
    let task: TaskItem
    let indicatorColor: Color
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Circle()
                .strokeBorder(indicatorColor, lineWidth: 2)
                .frame(width: AppSpacing.medium, height: AppSpacing.medium)
                .overlay(
                    Circle()
                        .fill(indicatorColor.opacity(0.12))
                        .frame(width: AppSpacing.medium - AppSpacing.small, height: AppSpacing.medium - AppSpacing.small)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(task.title)
                    .font(AppFont.heading())
                    .foregroundColor(AppColor.textPrimary)

                if !task.detail.isEmpty {
                    Text(task.detail)
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
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
}

#Preview {
    AddTaskView(tasks: .constant([
        TaskItem(title: "Work on Project Dayflow", tag: .work, detail: "Finalize sprint backlog"),
        TaskItem(title: "Call with Mom", tag: .personal, detail: "Weekly check-in")
    ]))
}
