//
//  DeepLink.swift
//  ParkTimes
//
//  parktimes://park/<parkId>?name=...
//  parktimes://ride/<parkId>/<rideId>?name=...
//
//  Used by the favorites widget (widgetURL/Link) and wait-alert
//  notifications so a tap lands on the right screen, not just the home list.
//

import Foundation
import UserNotifications

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    /// Set when a link arrives; ContentView pushes it onto the navigation path.
    @Published var pendingPark: ParkModel?

    /// Ride to auto-open once that park's data has loaded.
    private var pendingRideId: String?
    private var pendingRideParkId: String?

    func handle(url: URL) {
        guard url.scheme == "parktimes" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        let name = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "name" }?.value

        switch url.host() {
        case "park" where parts.count >= 1:
            open(parkId: parts[0], rideId: nil, parkName: name)
        case "ride" where parts.count >= 2:
            open(parkId: parts[0], rideId: parts[1], parkName: name)
        default:
            break
        }
    }

    func open(parkId: String, rideId: String?, parkName: String?) {
        let known = (ParkCatalog.disneyParks + ParkCatalog.universalParks)
            .first { $0.id == parkId }
        pendingRideId = rideId
        pendingRideParkId = rideId == nil ? nil : parkId
        pendingPark = known ?? ParkModel(id: parkId, name: parkName ?? "Park", subtitle: "")
    }

    /// Called by RidesView after its data loads; one-shot.
    func consumePendingRide(for parkId: String) -> String? {
        guard pendingRideParkId == parkId, let rideId = pendingRideId else { return nil }
        pendingRideId = nil
        pendingRideParkId = nil
        return rideId
    }

    static func rideURL(parkId: String, rideId: String, parkName: String) -> URL {
        var components = URLComponents()
        components.scheme = "parktimes"
        components.host = "ride"
        components.path = "/\(parkId)/\(rideId)"
        components.queryItems = [URLQueryItem(name: "name", value: parkName)]
        return components.url!
    }
}

// MARK: - Notification Taps

final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    func attach() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let parkId = info["parkId"] as? String else { return }
        let rideId = info["rideId"] as? String
        let parkName = info["parkName"] as? String
        await MainActor.run {
            DeepLinkRouter.shared.open(parkId: parkId, rideId: rideId, parkName: parkName)
        }
    }
}
