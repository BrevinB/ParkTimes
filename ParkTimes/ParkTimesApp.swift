//
//  ParkTimesApp.swift
//  ParkTimes
//
//  Created by Brevin Blalock on 8/28/23.
//

import SwiftUI

@main
struct ParkTimesApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        WaitAlertManager.registerBackgroundTask()
        NotificationRouter.shared.attach()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fontDesign(.rounded)
                .environmentObject(FavoritesStore.shared)
                .environmentObject(AlertStore.shared)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                WaitAlertManager.scheduleBackgroundRefresh()
            }
        }
    }
}
