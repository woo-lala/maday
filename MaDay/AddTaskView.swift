import SwiftUI
import CoreData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    // Legacy bindings kept for compatibility, unused for source of truth
    @Binding var tasks: [TaskItem]
    @Binding var taskLibrary: [TaskItem]
    
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @State private var selectedTaskIDs: Set<UUID> = []
    
    // Core Data State
    @State private var taskEntities: [TaskEntity] = []
    @State private var editingEntity: TaskEntity?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
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
            .onAppear {
                taskEntities = CoreDataManager.shared.fetchTasks()
            }
            .sheet(item: $editingEntity) { entity in
                // Placeholder for Edit View
                Text("Edit Task Placeholder")
            }
        }
    }

    private var existingTasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("add_task.section.existing")
                .sectionTitleStyle()

            if taskEntities.isEmpty {
                Text("add_task.empty.category")
                    .font(AppFont.bodyRegular())
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppSpacing.small)
            } else {
                LazyVStack(spacing: AppSpacing.smallPlus) {
                    ForEach(taskEntities, id: \.id) { entity in
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
            
            NavigationLink {
                NewTaskView(tasks: .constant([]))
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

    private func toggleSelection(for id: UUID) {
        if selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        } else {
            selectedTaskIDs.insert(id)
        }
    }

    private func addSelectedTask() {
        guard !selectedTaskIDs.isEmpty else { return }
        // TODO: Implement adding to Daily Tasks
        print("Selected Task IDs to add: \(selectedTaskIDs)")
        selectedTaskIDs.removeAll()
        dismiss()
    }

    private func deleteTask(_ entity: TaskEntity) {
        if let id = entity.id, selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        }
        CoreDataManager.shared.deleteTask(entity)
        taskEntities = CoreDataManager.shared.fetchTasks()
    }
}

private struct ExistingTaskCard: View {
    let entity: TaskEntity
    let isSelected: Bool
    
    @State private var isExpanded: Bool = false
    
    var title: String { entity.title ?? "" }
    var color: Color { 
        if let hex = entity.color {
            return Color(hex: hex)
        }
        return AppColor.primary 
    }
    var checkList: [String] { entity.defaultChecklist ?? [] }
    var goalTime: Int64 { entity.defaultGoalTime }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                Circle()
                    .fill(color)
                    .frame(width: AppSpacing.medium, height: AppSpacing.medium)
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
                
                Button {
                    if !checkList.isEmpty {
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
                .opacity(!checkList.isEmpty ? 1 : 0)
                .disabled(checkList.isEmpty)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
            
            if isExpanded && !checkList.isEmpty {
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
