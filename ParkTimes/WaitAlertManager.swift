//
//  WaitAlertManager.swift
//  ParkTimes
//
//  Fires local notifications when a ride's standby wait drops to the
//  user's threshold. Checked on every foreground refresh, and in the
//  background via BGAppRefreshTask.
//

import Foundation
import BackgroundTasks
import UserNotifications

enum WaitAlertManager {
    static let backgroundTaskId = "co.brevinb.ParkTimes.refresh"

    // MARK: - Authorization

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Evaluation

    /// Checks the given live entities against saved alerts, notifies for any
    /// that triggered, and removes them (alerts are one-shot).
    @MainActor
    static func evaluate(entities: [LiveEntity]) {
        let triggered = AlertStore.triggered(by: entities, alerts: AlertStore.shared.alerts)
        guard !triggered.isEmpty else { return }

        for item in triggered {
            notify(alert: item.alert, wait: item.wait)
        }
        AlertStore.shared.remove(ids: triggered.map(\.alert.id))
    }

    private static func notify(alert: WaitAlert, wait: Int) {
        let content = UNMutableNotificationContent()
        content.title = alert.rideName
        content.body = "The wait is down to \(wait) minutes — go now!"
        content.sound = .default
        content.userInfo = ["parkId": alert.parkId, "rideId": alert.id]

        let request = UNNotificationRequest(
            identifier: "waitAlert-\(alert.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Background Refresh

    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskId, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(refreshTask)
        }
    }

    /// Background refresh serves two customers: pending wait alerts, and an
    /// active Live Activity that needs fresh waits while the app is closed.
    @MainActor
    static func scheduleBackgroundRefresh() {
        let hasAlerts = !SharedStore.loadAlerts().isEmpty
        let hasLiveActivity = LiveActivityController.shared.activeParkId != nil
        guard hasAlerts || hasLiveActivity else { return }

        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        let work = Task {
            let alerts = SharedStore.loadAlerts()
            let activeParkId = await MainActor.run { LiveActivityController.shared.activeParkId }
            let favoriteIds = Set(SharedStore.loadFavorites().map(\.id))

            var parkIds = Set(alerts.map(\.parkId))
            if let activeParkId { parkIds.insert(activeParkId) }

            for parkId in parkIds {
                guard !Task.isCancelled else { break }
                guard let entities = try? await ParkService.getLiveData(parkId: parkId) else { continue }

                await evaluate(entities: entities)

                if parkId == activeParkId {
                    await MainActor.run {
                        LiveActivityController.shared.update(
                            parkId: parkId,
                            entities: entities,
                            favoriteIds: favoriteIds
                        )
                    }
                }
            }

            await scheduleBackgroundRefresh()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
        }
    }
}
