//
//  LiveActivityController.swift
//  ParkTimes
//
//  Starts and updates a Lock Screen / Dynamic Island Live Activity showing
//  wait times for the user's favorite rides in a park (or the park's longest
//  waits if nothing is favorited). Updated whenever the app refreshes.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit

@MainActor
final class LiveActivityController: ObservableObject {
    static let shared = LiveActivityController()

    @Published private(set) var activeParkId: String?

    private var activity: Activity<ParkActivityAttributes>?

    private init() {
        // Re-adopt an activity that survived an app relaunch.
        if let existing = Activity<ParkActivityAttributes>.activities.first {
            activity = existing
            activeParkId = existing.attributes.parkId
        }
    }

    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func isActive(for parkId: String) -> Bool {
        activeParkId == parkId
    }

    func start(park: ParkModel, entities: [LiveEntity], favoriteIds: Set<String>) {
        guard isSupported else { return }

        // Replace any activity for another park.
        if activity != nil { end() }

        let attributes = ParkActivityAttributes(parkId: park.id, parkName: park.name)
        let state = contentState(entities: entities, favoriteIds: favoriteIds)

        activity = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: Date(timeIntervalSinceNow: 30 * 60))
        )
        activeParkId = activity == nil ? nil : park.id
    }

    func update(parkId: String, entities: [LiveEntity], favoriteIds: Set<String>) {
        guard let activity, activity.attributes.parkId == parkId else { return }
        let state = contentState(entities: entities, favoriteIds: favoriteIds)
        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: Date(timeIntervalSinceNow: 30 * 60))
            )
        }
    }

    func end() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
        activeParkId = nil
    }

    private func contentState(entities: [LiveEntity], favoriteIds: Set<String>) -> ParkActivityAttributes.ContentState {
        let attractions = entities.filter(\.isAttraction)
        var picked = attractions.filter { favoriteIds.contains($0.id) }
        if picked.isEmpty {
            picked = attractions
                .filter(\.isOpen)
                .sorted { ($0.waitTime ?? 0) > ($1.waitTime ?? 0) }
        }

        let rides = picked.prefix(4).map {
            ParkActivityAttributes.RideWait(id: $0.id, name: $0.name, wait: $0.waitTime, isOpen: $0.isOpen)
        }
        return ParkActivityAttributes.ContentState(rides: Array(rides), updated: Date())
    }
}
#endif
