import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmationText = ""
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                warningSection
                consequencesSection
                confirmationSection
                deleteButton
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("delete_account.title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("delete_account.alert.title", isPresented: $showDeleteAlert) {
            Button("delete_account.alert.cancel", role: .cancel) { }
            Button("delete_account.alert.delete", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("delete_account.alert.message")
        }
    }
    
    private var warningSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("delete_account.title")
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.textPrimary)
            
            Text("delete_account.warning")
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, AppSpacing.xSmall)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.large)
    }
    
    private var consequencesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("delete_account.consequences.title")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            VStack(spacing: AppSpacing.small) {
                ConsequenceRow(icon: "checkmark.circle.fill", text: "delete_account.item.tasks")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "delete_account.item.reports")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "delete_account.item.sync")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "delete_account.item.settings")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "delete_account.item.apple_id")
            }
            .padding(AppSpacing.medium)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("delete_account.confirm.title")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            TextField("DELETE", text: $confirmationText)
                .font(AppFont.body())
                .padding(AppSpacing.medium)
                .background(AppColor.surface)
                .cornerRadius(AppRadius.standard)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
        }
    }
    
    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            HStack {
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("delete_account.button")
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .fill(canDelete ? AppColor.destructive : AppColor.border.opacity(0.3))
            )
            .foregroundColor(.white)
        }
        .disabled(!canDelete || isDeleting)
        .padding(.top, AppSpacing.medium)
    }
    
    private var canDelete: Bool {
        confirmationText.uppercased() == "DELETE"
    }
    
    private func performDelete() {
        isDeleting = true
        
        // Simulate deletion process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isDeleting = false
            // In real app, perform actual deletion and sign out
            dismiss()
        }
    }
}

private struct ConsequenceRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColor.textSecondary)
                .frame(width: 20)
            
            Text(LocalizedStringKey(text))
                .font(AppFont.body())
                .foregroundColor(AppColor.textPrimary)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
    }
}
