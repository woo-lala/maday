//
//  MaDayApp.swift
//  MaDay
//
//  Created by woolala on 10/26/25.
//

import SwiftUI

@main
struct MaDayApp: App {
    @StateObject private var timerViewModel = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerViewModel)
        }
    }
}
