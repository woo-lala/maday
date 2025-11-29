import SwiftUI

struct NewTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var tasks: [TaskItem]
    var onTaskCreated: ((TaskItem) -> Void)? = nil
    var taskToEdit: TaskItem? = nil
    
    @State private var newTaskName: String
    @State private var newTaskDescription: String
    @State private var categoryOptions: [CategoryOption] = CategoryOption.defaults
    @State private var selectedCategoryId: UUID?
    @State private var categoryPickerExpanded = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor: Color = TaskItem.Tag.work.color
    @State private var newCategoryColorId: String = "work"
    @State private var showAddCategoryForm = false

    @State private var goalHours: Int = 0
    @State private var goalMinutes: Int = 0
    @State private var showGoalTimePicker = false

    init(tasks: Binding<[TaskItem]>, onTaskCreated: ((TaskItem) -> Void)? = nil, taskToEdit: TaskItem? = nil) {
        self._tasks = tasks
        self.onTaskCreated = onTaskCreated
        self.taskToEdit = taskToEdit

        _newTaskName = State(initialValue: taskToEdit?.title ?? "")
        _newTaskDescription = State(initialValue: taskToEdit?.detail ?? "")
        
        // Determine initial category selection
        let initialTag = taskToEdit?.tag ?? .work
        let matchingCategory = CategoryOption.defaults.first { $0.tag == initialTag }
        _selectedCategoryId = State(initialValue: matchingCategory?.id ?? CategoryOption.defaults.first?.id)
        
        // Determine initial goal time
        if let goal = taskToEdit?.goalTime {
            let totalMinutes = Int(goal) / 60
            _goalHours = State(initialValue: totalMinutes / 60)
            _goalMinutes = State(initialValue: totalMinutes % 60)
        } else {
            _goalHours = State(initialValue: 0)
            _goalMinutes = State(initialValue: 0)
        }
    }

    private var trimmedTaskName: String {
        newTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedCategory: CategoryOption? {
        categoryOptions.first { $0.id == selectedCategoryId } ?? categoryOptions.first
    }

    private var availablePalette: [ColorChoice] {
        let used = Set(categoryOptions.map { $0.colorId })
        let excluded = used.union([ColorChoice.primaryConflictId])
        return Array(ColorChoice.base.filter { !excluded.contains($0.id) }.prefix(4))
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    formSection
                }
                .padding(.horizontal, AppSpacing.mediumPlus)
                .padding(.top, AppSpacing.large)
                .padding(.bottom, AppSpacing.xLarge)
            }
        }
        .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
    }
    
    // ... (formSection stays same)

    private var formSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
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
                    HStack(spacing: AppSpacing.small) {
                        Circle()
                            .fill(selectedCategory?.color ?? AppColor.primary)
                            .frame(width: AppSpacing.small, height: AppSpacing.small)
                        Text(selectedCategory?.name ?? "")
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: categoryPickerExpanded ? "chevron.up" : "chevron.down")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.smallPlus)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            categoryPickerExpanded.toggle()
                        }
                    }

                    if categoryPickerExpanded {
                        Divider()
                            .padding(.horizontal, AppSpacing.medium)

                        VStack(spacing: AppSpacing.smallPlus) {
                            ForEach(categoryOptions) { category in
                                HStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: AppSpacing.small, height: AppSpacing.small)
                                    Text(category.name)
                                        .font(AppFont.bodyRegular())
                                        .foregroundColor(AppColor.textPrimary)
                                    Spacer()
                                    if selectedCategoryId == category.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColor.primary)
                                        .font(AppFont.caption())
                                    }
                                }
                                .padding(.horizontal, AppSpacing.small)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        selectedCategoryId = category.id
                                        categoryPickerExpanded = false
                                        showAddCategoryForm = false
                                    }
                                }
                            }

                            if showAddCategoryForm {
                                VStack(alignment: .leading, spacing: AppSpacing.small) {
                                    HStack(spacing: AppSpacing.small) {
                                        AppTextField("Name", text: $newCategoryName)

                                        HStack(spacing: AppSpacing.xSmall) {
                                            ForEach(availablePalette) { choice in
                                                Circle()
                                                    .fill(choice.color)
                                                    .frame(width: 24, height: 24)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(choice.id == newCategoryColorId ? AppColor.primaryStrong : AppColor.border, lineWidth: choice.id == newCategoryColorId ? 2 : 1)
                                                    )
                                                    .shadow(color: choice.id == newCategoryColorId ? AppColor.primary.opacity(0.25) : .clear, radius: choice.id == newCategoryColorId ? 3 : 0, x: 0, y: 1)
                                                    .onTapGesture {
                                                        newCategoryColor = choice.color
                                                        newCategoryColorId = choice.id
                                                    }
                                            }
                                        }
                                        .padding(.horizontal, AppSpacing.xSmall)
                                    }

                                    HStack(spacing: AppSpacing.small) {
                                        Button(action: addCategory) {
                                            Text("Add")
                                                .font(AppFont.button())
                                                .frame(maxWidth: .infinity)
                                                .frame(height: AppMetrics.buttonHeight)
                                                .foregroundColor(AppColor.white)
                                                .background(
                                                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                                        .fill(AppColor.primary)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                                showAddCategoryForm = false
                                                newCategoryName = ""
                                            }
                                        } label: {
                                            Text("Cancel")
                                                .font(AppFont.button())
                                                .frame(height: AppMetrics.buttonHeight)
                                                .foregroundColor(AppColor.textSecondary)
                                                .padding(.horizontal, AppSpacing.medium)
                                                .background(
                                                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                                        .stroke(AppColor.border, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        prepareAddCategoryForm()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppColor.white)
                                        Text("Add Category")
                                            .font(AppFont.body())
                                            .foregroundColor(AppColor.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                            .fill(AppColor.primary)
                                    )
                                    .padding(.horizontal, AppSpacing.small)
                                }
                                .buttonStyle(.plain)
                                .disabled(availablePalette.isEmpty)
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
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Goal Time (Optional)")
                    .font(AppFont.callout())
                    .foregroundColor(AppColor.textSecondary)

                VStack(spacing: 0) {
                    HStack {
                        Text(goalTimeText)
                            .font(AppFont.body())
                            .foregroundColor(goalHours == 0 && goalMinutes == 0 ? AppColor.textSecondary : AppColor.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: showGoalTimePicker ? "chevron.up" : "chevron.down")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.smallPlus)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showGoalTimePicker.toggle()
                        }
                    }
                    
                    if showGoalTimePicker {
                        Divider()
                            .padding(.horizontal, AppSpacing.medium)
                        
                        HStack {
                            Picker("Hours", selection: $goalHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour) h").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            
                            Picker("Minutes", selection: $goalMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute) m").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
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

    private var goalTimeText: String {
        if goalHours == 0 && goalMinutes == 0 {
            return "No Goal (Stopwatch Mode)"
        }
        return "\(goalHours)h \(goalMinutes)m"
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
        .padding(.horizontal, AppSpacing.mediumPlus)
        .padding(.top, AppSpacing.smallPlus)
        .padding(.bottom, AppSpacing.small)
        .background(AppColor.surface.shadow(color: AppShadow.card.opacity(0.5), radius: 4, x: 0, y: -2))
    }

    private func saveTask() {
        let title = trimmedTaskName
        guard !title.isEmpty else { return }

        guard let selectedCategory else { return }

        let details = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var goalTime: TimeInterval? = nil
        if goalHours > 0 || goalMinutes > 0 {
            goalTime = TimeInterval(goalHours * 3600 + goalMinutes * 60)
        }
        
        if let editingTask = taskToEdit, let index = tasks.firstIndex(where: { $0.id == editingTask.id }) {
            // Update existing task
            var updatedTask = tasks[index]
            updatedTask.title = title
            updatedTask.detail = details
            updatedTask.tag = selectedCategory.tag
            updatedTask.categoryTitle = selectedCategory.name
            updatedTask.categoryColor = selectedCategory.color
            updatedTask.goalTime = goalTime
            
            tasks[index] = updatedTask
            onTaskCreated?(updatedTask)
        } else {
            // Create new task
            let newTask = TaskItem(
                title: title,
                tag: selectedCategory.tag,
                trackedTime: 0,
                detail: details,
                isCompleted: false,
                categoryTitle: selectedCategory.name,
                categoryColor: selectedCategory.color,
                goalTime: goalTime
            )
            tasks.append(newTask)
            onTaskCreated?(newTask)
        }

        dismiss()
    }



}

private struct CategoryOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let colorId: String
    let color: Color
    let tag: TaskItem.Tag
    let isDefault: Bool

    static let defaults: [CategoryOption] = [
        CategoryOption(name: "Work", colorId: "work", color: TaskItem.Tag.work.color, tag: .work, isDefault: true),
        CategoryOption(name: "Personal", colorId: "personal", color: TaskItem.Tag.personal.color, tag: .personal, isDefault: true),
        CategoryOption(name: "Fitness", colorId: "fitness", color: TaskItem.Tag.fitness.color, tag: .fitness, isDefault: true),
        CategoryOption(name: "Learn", colorId: "learn", color: TaskItem.Tag.learn.color, tag: .learn, isDefault: true),
        CategoryOption(name: "YouTube", colorId: "youtube", color: TaskItem.Tag.youtube.color, tag: .youtube, isDefault: true),
        CategoryOption(name: "Cooking", colorId: "cooking", color: TaskItem.Tag.cooking.color, tag: .cooking, isDefault: true)
    ]
}

private struct ColorChoice: Identifiable {
    let id: String
    let color: Color

    static let base: [ColorChoice] = [
        ColorChoice(id: "emerald", color: Color(hex: "10B981")),
        ColorChoice(id: "amber", color: Color(hex: "F59E0B")),
        ColorChoice(id: "fuchsia", color: Color(hex: "EC4899")),
        ColorChoice(id: "teal", color: Color(hex: "14B8A6")),
        ColorChoice(id: "indigo", color: Color(hex: "6366F1")),
        ColorChoice(id: "rose", color: Color(hex: "F43F5E")),
        ColorChoice(id: "slate", color: Color(hex: "64748B")),
        ColorChoice(id: "lime", color: Color(hex: "84CC16"))
    ]

    static let primaryConflictId = "azure"
}

private extension NewTaskView {
    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let option = CategoryOption(name: name, colorId: newCategoryColorId, color: newCategoryColor, tag: .personal, isDefault: false)
        categoryOptions.append(option)
        selectedCategoryId = option.id
        newCategoryName = ""
        showAddCategoryForm = false
        categoryPickerExpanded = false
    }

    private func prepareAddCategoryForm() {
        if let first = availablePalette.first {
            newCategoryColor = first.color
            newCategoryColorId = first.id
        }
        showAddCategoryForm = true
    }

}

#Preview {
    NavigationStack {
        NewTaskView(tasks: .constant([
            TaskItem(title: "Preview Task", tag: .work, detail: "Preview details")
        ]))
    }
}
