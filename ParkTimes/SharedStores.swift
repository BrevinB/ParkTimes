//
//  SharedStores.swift
//  ParkTimes
//
//  Persistence shared between the app and the widget extension via the
//  App Group container.
//

import Foundation

// MARK: - Shared Store (App Group)

enum SharedStore {
    static let appGroupId = "group.co.brevinb.ParkTimes"

    /// Falls back to standard defaults if the app group isn't provisioned,
    /// so the app still works even when entitlements are missing.
    static let defaults: UserDefaults = UserDefaults(suiteName: appGroupId) ?? .standard

    private static let favoritesKey = "favorites.v1"
    private static let alertsKey = "waitAlerts.v1"

    static func loadFavorites() -> [FavoriteRide] {
        guard let data = defaults.data(forKey: favoritesKey) else { return [] }
        return (try? JSONDecoder().decode([FavoriteRide].self, from: data)) ?? []
    }

    static func saveFavorites(_ favorites: [FavoriteRide]) {
        defaults.set((try? JSONEncoder().encode(favorites)) ?? Data(), forKey: favoritesKey)
    }

    static func loadAlerts() -> [WaitAlert] {
        guard let data = defaults.data(forKey: alertsKey) else { return [] }
        return (try? JSONDecoder().decode([WaitAlert].self, from: data)) ?? []
    }

    static func saveAlerts(_ alerts: [WaitAlert]) {
        defaults.set((try? JSONEncoder().encode(alerts)) ?? Data(), forKey: alertsKey)
    }
}

// MARK: - Favorites

struct FavoriteRide: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let parkId: String
    let parkName: String
}

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favorites: [FavoriteRide]

    var ids: Set<String> { Set(favorites.map(\.id)) }

    private init() {
        favorites = SharedStore.loadFavorites()
    }

    func isFavorite(_ rideId: String) -> Bool {
        favorites.contains { $0.id == rideId }
    }

    func toggle(ride: LiveEntity, park: ParkModel) {
        if isFavorite(ride.id) {
            favorites.removeAll { $0.id == ride.id }
        } else {
            favorites.append(FavoriteRide(id: ride.id, name: ride.name, parkId: park.id, parkName: park.name))
        }
        SharedStore.saveFavorites(favorites)
    }
}

// MARK: - Wait Alerts

struct WaitAlert: Codable, Identifiable, Equatable {
    let id: String          // ride id
    let rideName: String
    let parkId: String
    let threshold: Int      // notify when standby wait <= threshold
}

@MainActor
final class AlertStore: ObservableObject {
    static let shared = AlertStore()

    @Published private(set) var alerts: [WaitAlert]

    private init() {
        alerts = SharedStore.loadAlerts()
    }

    func threshold(for rideId: String) -> Int? {
        alerts.first { $0.id == rideId }?.threshold
    }

    func set(threshold: Int?, ride: LiveEntity, park: ParkModel) {
        alerts.removeAll { $0.id == ride.id }
        if let threshold {
            alerts.append(WaitAlert(id: ride.id, rideName: ride.name, parkId: park.id, threshold: threshold))
        }
        SharedStore.saveAlerts(alerts)
    }

    func remove(ids: [String]) {
        guard !ids.isEmpty else { return }
        alerts.removeAll { ids.contains($0.id) }
        SharedStore.saveAlerts(alerts)
    }

    /// Alerts whose condition is met by the given live entities.
    nonisolated static func triggered(by entities: [LiveEntity], alerts: [WaitAlert]) -> [(alert: WaitAlert, wait: Int)] {
        var byId: [String: LiveEntity] = [:]
        for entity in entities { byId[entity.id] = entity }

        return alerts.compactMap { alert in
            guard let entity = byId[alert.id],
                  entity.isOpen,
                  let wait = entity.waitTime,
                  wait <= alert.threshold else { return nil }
            return (alert, wait)
        }
    }
}
