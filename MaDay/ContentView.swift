//
//  ContentView.swift
//  MaDay
//
//  Created by woolala on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "globe")
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.primary)

            Text("Hello, world!")
                .font(AppFont.body())
                .foregroundColor(AppColor.textPrimary)
        }
        .padding(AppSpacing.large)
        .background(AppColor.background)
    }
}

#Preview {
    ContentView()
}
