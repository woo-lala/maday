//
//  ContentView.swift
//  MaDay
//
//  Created by woolala on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    RecordView(showsTabBar: false, onSelectTab: { selectedTab = $0 })
                case .report:
                    ReportView()
                case .activity:
                    RecordView(showsTabBar: false, onSelectTab: { selectedTab = $0 })
                case .settings:
                    SettingsPlaceholderView()
                }
            }
            .padding(.bottom, AppSpacing.mediumPlus + AppMetrics.buttonHeight) // space for tab bar

            CommonTabBar(selectedTab: $selectedTab)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(AppColor.background.ignoresSafeArea())
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(AppFont.title())
                .foregroundColor(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, AppSpacing.mediumPlus)
        .padding(.top, AppSpacing.large)
    }
}

#Preview {
    ContentView()
}
