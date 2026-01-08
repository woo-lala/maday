import SwiftUI
import CoreData

struct EditDailyTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dailyTask: DailyTaskEntity
    var onSaved: (() -> Void)? = nil
    
    @State private var taskTitle: String
    @State private var newTaskDescription: String
    @State private var categoryOptions: [CategoryOption] = []
    @State private var selectedCategoryId: UUID?
    @State private var categoryPickerExpanded = false
    @State private var showCategoryEditor = false
    @State private var categoryToEdit: CategoryEntity? = nil
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
    
    init(dailyTask: DailyTaskEntity, onSaved: (() -> Void)? = nil) {
        self.dailyTask = dailyTask
        self.onSaved = onSaved
        
        _taskTitle = State(initialValue: dailyTask.title ?? dailyTask.task?.title ?? "Untitled")
        _newTaskDescription = State(initialValue: dailyTask.descriptionText ?? "")
        
        let texts = dailyTask.checklistTexts ?? dailyTask.task?.defaultChecklist ?? []
        let states = dailyTask.checklistState ?? Array(repeating: false, count: texts.count)
        if !texts.isEmpty {
            let items: [ChecklistItem] = texts.enumerated().map { idx, text in
                ChecklistItem(text: text, isCompleted: states.indices.contains(idx) ? states[idx] : false)
            }
            _descriptionType = State(initialValue: dailyTask.usesChecklist ? .checklist : .text)
            _checklistItems = State(initialValue: items)
        } else {
            _descriptionType = State(initialValue: .text)
            _checklistItems = State(initialValue: [])
        }
        
        let totalMinutes = Int(dailyTask.goalTime) / 60
        _goalHours = State(initialValue: totalMinutes / 60)
        _goalMinutes = State(initialValue: totalMinutes % 60)
        
        _selectedCategoryId = State(initialValue: dailyTask.categoryId ?? dailyTask.task?.category?.id)
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

                AppTextField("new_task.placeholder.name", text: $taskTitle)
                    .disabled(false)
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
    
    private var selectedCategory: CategoryOption? {
        categoryOptions.first { $0.id == selectedCategoryId } ?? categoryOptions.first
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
    
    private var goalTimeText: String {
        if goalHours == 0 && goalMinutes == 0 {
            return NSLocalizedString("new_task.goal.none", comment: "")
        }
        return "\(goalHours)h \(goalMinutes)m"
    }
    
    private var saveButtonBar: some View {
        VStack(spacing: AppSpacing.small) {
            AppButton(style: .primary, action: saveChanges) {
                Text("common.save")
            }
            .opacity(1)

            AppColor.clear
                .frame(height: AppSpacing.xSmall)
        }
        .padding(.horizontal, AppSpacing.mediumPlus)
        .padding(.top, AppSpacing.smallPlus)
        .padding(.bottom, AppSpacing.small)
        .background(AppColor.surface.shadow(color: AppShadow.card.opacity(0.5), radius: 4, x: 0, y: -2))
    }
    
    private func saveChanges() {
        let totalSeconds = Int64(goalHours * 3600 + goalMinutes * 60)
        let finalChecklistState: [Bool]
        let finalChecklistTexts: [String]
        finalChecklistState = checklistItems.map { $0.isCompleted }
        finalChecklistTexts = checklistItems.map { $0.text }
        
        var finalDescription: String? = nil
        let text = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        finalDescription = text.isEmpty ? nil : text
        
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? (dailyTask.title ?? dailyTask.task?.title ?? "Untitled") : trimmedTitle
        
        let updateBlock: (_ categoryId: UUID?) -> Void = { catId in
            CoreDataManager.shared.updateDailyTask(
                dailyTask,
                realTime: dailyTask.realTime,
                isCompleted: dailyTask.isCompleted,
                checklistState: finalChecklistState,
                checklistTexts: finalChecklistTexts,
                descriptionText: finalDescription,
                priority: dailyTask.priority,
                goalTime: totalSeconds,
                categoryId: catId,
                title: finalTitle,
                usesChecklist: descriptionType == .checklist
            )
        }
        
        if let selectedCategory {
            updateBlock(selectedCategory.id)
        } else {
            updateBlock(nil)
        }
        
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

private struct CategoryOption: Identifiable {
    let id: UUID
    let name: String
    let colorId: String
    let color: Color
    let isDefault: Bool

    static let defaults: [CategoryOption] = [
        CategoryOption(id: UUID(), name: "Work", colorId: "work", color: AppColor.work, isDefault: true),
        CategoryOption(id: UUID(), name: "Personal", colorId: "personal", color: AppColor.personal, isDefault: true),
        CategoryOption(id: UUID(), name: "Fitness", colorId: "fitness", color: AppColor.fitness, isDefault: true),
        CategoryOption(id: UUID(), name: "Learn", colorId: "learn", color: AppColor.learning, isDefault: true),
        CategoryOption(id: UUID(), name: "YouTube", colorId: "youtube", color: AppColor.youtube, isDefault: true),
        CategoryOption(id: UUID(), name: "Cooking", colorId: "cooking", color: AppColor.cooking, isDefault: true)
    ]

    init(id: UUID = UUID(), name: String, colorId: String, color: Color, isDefault: Bool) {
        self.id = id
        self.name = name
        self.colorId = colorId
        self.color = color
        self.isDefault = isDefault
    }
    
    init(entity: CategoryEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        let hex = entity.color ?? "3D7AF5"
        self.colorId = hex
        self.color = Color(hex: hex)
        self.isDefault = false
    }
}

