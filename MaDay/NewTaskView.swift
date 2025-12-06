import SwiftUI
import CoreData

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
    
    enum DescriptionType {
        case text
        case checklist
    }
    @State private var descriptionType: DescriptionType = .text
    @State private var checklistItems: [ChecklistItem] = []
    @State private var newChecklistItemText: String = ""

    init(tasks: Binding<[TaskItem]>, onTaskCreated: ((TaskItem) -> Void)? = nil, taskToEdit: TaskItem? = nil) {
        self._tasks = tasks
        self.onTaskCreated = onTaskCreated
        self.taskToEdit = taskToEdit

        _newTaskName = State(initialValue: taskToEdit?.title ?? "")
        _newTaskDescription = State(initialValue: taskToEdit?.detail ?? "")
        
        if let existingChecklist = taskToEdit?.checklist, !existingChecklist.isEmpty {
            _descriptionType = State(initialValue: .checklist)
            _checklistItems = State(initialValue: existingChecklist)
        } else {
            _descriptionType = State(initialValue: .text)
            _checklistItems = State(initialValue: [])
        }
        
        let initialTag = taskToEdit?.tag ?? .work
        let matchingCategory = CategoryOption.defaults.first { $0.tag == initialTag }
        _selectedCategoryId = State(initialValue: matchingCategory?.id ?? CategoryOption.defaults.first?.id)
        
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
        .navigationTitle(taskToEdit == nil ? "new_task.title.new" : "new_task.title.edit")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
    }
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("new_task.field.name")
                    .font(AppFont.callout())
                    .foregroundColor(AppColor.textSecondary)

                AppTextField("new_task.placeholder.name", text: $newTaskName)
            }

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text("new_task.field.desc")
                        .font(AppFont.callout())
                        .foregroundColor(AppColor.textSecondary)
                    
                    Spacer()
                    
                    Picker("", selection: $descriptionType) {
                        Text("Text").tag(DescriptionType.text)
                        Text("Checklist").tag(DescriptionType.checklist)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .onChange(of: descriptionType) { oldValue, newValue in
                        if newValue == .text {
                            checklistItems = []
                        } else {
                            newTaskDescription = ""
                        }
                    }
                }
                
                if descriptionType == .text {
                    AppTextEditor("new_task.placeholder.desc", text: $newTaskDescription)
                        .frame(minHeight: 120)
                } else {
                    checklistSection
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("new_task.field.category")
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
                            
                            // Category add form removed for brevity and focus on core task creation
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
                Text("new_task.field.goal")
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
                            Picker("new_task.picker.hours", selection: $goalHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour) h").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            
                            Picker("new_task.picker.minutes", selection: $goalMinutes) {
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

    private var checklistSection: some View {
        let containerBackground = RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
            .stroke(AppColor.border, lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .fill(AppColor.background)
            )
        
        return VStack(spacing: AppSpacing.small) {
            ForEach(checklistItems.indices, id: \.self) { index in
                checklistItemRow(at: index)
            }
            addChecklistItemRow
        }
        .padding(AppSpacing.small)
        .background(containerBackground)
        .frame(minHeight: 120)
    }
    
    private var addChecklistItemRow: some View {
        let isTextEmpty = newChecklistItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let buttonColor = isTextEmpty ? AppColor.textSecondary.opacity(0.5) : AppColor.primary
        let borderShape = RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
            .stroke(AppColor.border, lineWidth: 1)
        
        return HStack(spacing: AppSpacing.small) {
            AppTextField("Add item...", text: $newChecklistItemText)
                .onSubmit {
                    addChecklistItem()
                }
            
            Button {
                addChecklistItem()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(buttonColor)
            }
            .buttonStyle(.plain)
            .disabled(isTextEmpty)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
        .background(borderShape)
    }

    private func checklistItemRow(at index: Int) -> some View {
        let item = checklistItems[index]
        let itemBackground = RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
            .fill(AppColor.surface)
        
        return HStack(spacing: AppSpacing.small) {
            Button {
                checklistItems[index].isCompleted.toggle()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(item.isCompleted ? AppColor.primary : AppColor.textSecondary)
            }
            .buttonStyle(.plain)
            
            Text(item.text)
                .font(AppFont.bodyRegular())
                .foregroundColor(item.isCompleted ? AppColor.textSecondary : AppColor.textPrimary)
                .strikethrough(item.isCompleted)
            
            Spacer()
            
            Button {
                checklistItems.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.textSecondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallPlus)
        .background(itemBackground)
    }

    private var goalTimeText: String {
        if goalHours == 0 && goalMinutes == 0 {
            return NSLocalizedString("new_task.goal.none", comment: "")
        }
        return "\(goalHours)h \(goalMinutes)m"
    }

    private var saveButtonBar: some View {
        VStack(spacing: AppSpacing.small) {
            AppButton(style: .primary, action: saveTask) {
                Text("common.save")
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

        // Core Data Integration: Convert checklist to String array. Note: Template doesn't store completion state.
        var finalChecklist: [String] = []
        if descriptionType == .text {
             let text = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
             if !text.isEmpty {
                 finalChecklist = [text]
             }
        } else {
             finalChecklist = checklistItems.map { $0.text }
        }

        let totalSeconds = Int64(goalHours * 3600 + goalMinutes * 60)
        let colorHex = getColorHex(for: selectedCategory.colorId)
        
        // Ignoring Edit Mode logic for now as we focus on Creation first
        _ = CoreDataManager.shared.createTask(
            title: title,
            categoryId: UUID(), // Placeholder
            defaultGoalTime: totalSeconds,
            defaultChecklist: finalChecklist,
            color: colorHex
        )

        dismiss()
    }
    
    private func addChecklistItem() {
        let trimmedText = newChecklistItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        let newItem = ChecklistItem(text: trimmedText, isCompleted: false)
        checklistItems.append(newItem)
        newChecklistItemText = ""
    }
    
    // Helper to map colorId to hex string (Matches Color+Extension.swift and ColorChoice palette)
    private func getColorHex(for id: String) -> String {
        switch id {
        // App Default Categories (Matches DesignSystem.swift mappings)
        case "work": return "3D7AF5"
        case "personal": return "E94E3D" // mapped to mdYoutube in DesignSystem
        case "fitness": return "26BA67"
        case "learn": return "FFC23F"
        case "youtube": return "E94E3D"
        case "shopping": return "2EB97F"
        case "cooking": return "6B7280"
            
        // Custom Category Palette (from ColorChoice)
        case "emerald": return "10B981"
        case "amber": return "F59E0B"
        case "fuchsia": return "EC4899"
        case "teal": return "14B8A6"
        case "indigo": return "6366F1"
        case "rose": return "F43F5E"
        case "slate": return "64748B"
        case "lime": return "84CC16"
            
        default: return "3D7AF5" // Default fallback
        }
    }
}

// Supporting Structs
private struct CategoryOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let colorId: String
    let color: Color
    let tag: TaskItem.Tag
    let isDefault: Bool

    static let defaults: [CategoryOption] = [
        CategoryOption(name: "Work", colorId: "work", color: AppColor.work, tag: .work, isDefault: true),
        CategoryOption(name: "Personal", colorId: "personal", color: AppColor.personal, tag: .personal, isDefault: true),
        CategoryOption(name: "Fitness", colorId: "fitness", color: AppColor.fitness, tag: .fitness, isDefault: true),
        CategoryOption(name: "Learn", colorId: "learn", color: AppColor.learning, tag: .learn, isDefault: true),
        CategoryOption(name: "YouTube", colorId: "youtube", color: AppColor.youtube, tag: .youtube, isDefault: true),
        CategoryOption(name: "Cooking", colorId: "cooking", color: AppColor.cooking, tag: .cooking, isDefault: true)
    ]
}

private struct ColorChoice: Identifiable {
    let id: String
    let color: Color

    static let base: [ColorChoice] = [
        ColorChoice(id: "emerald", color: Color(red: 0.06, green: 0.73, blue: 0.51)),
        ColorChoice(id: "amber", color: Color(red: 0.96, green: 0.62, blue: 0.04)),
        ColorChoice(id: "fuchsia", color: Color(red: 0.93, green: 0.28, blue: 0.6)),
        ColorChoice(id: "teal", color: Color(red: 0.08, green: 0.72, blue: 0.65)),
        ColorChoice(id: "indigo", color: Color(red: 0.39, green: 0.4, blue: 0.9)),
        ColorChoice(id: "rose", color: Color(red: 0.96, green: 0.25, blue: 0.37)),
        ColorChoice(id: "slate", color: Color(red: 0.39, green: 0.45, blue: 0.55)),
        ColorChoice(id: "lime", color: Color(red: 0.52, green: 0.8, blue: 0.09))
    ]

    static let primaryConflictId = "azure"
}
