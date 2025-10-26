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
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    appBar
                    categoryFilter
                    existingTasksSection
                    newTaskSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text("Add Task")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
    }

    private var categoryFilter: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    filterExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Theme.primary)
                    Text(selectedFilter.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .rotationEffect(filterExpanded ? .degrees(180) : .zero)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: filterExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if filterExpanded {
                Divider()
                    .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    ForEach(TaskCategoryFilter.allCases) { filter in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                selectedFilter = filter
                                filterExpanded = false
                            }
                        } label: {
                            HStack {
                                Text(filter.title)
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Theme.primary)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.inputBorder, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                )
        )
    }

    private var existingTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Existing Tasks")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            if displayCategories.isEmpty {
                Text("No tasks in this category yet")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ForEach(displayCategories, id: \.self) { category in
                    Section {
                        VStack(spacing: 12) {
                            ForEach(filteredTasks(for: category)) { task in
                                ExistingTaskCard(task: task, indicatorColor: category.color)
                            }
                        }
                    } header: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)
                            Text(category.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.bottom, 4)
                    }
                }
            }

            Text("Or create a new task")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .padding(.top, 8)
        }
    }

    private var newTaskSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Task Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Task Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                TextField("Enter task name", text: $newTaskName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white)
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                        )

                    TextEditor(text: $newTaskDescription)
                        .frame(minHeight: 120)
                        .padding(12)
                        .scrollContentBackground(.hidden)

                    if newTaskDescription.isEmpty {
                        Text("Add a short description...")
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                VStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            categoryPickerExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(selectedCategory.color)
                                .frame(width: 8, height: 8)
                            Text(selectedCategory.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .rotationEffect(categoryPickerExpanded ? .degrees(180) : .zero)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: categoryPickerExpanded)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if categoryPickerExpanded {
                        Divider()
                            .padding(.horizontal, 16)

                        VStack(spacing: 12) {
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
                                            .frame(width: 8, height: 8)
                                        Text(category.title)
                                            .font(.system(size: 15))
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        if selectedCategory == category {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Theme.primary)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                        )
                )
            }
        }
    }

    private var saveButtonBar: some View {
        VStack(spacing: 12) {
            Button(action: saveTask) {
                Text("Save")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.primary)
                    )
            }
            .disabled(trimmedTaskName.isEmpty)
            .opacity(trimmedTaskName.isEmpty ? 0.6 : 1)

            Color.clear
                .frame(height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.white.shadow(color: Theme.shadow.opacity(0.5), radius: 4, x: 0, y: -2))
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
        print("Saved new task: \(newTask.title) (\(selectedCategory.title))")
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
        case .work: return Theme.primary
        case .personal: return Theme.secondary
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
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .strokeBorder(indicatorColor, lineWidth: 2)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .fill(indicatorColor.opacity(0.12))
                        .frame(width: 18, height: 18)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                if !task.detail.isEmpty {
                    Text(task.detail)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.shadow, radius: 2, x: 0, y: 0)
        )
    }
}

#Preview {
    AddTaskView(tasks: .constant([
        TaskItem(title: "Work on Project Dayflow", tag: .work, detail: "Finalize sprint backlog"),
        TaskItem(title: "Call with Mom", tag: .personal, detail: "Weekly check-in")
    ]))
}
