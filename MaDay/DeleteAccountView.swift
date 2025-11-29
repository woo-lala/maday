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
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    private var warningSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Delete Account")
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.textPrimary)
            
            Text("Once you delete your account, there is no going back. Please be certain.")
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
            Text("What will be deleted:")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            VStack(spacing: AppSpacing.small) {
                ConsequenceRow(icon: "checkmark.circle.fill", text: "All your tasks and tracked time")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "Your weekly reports and analytics")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "All synced data across devices")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "Your account settings and preferences")
                ConsequenceRow(icon: "checkmark.circle.fill", text: "Access to your Apple ID connection")
            }
            .padding(AppSpacing.medium)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Type DELETE to confirm")
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
                    Text("Delete My Account")
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
            
            Text(text)
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
