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
        ColorChoice.fixed
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
        .onAppear {
            loadCategories()
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
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteCategory(id: category.id)
                                    } label: {
                                        Label("common.delete", systemImage: "trash")
                                    }
                                }
                            }
                            
                            if showAddCategoryForm {
                                VStack(alignment: .leading, spacing: AppSpacing.small) {
                                    AppTextField("new_task.category.placeholder.name", text: $newCategoryName)
                                    
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
                                        
                                        ColorPicker("", selection: Binding(get: {
                                            newCategoryColor
                                        }, set: { newVal in
                                            newCategoryColor = newVal
                                            newCategoryColorId = "custom-\(UUID().uuidString)"
                                        }))
                                        .labelsHidden()
                                        .frame(width: 30, height: 30)
                                    }
                                    
                                    HStack(spacing: AppSpacing.small) {
                                        Button {
                                            addCategory()
                                        } label: {
                                            Text("add_task.category.add")
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
                                            Text("common.cancel")
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
                                .padding(.horizontal, AppSpacing.medium)
                                .padding(.bottom, AppSpacing.smallPlus)
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
                                        Text("add_task.category.add_button")
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

        // Core Data Integration: Persist either text OR checklist (most recent mode only).
        var finalChecklist: [String] = []
        var descriptionText: String? = nil
        if descriptionType == .text {
            let text = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                descriptionText = text
            }
        } else {
            finalChecklist = checklistItems.map { $0.text }
            descriptionText = nil
        }

        let totalSeconds = Int64(goalHours * 3600 + goalMinutes * 60)
        let colorHex = getColorHex(for: selectedCategory.colorId)
        let categories = CoreDataManager.shared.fetchCategories()
        let chosenCategory = categories.first { $0.id == selectedCategory.id }
        let categoryEntity = chosenCategory ?? CoreDataManager.shared.createCategory(name: selectedCategory.name, color: colorHex, order: Int16(categories.count))
        
        _ = CoreDataManager.shared.createTask(
            title: title,
            category: categoryEntity,
            defaultGoalTime: totalSeconds,
            defaultChecklist: finalChecklist,
            color: colorHex,
            descriptionText: descriptionText,
            usesChecklist: descriptionType == .checklist
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
    
    private func loadCategories() {
        let categories = CoreDataManager.shared.fetchCategories()
        if categories.isEmpty {
            let defaults = CategoryOption.defaults
            for (idx, opt) in defaults.enumerated() {
                _ = CoreDataManager.shared.createCategory(name: opt.name, color: getColorHex(for: opt.colorId), order: Int16(idx))
            }
            let seeded = CoreDataManager.shared.fetchCategories()
            categoryOptions = seeded.map { CategoryOption(entity: $0) }
            selectedCategoryId = seeded.first?.id
        } else {
            categoryOptions = categories.map { CategoryOption(entity: $0) }
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }
        }
    }
    
    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let categories = CoreDataManager.shared.fetchCategories()
        let newOrder = Int16(categories.count)
        let newEntity = CoreDataManager.shared.createCategory(name: name, color: getColorHex(for: newCategoryColorId), order: newOrder)
        let option = CategoryOption(entity: newEntity)
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
    
    private func deleteCategory(id: UUID) {
        let categories = CoreDataManager.shared.fetchCategories()
        guard let target = categories.first(where: { $0.id == id }) else { return }
        CoreDataManager.shared.deleteCategory(target)
        categoryOptions.removeAll { $0.id == id }
        if selectedCategoryId == id {
            selectedCategoryId = categoryOptions.first?.id
        }
    }
    
    // Helper to map colorId to hex string (Matches fixed palette + defaults)
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
        case "blue": return "3D7AF5"
        case "green": return "26BA67"
        case "yellow": return "FFC23F"
        case "orange": return "FF9500"
        case "red": return "FF3B30"
        default: return "3D7AF5" // Default fallback
        }
    }
}

// Supporting Structs
private struct CategoryOption: Identifiable, Hashable {
    let id: UUID
    let name: String
    let colorId: String
    let color: Color
    let tag: TaskItem.Tag
    let isDefault: Bool

    static let defaults: [CategoryOption] = [
        CategoryOption(id: UUID(), name: "Work", colorId: "work", color: AppColor.work, tag: .work, isDefault: true),
        CategoryOption(id: UUID(), name: "Personal", colorId: "personal", color: AppColor.personal, tag: .personal, isDefault: true),
        CategoryOption(id: UUID(), name: "Fitness", colorId: "fitness", color: AppColor.fitness, tag: .fitness, isDefault: true),
        CategoryOption(id: UUID(), name: "Learn", colorId: "learn", color: AppColor.learning, tag: .learn, isDefault: true),
        CategoryOption(id: UUID(), name: "YouTube", colorId: "youtube", color: AppColor.youtube, tag: .youtube, isDefault: true),
        CategoryOption(id: UUID(), name: "Cooking", colorId: "cooking", color: AppColor.cooking, tag: .cooking, isDefault: true)
    ]

    init(id: UUID = UUID(), name: String, colorId: String, color: Color, tag: TaskItem.Tag, isDefault: Bool) {
        self.id = id
        self.name = name
        self.colorId = colorId
        self.color = color
        self.tag = tag
        self.isDefault = isDefault
    }
    
    init(entity: CategoryEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        let hex = entity.color ?? "3D7AF5"
        self.colorId = hex
        self.color = Color(hex: hex)
        self.tag = .work
        self.isDefault = false
    }
}

private struct ColorChoice: Identifiable {
    let id: String
    let color: Color

    static let fixed: [ColorChoice] = [
        ColorChoice(id: "blue", color: Color(hex: "3D7AF5")),
        ColorChoice(id: "green", color: Color(hex: "26BA67")),
        ColorChoice(id: "yellow", color: Color(hex: "FFC23F")),
        ColorChoice(id: "orange", color: Color(hex: "FF9500")),
        ColorChoice(id: "red", color: Color(hex: "FF3B30"))
    ]

    static let primaryConflictId = "azure"
}
