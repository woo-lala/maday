import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var tasks: [TaskItem]
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @State private var filterExpanded = false
    @State private var selectedFilter: TaskCategoryFilter = .all
    @State private var categoryPickerExpanded = false
    @State private var selectedCategory: TaskCategory = .work
    @State private var newTaskName = ""
    @State private var newTaskDescription = ""

    private var trimmedTaskName: String {
        newTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    appBar
                    categoryFilter
                    existingTasksSection
                    newTaskSection
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.medium)
                .padding(.bottom, AppSpacing.xLarge)
            }
        }
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var appBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(AppFont.heading())
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: AppMetrics.toolbarIconSize, height: AppMetrics.toolbarIconSize)
            }

            Spacer()

            Text("Add Task")
                .font(AppFont.title())
                .foregroundColor(AppColor.textPrimary)

            Spacer()

            Spacer()
                .frame(width: AppMetrics.toolbarIconSize)
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
                                ExistingTaskCard(task: task, indicatorColor: category.color)
                            }
                        }
                    } header: {
                        AppSectionHeader(title: category.title, indicatorColor: category.color)
                            .padding(.bottom, AppSpacing.xSmall)
                    }
                }
            }

            Text("Or create a new task")
                .font(AppFont.caption())
                .foregroundColor(AppColor.textSecondary)
        }
    }

    private var newTaskSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("New Task Details")
                .sectionTitleStyle()

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Task Name")
                    .font(AppFont.callout())
                    .foregroundColor(AppColor.textSecondary)

                AppTextField("Enter task name", text: $newTaskName)
            }

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Description")
                    .font(AppFont.callout())
                    .foregroundColor(AppColor.textSecondary)

                AppTextEditor("Add a short description...", text: $newTaskDescription)
                    .frame(minHeight: 120)
            }

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Category")
                    .font(AppFont.callout())
                    .foregroundColor(AppColor.textSecondary)

                VStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            categoryPickerExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: AppSpacing.small) {
                            Circle()
                                .fill(selectedCategory.color)
                                .frame(width: AppSpacing.small, height: AppSpacing.small)
                            Text(selectedCategory.title)
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(AppFont.caption())
                                .foregroundColor(AppColor.textSecondary)
                                .rotationEffect(categoryPickerExpanded ? .degrees(180) : .zero)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: categoryPickerExpanded)
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                    }
                    .buttonStyle(.plain)

                    if categoryPickerExpanded {
                        Divider()
                            .padding(.horizontal, AppSpacing.medium)

                        VStack(spacing: AppSpacing.smallPlus) {
                            ForEach(TaskCategory.allCases) { category in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        selectedCategory = category
                                        categoryPickerExpanded = false
                                    }
                                } label: {
                                    HStack {
                                        Circle()
                                            .fill(category.color)
                                            .frame(width: AppSpacing.small, height: AppSpacing.small)
                                        Text(category.title)
                                            .font(AppFont.bodyRegular())
                                            .foregroundColor(AppColor.textPrimary)
                                        Spacer()
                                        if selectedCategory == category {
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
        }
    }

    private var saveButtonBar: some View {
        VStack(spacing: AppSpacing.small) {
            AppButton(style: .primary, action: saveTask) {
                Text("Save")
            }
            .disabled(trimmedTaskName.isEmpty)
            .opacity(trimmedTaskName.isEmpty ? 0.6 : 1)

            AppColor.clear
                .frame(height: AppSpacing.xSmall)
        }
        .padding(.horizontal, AppSpacing.medium)
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

    private func saveTask() {
        let title = trimmedTaskName
        guard !title.isEmpty else { return }

        let details = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTask = TaskItem(title: title, tag: selectedCategory.tag, trackedTime: 0, detail: details)
        tasks.append(newTask)
        onTaskCreated?(newTask)

        newTaskName = ""
        newTaskDescription = ""
        dismiss()
    }
}

private enum TaskCategory: String, CaseIterable, Identifiable {
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
        case .work: return AppColor.primary
        case .personal: return AppColor.secondary
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

private enum TaskCategoryFilter: String, CaseIterable, Identifiable {
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
                .fill(AppColor.surface)
                .shadow(color: AppShadow.card, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }
}

#Preview {
    AddTaskView(tasks: .constant([
        TaskItem(title: "Work on Project Dayflow", tag: .work, detail: "Finalize sprint backlog"),
        TaskItem(title: "Call with Mom", tag: .personal, detail: "Weekly check-in")
    ]))
    .background(AppColor.background)
}
