import SwiftUI

struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    // If nil, we are adding. If not nil, we are editing.
    var categoryToEdit: CategoryEntity?
    
    @State private var categoryName: String = ""
    @State private var selectedColor: Color = AppColor.work
    
    var onSave: (String, String) -> Void // name, colorHex
    
    private let availablePalette: [ColorChoice] = ColorChoice.fixed
    
    init(category: CategoryEntity? = nil, onSave: @escaping (String, String) -> Void) {
        self.categoryToEdit = category
        self.onSave = onSave
        
        if let category = category {
            _categoryName = State(initialValue: category.name ?? "")
            let hex = category.color ?? "3D7AF5"
            _selectedColor = State(initialValue: Color(hex: hex))
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                    // Category Name Section
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("new_task.category.add.name")
                            .font(AppFont.callout())
                            .foregroundColor(AppColor.textSecondary)
                        
                        AppTextField("new_task.category.placeholder.name", text: $categoryName)
                    }
                    
                    // Color Selection Section
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("new_task.field.category") // Reusing "Category" or could use a "Color" key
                            .font(AppFont.callout())
                            .foregroundColor(AppColor.textSecondary)
                        
                        HStack(spacing: AppSpacing.xSmall) {
                            ForEach(availablePalette) { choice in
                                Circle()
                                    .fill(choice.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(choice.id == selectedHex ? AppColor.primaryStrong : AppColor.border, lineWidth: choice.id == selectedHex ? 2 : 1)
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedColor = choice.color
                                        }
                                    }
                            }
                            
                            ColorPicker("", selection: $selectedColor)
                                .labelsHidden()
                                .frame(width: 30, height: 30)
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.mediumPlus)
            }
            .navigationTitle(categoryToEdit == nil ? "new_task.category.add.button" : "common.edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        let hex = selectedColor.toHex() ?? "3D7AF5"
                        onSave(categoryName, hex)
                        dismiss()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var selectedHex: String {
        selectedColor.toHex() ?? "custom"
    }
}

struct ColorChoice: Identifiable {
    let id: String
    let color: Color

    static let fixed: [ColorChoice] = [
        ColorChoice(id: "blue", color: Color(hex: "3D7AF5")),
        ColorChoice(id: "green", color: Color(hex: "26BA67")),
        ColorChoice(id: "yellow", color: Color(hex: "FFC23F")),
        ColorChoice(id: "orange", color: Color(hex: "FF9500")),
        ColorChoice(id: "red", color: Color(hex: "FF3B30"))
    ]
}
