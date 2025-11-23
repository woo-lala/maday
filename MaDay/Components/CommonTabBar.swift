import SwiftUI

enum TabItem: String, CaseIterable {
    case home, report, activity, settings

    var label: String {
        switch self {
        case .home: return "Record"
        case .report: return "Report"
        case .activity: return "Activity"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .report: return "chart.bar.xaxis"
        case .activity: return "figure.walk"
        case .settings: return "gearshape"
        }
    }
}

struct CommonTabBar: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        HStack {
            ForEach(TabItem.allCases, id: \.self) { item in
                Button {
                    selectedTab = item
                } label: {
                    VStack(spacing: AppSpacing.xSmall) {
                        Image(systemName: item.icon)
                            .font(AppFont.heading())
                        Text(item.label)
                            .font(AppFont.caption())
                    }
                    .foregroundColor(selectedTab == item ? AppColor.primary : AppColor.textSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.mediumPlus)
        .padding(.vertical, AppSpacing.smallPlus)
        .background(AppColor.surface)
    }
}

