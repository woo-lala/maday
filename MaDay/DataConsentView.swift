import SwiftUI

struct DataConsentView: View {
    @State private var analyticsEnabled = true
    @State private var crashReportsEnabled = true
    @State private var personalizationEnabled = false
    @State private var thirdPartyEnabled = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                headerSection
                consentToggles
                dataInfoSection
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Data Usage & Consent")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Your Privacy Matters")
                .font(AppFont.title())
                .foregroundColor(AppColor.textPrimary)
            
            Text("Control what data you share with us. You can change these settings anytime.")
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
        }
    }
    
    private var consentToggles: some View {
        VStack(spacing: AppSpacing.medium) {
            ConsentToggleCard(
                icon: "chart.bar.fill",
                title: "Analytics",
                description: "Help us improve the app by sharing anonymous usage data.",
                isEnabled: $analyticsEnabled,
                isRecommended: true
            )
            
            ConsentToggleCard(
                icon: "ant.fill",
                title: "Crash Reports",
                description: "Automatically send crash reports to help us fix bugs.",
                isEnabled: $crashReportsEnabled,
                isRecommended: true
            )
            
            ConsentToggleCard(
                icon: "sparkles",
                title: "Personalization",
                description: "Allow us to personalize your experience based on usage patterns.",
                isEnabled: $personalizationEnabled,
                isRecommended: false
            )
            
            ConsentToggleCard(
                icon: "globe",
                title: "Third-Party Services",
                description: "Share data with third-party services for enhanced features.",
                isEnabled: $thirdPartyEnabled,
                isRecommended: false
            )
        }
    }
    
    private var dataInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("What we collect")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            VStack(spacing: AppSpacing.small) {
                DataInfoRow(
                    icon: "checkmark.shield.fill",
                    title: "Always Encrypted",
                    description: "Your task data is end-to-end encrypted"
                )
                
                DataInfoRow(
                    icon: "lock.fill",
                    title: "Never Sold",
                    description: "We never sell your personal information"
                )
                
                DataInfoRow(
                    icon: "eye.slash.fill",
                    title: "Anonymous Analytics",
                    description: "Usage data is anonymized and aggregated"
                )
            }
            .padding(AppSpacing.medium)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
            
            Button {
                // Open privacy policy
            } label: {
                HStack {
                    Text("Read Full Privacy Policy")
                        .font(AppFont.body())
                        .foregroundColor(AppColor.primary)
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundColor(AppColor.primary)
                }
            }
            .padding(.top, AppSpacing.small)
        }
    }
}

private struct ConsentToggleCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let isRecommended: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppSpacing.xSmall) {
                        Text(title)
                            .font(AppFont.headline())
                            .foregroundColor(AppColor.textPrimary)
                        
                        if isRecommended {
                            Text("•")
                                .font(AppFont.caption())
                                .foregroundColor(AppColor.textSecondary)
                            
                            Text("Recommended")
                                .font(AppFont.caption())
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }
                    
                    Text(description)
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .toggleStyle(ChubbyToggleStyle())
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.standard)
    }
}

private struct DataInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.body())
                .fontWeight(.medium)
                .foregroundColor(AppColor.textPrimary)
            
            Text(description)
                .font(AppFont.caption())
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        DataConsentView()
    }
}
