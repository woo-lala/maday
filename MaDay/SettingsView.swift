import SwiftUI

struct SettingsView: View {
    @State private var isDailyReminderEnabled = true
    @State private var isWeeklyReportEnabled = false
    @State private var isWatchConnected = true
    @State private var showDeleteAccount = false
    @State private var showDataConsent = false
    @State private var showBackupRestore = false
    @State private var showContactSupport = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                header
                
                VStack(spacing: AppSpacing.large) {
                    accountSection
                    privacySection
                    syncSection
                    notificationsSection
                    supportSection
                }
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge + 80) // Extra padding for tab bar
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationDestination(isPresented: $showDeleteAccount) {
            DeleteAccountView()
        }
        .navigationDestination(isPresented: $showDataConsent) {
            DataConsentView()
        }
        .navigationDestination(isPresented: $showBackupRestore) {
            BackupRestoreView()
        }
        .navigationDestination(isPresented: $showContactSupport) {
            ContactSupportView()
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("settings.title")
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.textPrimary)
            
            Text("settings.subtitle")
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
        }
    }
    
    // MARK: - Sections
    
    private var accountSection: some View {
        SettingsSection(title: "settings.account.title") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "apple.logo",
                    title: "settings.account.apple_signin",
                    subtitle: "settings.account.apple_signin.desc",
                    showDivider: true
                ) {
                    Button("settings.account.connect") {
                        // Action
                    }
                    .buttonStyle(SmallButtonStyle())
                }
                
                Button {
                    showDeleteAccount = true
                } label: {
                    SettingsRow(
                        icon: "trash",
                        title: "settings.account.delete",
                        subtitle: "settings.account.delete.desc",
                        showDivider: false
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
            }
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var privacySection: some View {
        SettingsSection(title: "settings.privacy.title") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "lock",
                    title: "settings.privacy.policy",
                    subtitle: "settings.privacy.policy.desc",
                    showDivider: true
                ) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundColor(AppColor.textSecondary)
                }
                
                Button {
                    showDataConsent = true
                } label: {
                    SettingsRow(
                        icon: "person",
                        title: "settings.privacy.usage",
                        subtitle: "settings.privacy.usage.desc",
                        showDivider: true
                    ) {
                        ChevronView()
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    showBackupRestore = true
                } label: {
                    SettingsRow(
                        icon: "externaldrive",
                        title: "settings.privacy.backup",
                        subtitle: "settings.privacy.backup.desc",
                        showDivider: false
                    ) {
                        ChevronView()
                    }
                }
                .buttonStyle(.plain)
            }
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var syncSection: some View {
        SettingsSection(title: "settings.sync.title") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "applewatch",
                    title: "settings.sync.watch",
                    subtitle: isWatchConnected ? "settings.sync.connected" : "settings.sync.disconnected",
                    showDivider: true
                ) {
                    Toggle("", isOn: $isWatchConnected)
                        .labelsHidden()
                        .toggleStyle(ChubbyToggleStyle())
                }
                
                SettingsRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "settings.sync.now",
                    subtitle: "settings.sync.now.desc",
                    showDivider: false
                ) {
                    Button("settings.sync.button") {
                        // Action
                    }
                    .buttonStyle(SmallButtonStyle(isPrimary: true))
                }
            }
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var notificationsSection: some View {
        SettingsSection(title: "settings.noti.title") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell",
                    title: "settings.noti.daily",
                    subtitle: "settings.noti.daily.desc",
                    showDivider: true
                ) {
                    Toggle("", isOn: $isDailyReminderEnabled)
                        .labelsHidden()
                        .toggleStyle(ChubbyToggleStyle())
                }
                
                SettingsRow(
                    icon: "bell.badge",
                    title: "settings.noti.weekly",
                    subtitle: "settings.noti.weekly.desc",
                    showDivider: false
                ) {
                    Toggle("", isOn: $isWeeklyReportEnabled)
                        .labelsHidden()
                        .toggleStyle(ChubbyToggleStyle())
                }
            }
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var supportSection: some View {
        SettingsSection(title: "settings.support.title") {
            VStack(spacing: 0) {
                Button {
                    showContactSupport = true
                } label: {
                    SettingsRow(
                        icon: "doc.text",
                        title: "settings.support.contact",
                        subtitle: nil,
                        showDivider: true
                    ) {
                        ChevronView()
                    }
                }
                .buttonStyle(.plain)
                
                SettingsRow(
                    icon: "info.circle",
                    title: "settings.support.version",
                    subtitle: "2.4.1",
                    showDivider: false
                ) {
                    Text("2.4.1")
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
}

// MARK: - Helper Views

struct ChubbyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? AppColor.primary : AppColor.border.opacity(0.5))
                    .frame(width: 44, height: 28) // Shorter width, standard height
                
                Circle()
                    .fill(.white)
                    .padding(2)
                    .frame(width: 28, height: 28)
                    .offset(x: configuration.isOn ? 8 : -8)
                    .shadow(radius: 1, x: 0, y: 1)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - Helper Views

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(LocalizedStringKey(title))
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            content
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showDivider: Bool
    let trailing: Trailing
    
    init(icon: String, title: String, subtitle: String? = nil, showDivider: Bool = true, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showDivider = showDivider
        self.trailing = trailing()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(AppFont.body())
                        .foregroundColor(AppColor.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(LocalizedStringKey(subtitle))
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                trailing
            }
            .padding(AppSpacing.medium)
            
            if showDivider {
                Divider()
                    .padding(.leading, AppSpacing.medium + 24 + AppSpacing.medium) // Align with text
            }
        }
    }
}

private struct ChevronView: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppColor.textSecondary.opacity(0.5))
    }
}

private struct SmallButtonStyle: ButtonStyle {
    var isPrimary: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.caption())
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isPrimary ? AppColor.primary : AppColor.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColor.border, lineWidth: isPrimary ? 0 : 1)
                    )
            )
            .foregroundColor(isPrimary ? .white : AppColor.textPrimary)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

#Preview {
    SettingsView()
}
