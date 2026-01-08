import SwiftUI
import CoreData
import Combine

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    // Legacy bindings kept for compatibility, unused for source of truth
    @Binding var tasks: [TaskItem]
    @Binding var taskLibrary: [TaskItem]
    
    /// Date for which daily tasks are being created (e.g., today). Defaults to current date.
    var targetDate: Date = Date()
    
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @State private var selectedTaskIDs: Set<UUID> = []
    
    // Core Data State
    @State private var taskEntities: [TaskEntity] = []
    @State private var editingTaskID: EditingTaskKey?
    @State private var contextSaveSubscription: AnyCancellable?
    @State private var renderToken: UUID = UUID()
    
    enum Tab: String, CaseIterable {
        case all = "add_task.tab.all"
        case planned = "add_task.tab.planned"
        case recent = "add_task.tab.recent"
    }
    @State private var selectedTab: Tab = .all
    @State private var cachedRecentTaskIDs: [UUID] = [] // Ordered IDs
    
    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case category = "Category"
        case createdDesc = "Newest"
        case createdAsc = "Oldest"
        
        var id: String { rawValue }
        
        var localizedName: LocalizedStringKey {
            switch self {
            case .name: return "Name" // TODO: Localize if needed
            case .category: return "Category"
            case .createdDesc: return "Newest"
            case .createdAsc: return "Oldest"
            }
        }
    }
    @State private var sortOption: SortOption = .createdDesc

    private var filteredTaskEntities: [TaskEntity] {
        var result: [TaskEntity] = []
        
        switch selectedTab {
        case .all:
            result = taskEntities
        case .recent:
            // Maintain order from cachedRecentTaskIDs (Already sorted by "Recent Usage")
            return cachedRecentTaskIDs.compactMap { id in
                taskEntities.first(where: { $0.id == id })
            }
        case .planned:
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: targetDate) // 1=Sun, 2=Mon...
            
            result = taskEntities.filter { entity in
                // 1. Is it specifically targeted for today?
                if let tDate = entity.dueDate, calendar.isDate(tDate, inSameDayAs: targetDate) {
                    return true
                }
                // 2. Does it repeat on this weekday?
                if let repeatDays = entity.repeatDays, repeatDays.contains(weekday) {
                    return true
                }
                return false
            }
        }
        
        // Apply Sort Option (Only for All and Planned, Recent has its own logic)
        switch sortOption {
        case .name:
            return result.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .category:
            return result.sorted {
                let keyA = CategoryKey.from(entity: $0)
                let keyB = CategoryKey.from(entity: $1)
                if keyA.name == keyB.name {
                    return ($0.title ?? "") < ($1.title ?? "")
                }
                return keyA.name < keyB.name
            }
        case .createdDesc:
            return result.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        case .createdAsc:
            return result.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
        }
    }

    private var groupedTaskEntities: [CategoryGroup] {
        var order: [CategoryKey] = []
        var bucket: [CategoryKey: [TaskEntity]] = [:]

        for entity in filteredTaskEntities {
            let key = CategoryKey.from(entity: entity)
            if bucket[key] == nil {
                order.append(key)
                bucket[key] = []
            }
            bucket[key, default: []].append(entity)
        }

        return order.map { key in
            CategoryGroup(id: key.key, name: key.name, color: key.color, tasks: bucket[key] ?? [])
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        
                        HStack {
                            Text("add_task.section.existing")
                                .sectionTitleStyle()
                            
                            Spacer()
                            
                            Menu {
                                Picker("Sort By", selection: $sortOption) {
                                    ForEach(SortOption.allCases) { option in
                                        Text(option.localizedName).tag(option)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColor.textSecondary)
                            }
                        }
                        
                        Picker("", selection: $selectedTab) {
                            ForEach(Tab.allCases, id: \.self) { tab in
                                Text(NSLocalizedString(tab.rawValue, comment: "")).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // Category Filter Disabled
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
            .toolbar {
                // Toolbar items removed
            }
            .onAppear {
                refreshTasks()
                // Refresh when Core Data saves (e.g., after creating a new task)
                contextSaveSubscription = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
                    .receive(on: RunLoop.main)
                    .sink { _ in
                        refreshTasks()
                    }
            }
            .onDisappear {
                contextSaveSubscription?.cancel()
            }
            .sheet(item: $editingTaskID) { key in
                if let entity = taskEntities.first(where: { $0.id == key.id }) {
                    NavigationStack {
                        EditTaskView(task: entity) {
                            refreshTasks()
                        }
                    }
                } else {
                    Text("Task not found")
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "NewTaskView" {
                    NewTaskView(tasks: .constant([]))
                }
            }
        }
    }

    private var existingTasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {


            if filteredTaskEntities.isEmpty {
                Text(selectedTab == .planned ? "No planned tasks for this date" : "add_task.empty.category") // TODO: Localize "No planned..." if strictly needed, or reuse empty
                    .font(AppFont.bodyRegular())
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppSpacing.small)
            } else {
                LazyVStack(alignment: .leading, spacing: AppSpacing.medium) {
                    ForEach(groupedTaskEntities) { group in
                        VStack(alignment: .leading, spacing: AppSpacing.smallPlus) {
                            HStack(spacing: AppSpacing.small) {
                                Circle()
                                    .fill(group.color)
                                    .frame(width: AppSpacing.medium, height: AppSpacing.medium)
                                Text(group.name)
                                    .font(AppFont.callout())
                                    .foregroundColor(AppColor.textSecondary)
                            }
                            .padding(.horizontal, AppSpacing.small)
                            
                            LazyVStack(spacing: AppSpacing.smallPlus) {
                                ForEach(group.tasks, id: \.id) { entity in
                                    if let id = entity.id {
                                        Button {
                                            toggleSelection(for: id)
                                        } label: {
                                            ExistingTaskCard(
                                                entity: entity,
                                                isSelected: selectedTaskIDs.contains(id)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button {
                                                if let id = entity.id {
                                                    editingTaskID = EditingTaskKey(id: id)
                                                }
                                            } label: {
                                                Label("common.edit", systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive) {
                                                deleteTask(entity)
                                            } label: {
                                                Label("common.delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            

        }
        .id(renderToken)
    }

    private var saveButtonBar: some View {
        VStack(spacing: AppSpacing.small) {
            if selectedTaskIDs.isEmpty {
                NavigationLink(destination: NewTaskView(tasks: .constant([]))) {
                    Text("add_task.create_new")
                        .font(AppFont.button())
                        .frame(maxWidth: .infinity)
                        .frame(height: AppMetrics.buttonHeight)
                        .foregroundColor(AppColor.white)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .fill(AppColor.primary)
                        )
                }
            } else {
                AppButton(style: .primary) {
                    addSelectedTask()
                } label: {
                    Text("common.add")
                }
            }

            AppColor.clear
                .frame(height: AppSpacing.xSmall)
        }
        .padding(.horizontal, AppSpacing.mediumPlus)
        .padding(.top, AppSpacing.smallPlus)
        .padding(.bottom, AppSpacing.small)
        .background(AppColor.surface.shadow(color: AppShadow.card.opacity(0.5), radius: 4, x: 0, y: -2))
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
        let selectedEntities = taskEntities.filter { entity in
            if let id = entity.id {
                return selectedTaskIDs.contains(id)
            }
            return false
        }
        
        let today = Calendar.current.startOfDay(for: targetDate)
        // Determine next order based on existing daily tasks count
        let existing = CoreDataManager.shared.fetchDailyTasks(for: today)
        var nextOrder = existing.map { Int($0.order) }.max() ?? -1
        selectedEntities.forEach { template in
            nextOrder += 1
            _ = CoreDataManager.shared.createDailyTask(from: template, date: today, order: Int16(nextOrder))
        }

        selectedTaskIDs.removeAll()
        refreshTasks()
        dismiss()
    }

    private func deleteTask(_ entity: TaskEntity) {
        if let id = entity.id, selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        }
        CoreDataManager.shared.deleteTask(entity)
        refreshTasks()
    }

    private func refreshTasks() {
        taskEntities = CoreDataManager.shared.fetchTasks()
        
        // Refresh Recent List
        let recentDaily = CoreDataManager.shared.fetchRecentDailyTasks(limitDays: 3)
        // Extract unique task IDs in order of recency (most recent first)
        var seen = Set<UUID>()
        var ordered = [UUID]()
        
        for daily in recentDaily {
            if let task = daily.task, let id = task.id {
                if !seen.contains(id) {
                    seen.insert(id)
                    ordered.append(id)
                }
            }
        }
        cachedRecentTaskIDs = ordered
        
        renderToken = UUID()
    }
}

private struct EditingTaskKey: Identifiable, Equatable {
    let id: UUID
}

private struct CategoryGroup: Identifiable {
    let id: String
    let name: String
    let color: Color
    let tasks: [TaskEntity]
}

private struct CategoryKey: Hashable {
    let id: UUID?
    let name: String
    let colorHex: String

    var color: Color { Color(hex: colorHex) }
    var key: String { id?.uuidString ?? "uncategorized-\(name)" }

    static func from(entity: TaskEntity) -> CategoryKey {
        let name = entity.category?.name ?? "Uncategorized"
        let hex = entity.category?.color ?? entity.color ?? "3D7AF5"
        return CategoryKey(id: entity.category?.id, name: name, colorHex: hex)
    }
}

private struct ExistingTaskCard: View {
    let entity: TaskEntity
    let isSelected: Bool
    
    @State private var isExpanded: Bool = false
    
    var title: String { entity.title ?? "" }
    var color: Color {
        if let hex = entity.category?.color ?? entity.color {
            return Color(hex: hex)
        }
        return AppColor.primary
    }
    var checkList: [String] { entity.defaultChecklist ?? [] }
    var goalTime: Int64 { entity.defaultGoalTime }
    var descriptionText: String { entity.descriptionText ?? "" }
    var usesChecklist: Bool { entity.usesChecklist }

    init(entity: TaskEntity, isSelected: Bool) {
        self.entity = entity
        self.isSelected = isSelected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: AppSpacing.medium) {
                Circle()
                    .fill(color)
                    .frame(width: AppSpacing.small, height: AppSpacing.small)
                    .shadow(color: color.opacity(0.25), radius: 2, x: 0, y: 1)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if goalTime > 0 {
                            Text(formattedGoalTime(TimeInterval(goalTime)))
                                .font(AppFont.caption())
                                .foregroundColor(AppColor.primary)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Arrow toggle to expand/collapse details
                if (!checkList.isEmpty || !descriptionText.isEmpty) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
            
            if isExpanded && usesChecklist && !checkList.isEmpty {
                Divider()
                    .background(AppColor.border)
                    .padding(.horizontal, AppSpacing.medium)
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    ForEach(checkList, id: \.self) { item in
                        HStack(spacing: AppSpacing.small) {
                            Image(systemName: "circle")
                                .font(.system(size: 18))
                                .foregroundColor(AppColor.textSecondary)
                            
                            Text(item)
                                .font(AppFont.bodyRegular())
                                .foregroundColor(AppColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal, AppSpacing.mediumPlus)
                .padding(.vertical, AppSpacing.medium)
            }
            
            if isExpanded && !usesChecklist && !descriptionText.isEmpty {
                Divider()
                    .background(AppColor.border)
                    .padding(.horizontal, AppSpacing.medium)
                
                Text(descriptionText)
                    .font(AppFont.bodyRegular())
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.vertical, AppSpacing.medium)
            }
            
            // Fallbacks: if chosen mode is empty, show the other when available
            if isExpanded && usesChecklist && checkList.isEmpty && !descriptionText.isEmpty {
                Divider()
                    .background(AppColor.border)
                    .padding(.horizontal, AppSpacing.medium)
                
                Text(descriptionText)
                    .font(AppFont.bodyRegular())
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.horizontal, AppSpacing.mediumPlus)
                    .padding(.vertical, AppSpacing.medium)
            } else if isExpanded && !usesChecklist && descriptionText.isEmpty && !checkList.isEmpty {
                Divider()
                    .background(AppColor.border)
                    .padding(.horizontal, AppSpacing.medium)
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    ForEach(checkList, id: \.self) { item in
                        HStack(spacing: AppSpacing.small) {
                            Image(systemName: "circle")
                                .font(.system(size: 18))
                                .foregroundColor(AppColor.textSecondary)
                            
                            Text(item)
                                .font(AppFont.bodyRegular())
                                .foregroundColor(AppColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(.vertical, 2)
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
