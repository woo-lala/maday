import SwiftUI

struct NewTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var tasks: [TaskItem]
    var onTaskCreated: ((TaskItem) -> Void)? = nil

    @State private var newTaskName = ""
    @State private var newTaskDescription = ""
    @State private var selectedCategory: TaskCategory = .work
    @State private var categoryPickerExpanded = false

    private var trimmedTaskName: String {
        newTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
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
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
    }

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
        .padding(.horizontal, AppSpacing.mediumPlus)
        .padding(.top, AppSpacing.smallPlus)
        .padding(.bottom, AppSpacing.small)
        .background(AppColor.surface.shadow(color: AppShadow.card.opacity(0.5), radius: 4, x: 0, y: -2))
    }

    private func saveTask() {
        let title = trimmedTaskName
        guard !title.isEmpty else { return }

        let details = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTask = TaskItem(title: title, tag: selectedCategory.tag, trackedTime: 0, detail: details)
        tasks.append(newTask)
        onTaskCreated?(newTask)

        dismiss()
    }
}

#Preview {
    NavigationStack {
        NewTaskView(tasks: .constant([
            TaskItem(title: "Preview Task", tag: .work, detail: "Preview details")
        ]))
    }
}
