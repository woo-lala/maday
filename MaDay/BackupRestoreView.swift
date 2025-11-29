import SwiftUI

struct BackupRestoreView: View {
    @State private var isAutoBackupEnabled = true
    @State private var lastBackupDate = Date().addingTimeInterval(-3600 * 24 * 2) // 2 days ago
    @State private var backupSize = "2.3 MB"
    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                backupStatusSection
                autoBackupSection
                manualActionsSection
                availableBackupsSection
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restore Backup?", isPresented: $showRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                performRestore()
            }
        } message: {
            Text("This will replace your current data with the backup. Current data will be lost.")
        }
    }
    
    private var backupStatusSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Last backup")
                .font(AppFont.caption())
                .foregroundColor(AppColor.textSecondary)
            
            Text(formattedDate(lastBackupDate))
                .font(AppFont.title())
                .foregroundColor(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.large)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.standard)
    }
    
    private var autoBackupSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Automatic Backup")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            VStack(spacing: 0) {
                HStack(spacing: AppSpacing.medium) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColor.textPrimary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Auto Backup")
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textPrimary)
                        
                        Text("Automatically backup your data to iCloud daily")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isAutoBackupEnabled)
                        .labelsHidden()
                        .toggleStyle(ChubbyToggleStyle())
                }
                .padding(AppSpacing.medium)
            }
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var manualActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Manual Actions")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            HStack(spacing: AppSpacing.medium) {
                Button {
                    performBackup()
                } label: {
                    VStack(spacing: AppSpacing.small) {
                        if isBackingUp {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColor.textPrimary))
                                .padding(.bottom, AppSpacing.xSmall)
                        }
                        
                        Text("Backup Now")
                            .font(AppFont.body())
                            .fontWeight(.medium)
                            .foregroundColor(AppColor.textPrimary)
                        
                        Text(backupSize)
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.large)
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.standard)
                }
                .disabled(isBackingUp || isRestoring)
                
                Button {
                    showRestoreAlert = true
                } label: {
                    VStack(spacing: AppSpacing.small) {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColor.textPrimary))
                                .padding(.bottom, AppSpacing.xSmall)
                        }
                        
                        Text("Restore")
                            .font(AppFont.body())
                            .fontWeight(.medium)
                            .foregroundColor(AppColor.textPrimary)
                        
                        Text("From backup")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.large)
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.standard)
                }
                .disabled(isBackingUp || isRestoring)
            }
        }
    }
    
    private var availableBackupsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Available Backups")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            VStack(spacing: AppSpacing.small) {
                BackupRow(
                    date: Date().addingTimeInterval(-3600 * 24 * 2),
                    size: "2.3 MB",
                    isLatest: true
                )
                
                BackupRow(
                    date: Date().addingTimeInterval(-3600 * 24 * 5),
                    size: "2.1 MB",
                    isLatest: false
                )
                
                BackupRow(
                    date: Date().addingTimeInterval(-3600 * 24 * 9),
                    size: "1.9 MB",
                    isLatest: false
                )
            }
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func performBackup() {
        isBackingUp = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isBackingUp = false
            lastBackupDate = Date()
        }
    }
    
    private func performRestore() {
        isRestoring = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRestoring = false
        }
    }
}

private struct BackupRow: View {
    let date: Date
    let size: String
    let isLatest: Bool
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.xSmall) {
                    Text(formattedDate)
                        .font(AppFont.body())
                        .foregroundColor(AppColor.textPrimary)
                    
                    if isLatest {
                        Text("•")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                        
                        Text("Latest")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
                
                Text(size)
                    .font(AppFont.caption())
                    .foregroundColor(AppColor.textSecondary)
            }
            
            Spacer()
            
            Button {
                // Download backup
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.medium)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        BackupRestoreView()
    }
}
