import SwiftUI
import CoreData

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var task: TaskEntity
    var onSaved: (() -> Void)? = nil
    
    @State private var newTaskName: String
    @State private var newTaskDescription: String
    @State private var categoryOptions: [CategoryOption] = []
    @State private var selectedCategoryId: UUID?
    @State private var categoryPickerExpanded = false
    @State private var showCategoryEditor = false
    @State private var categoryToEdit: CategoryEntity? = nil

    @State private var goalHours: Int = 0
    @State private var goalMinutes: Int = 0
    @State private var showGoalTimePicker = false
    
    @State private var hasDueDate: Bool = false
    @State private var selectedDueDate: Date = Date()
    @State private var showDatePicker = false
    
    @State private var repeatDays: Set<Int> = []
    @State private var showRepeatPicker = false
    
    enum DescriptionType {
        case text
        case checklist
    }
    @State private var descriptionType: DescriptionType = .text
    @State private var checklistItems: [ChecklistItem] = []
    @State private var newChecklistItemText: String = ""

    init(task: TaskEntity, onSaved: (() -> Void)? = nil) {
        self.task = task
        self.onSaved = onSaved
        
        _newTaskName = State(initialValue: task.title ?? "")
        _newTaskDescription = State(initialValue: task.descriptionText ?? "")
        
        let defaultChecklist = task.defaultChecklist ?? []
        let hasText = !(task.descriptionText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasChecklist = !defaultChecklist.isEmpty
        // 선택 우선순위: 텍스트가 있으면 텍스트 모드, 아니면 usesChecklist, 아니면 체크리스트 존재 여부
        if hasText && !hasChecklist {
            _descriptionType = State(initialValue: .text)
        } else if task.usesChecklist && hasChecklist {
            _descriptionType = State(initialValue: .checklist)
        } else if hasText {
            _descriptionType = State(initialValue: .text)
        } else if hasChecklist {
            _descriptionType = State(initialValue: .checklist)
        } else {
            _descriptionType = State(initialValue: .text)
        }
        _checklistItems = State(initialValue: defaultChecklist.map { ChecklistItem(text: $0, isCompleted: false) })
        
        let totalMinutes = Int(task.defaultGoalTime) / 60
        _goalHours = State(initialValue: totalMinutes / 60)
        _goalMinutes = State(initialValue: totalMinutes % 60)
        
        _selectedCategoryId = State(initialValue: task.category?.id)
        
        if let dueDate = task.dueDate {
            _hasDueDate = State(initialValue: true)
            _selectedDueDate = State(initialValue: dueDate)
        }
        
        if let days = task.repeatDays {
            _repeatDays = State(initialValue: Set(days))
        }
    }

    private var trimmedTaskName: String {
        newTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedCategory: CategoryOption? {
        categoryOptions.first { $0.id == selectedCategoryId } ?? categoryOptions.first
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
        .navigationTitle("new_task.title.edit")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
        .onAppear {
            loadCategories()
        }
        .sheet(isPresented: $showCategoryEditor) {
            CategoryEditView(category: categoryToEdit) { name, colorHex in
                if let entity = categoryToEdit {
                    updateCategory(entity, name: name, colorHex: colorHex)
                } else {
                    addCategory(name: name, colorHex: colorHex)
                }
            }
            .presentationDetents([.medium])
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
                        Text("Checklist").tag(DescriptionType.checklist)
                        Text("Text").tag(DescriptionType.text)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
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
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        selectedCategoryId = category.id
                                        categoryPickerExpanded = false
                                    }
                                } label: {
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
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        prepareEditCategoryForm(category: category)
                                    } label: {
                                        Label("common.edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteCategory(id: category.id)
                                    } label: {
                                        Label("common.delete", systemImage: "trash")
                                    }
                                }
                            }
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    prepareAddCategoryForm()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColor.white)
                                    Text("new_task.category.add.button")
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
            
            // Due Date Section
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("new_task.field.target_date")
                    .font(AppFont.callout())
                    .foregroundColor(AppColor.textSecondary)

                VStack(spacing: 0) {
                    HStack {
                        if hasDueDate {
                            Text(dueDateFormatter.string(from: selectedDueDate))
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                        } else {
                            Text("new_task.target_date.none")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textSecondary)
                        }
                        
                        Spacer()
                        
                        if hasDueDate {
                            Button {
                                withAnimation {
                                    hasDueDate = false
                                    showDatePicker = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColor.textSecondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, AppSpacing.small)
                        }
                        
                        Image(systemName: "calendar")
                            .font(AppFont.body())
                            .foregroundColor(hasDueDate ? AppColor.primary : AppColor.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.smallPlus)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showDatePicker.toggle()
                            if showDatePicker && !hasDueDate {
                                hasDueDate = true
                                selectedDueDate = Date()
                            }
                        }
                    }

                    if showDatePicker {
                        Divider()
                            .padding(.horizontal, AppSpacing.medium)
                        
                        DatePicker("", selection: $selectedDueDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(AppSpacing.medium)
                            .onChange(of: selectedDueDate) { oldValue, newValue in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showDatePicker = false
                                }
                            }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                        .stroke(hasDueDate ? AppColor.primary : AppColor.border, lineWidth: hasDueDate ? 1.5 : 1)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                                .fill(AppColor.surface)
                        )
                )
            }
            
            // Repeat Section
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("new_task.field.repeat")
                    .font(AppFont.callout())
                    .foregroundColor(AppColor.textSecondary)

                VStack(spacing: 0) {
                    HStack {
                        Text(repeatSummary)
                            .font(AppFont.body())
                            .foregroundColor(repeatDays.isEmpty ? AppColor.textSecondary : AppColor.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: showRepeatPicker ? "chevron.up" : "chevron.down")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.smallPlus)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showRepeatPicker.toggle()
                        }
                    }

                    if showRepeatPicker {
                        Divider()
                            .padding(.horizontal, AppSpacing.medium)
                        
                        HStack(spacing: 0) {
                            ForEach(1...7, id: \.self) { day in
                                dayButton(for: day)
                            }
                        }
                        .padding(AppSpacing.medium)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                        .stroke(!repeatDays.isEmpty ? AppColor.primary : AppColor.border, lineWidth: !repeatDays.isEmpty ? 1.5 : 1)
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

        var finalChecklist: [String] = []
        var descriptionText: String? = nil
        let usesChecklist = descriptionType == .checklist
        // Always persist both; usesChecklist controls what is shown
        finalChecklist = checklistItems.map { $0.text }
        let text = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        descriptionText = text.isEmpty ? nil : text

        let totalSeconds = Int64(goalHours * 3600 + goalMinutes * 60)
        let colorHex = selectedCategory.color.toHex() ?? "3D7AF5"
        let categories = CoreDataManager.shared.fetchCategories()
        let chosenCategory = categories.first { $0.id == selectedCategory.id }
        let categoryEntity = chosenCategory ?? CoreDataManager.shared.createCategory(name: selectedCategory.name, color: colorHex, order: Int16(categories.count))
        
        CoreDataManager.shared.updateTask(
            task,
            title: title,
            category: categoryEntity,
            defaultGoalTime: totalSeconds,
            defaultChecklist: finalChecklist,
            color: colorHex,
            descriptionText: descriptionText,
            usesChecklist: usesChecklist,
            dueDate: hasDueDate ? selectedDueDate : nil,
            repeatDays: repeatDays.isEmpty ? nil : Array(repeatDays)
        )

        onSaved?()
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
                _ = CoreDataManager.shared.createCategory(name: opt.name, color: opt.color.toHex() ?? "3D7AF5", order: Int16(idx))
            }
            let seeded = CoreDataManager.shared.fetchCategories()
            categoryOptions = seeded.map { CategoryOption(entity: $0) }
            selectedCategoryId = selectedCategoryId ?? seeded.first?.id
        } else {
            categoryOptions = categories.map { CategoryOption(entity: $0) }
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }
        }
    }
    
    private func addCategory(name: String, colorHex: String) {
        let categories = CoreDataManager.shared.fetchCategories()
        let newOrder = Int16(categories.count)
        let newEntity = CoreDataManager.shared.createCategory(name: name, color: colorHex, order: newOrder)
        let option = CategoryOption(entity: newEntity)
        categoryOptions.append(option)
        selectedCategoryId = option.id
        categoryPickerExpanded = false
    }
    
    private func prepareAddCategoryForm() {
        categoryToEdit = nil
        showCategoryEditor = true
    }
    
    private func prepareEditCategoryForm(category: CategoryOption) {
        let categories = CoreDataManager.shared.fetchCategories()
        categoryToEdit = categories.first(where: { $0.id == category.id })
        showCategoryEditor = true
    }
    
    private func updateCategory(_ entity: CategoryEntity, name: String, colorHex: String) {
        entity.name = name
        entity.color = colorHex
        entity.updatedAt = Date()
        CoreDataManager.shared.saveContext()
        
        // Update local state
        if let index = categoryOptions.firstIndex(where: { $0.id == entity.id }) {
            categoryOptions[index] = CategoryOption(entity: entity)
        }
    }
    
    private func dayButton(for day: Int) -> some View {
        let isSelected = repeatDays.contains(day)
        let label = Calendar.current.shortWeekdaySymbols[day - 1].prefix(1)
        
        return Button {
            if isSelected {
                repeatDays.remove(day)
            } else {
                repeatDays.insert(day)
            }
        } label: {
            Text(String(label))
                .font(AppFont.caption())
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? AppColor.primary : AppColor.background)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? AppColor.primary : AppColor.border, lineWidth: 1)
                )
                .foregroundColor(isSelected ? AppColor.white : AppColor.textSecondary)
        }
        .buttonStyle(.plain)
    }
    
    private var repeatSummary: String {
        if repeatDays.isEmpty { return NSLocalizedString("new_task.repeat.none", comment: "None") }
        if repeatDays.count == 7 { return NSLocalizedString("new_task.repeat.everyday", comment: "Every day") }
        let sorted = repeatDays.sorted()
        return sorted.map { Calendar.current.shortWeekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }
    
    private var dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private func deleteCategory(id: UUID) {
        let categories = CoreDataManager.shared.fetchCategories()
        guard let target = categories.first(where: { $0.id == id }) else { return }
        CoreDataManager.shared.deleteCategory(target)
        categoryOptions.removeAll { $0.id == id }
        if selectedCategoryId == id {
            selectedCategoryId = categoryOptions.first?.id
        }
    }
}

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

