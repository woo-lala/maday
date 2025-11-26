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
                    NavigationStack {
                        ReportView()
                    }
                case .settings:
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            .padding(.bottom, AppSpacing.mediumPlus + AppMetrics.buttonHeight) // space for tab bar

            CommonTabBar(selectedTab: $selectedTab)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(AppColor.background.ignoresSafeArea())
    }
}



#Preview {
    ContentView()
}
