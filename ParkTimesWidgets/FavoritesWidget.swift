//
//  FavoritesWidget.swift
//  ParkTimesWidgets
//
//  Home screen / Lock Screen widget showing current waits for the user's
//  favorite rides. Favorites are shared from the app via the App Group;
//  live waits are fetched directly by the timeline provider.
//

import WidgetKit
import SwiftUI

struct WidgetRide: Identifiable {
    let id: String
    let name: String
    let wait: Int?
    let isOpen: Bool
}

struct FavoritesEntry: TimelineEntry {
    let date: Date
    let rides: [WidgetRide]
    let hasFavorites: Bool
}

struct FavoritesProvider: TimelineProvider {
    private static let sample: [WidgetRide] = [
        WidgetRide(id: "1", name: "Space Mountain", wait: 45, isOpen: true),
        WidgetRide(id: "2", name: "Seven Dwarfs Mine Train", wait: 70, isOpen: true),
        WidgetRide(id: "3", name: "Jungle Cruise", wait: 30, isOpen: true),
    ]

    func placeholder(in context: Context) -> FavoritesEntry {
        FavoritesEntry(date: Date(), rides: Self.sample, hasFavorites: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> Void) {
        Task {
            let favorites = SharedStore.loadFavorites()
            var rides: [WidgetRide] = []

            // Widgets have a tight budget — cap the number of park fetches.
            let parkIds = Array(Set(favorites.map(\.parkId)).sorted().prefix(3))
            for parkId in parkIds {
                guard let entities = try? await ParkService.getLiveData(parkId: parkId) else { continue }
                var byId: [String: LiveEntity] = [:]
                for entity in entities { byId[entity.id] = entity }

                for favorite in favorites where favorite.parkId == parkId {
                    if let entity = byId[favorite.id] {
                        rides.append(WidgetRide(
                            id: entity.id,
                            name: entity.name,
                            wait: entity.waitTime,
                            isOpen: entity.isOpen
                        ))
                    }
                }
            }

            rides.sort { ($0.wait ?? -1) > ($1.wait ?? -1) }

            let entry = FavoritesEntry(date: Date(), rides: rides, hasFavorites: !favorites.isEmpty)
            let refresh = Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }
}

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FavoritesWidget", provider: FavoritesProvider()) { entry in
            FavoritesWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.05, green: 0.05, blue: 0.12)
                }
        }
        .configurationDisplayName("Favorite Waits")
        .description("Current wait times for your favorite rides.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct FavoritesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FavoritesEntry

    private var maxRows: Int {
        switch family {
        case .systemSmall: return 3
        case .accessoryRectangular: return 3
        default: return 4
        }
    }

    var body: some View {
        if !entry.hasFavorites {
            emptyState
        } else if family == .accessoryRectangular {
            accessoryView
        } else {
            standardView
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "star")
                .font(.title3)
                .foregroundStyle(.yellow)
            Text("Star rides in ParkTimes to see their waits here")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var standardView: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text("Favorites")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.35))
            }

            if entry.rides.isEmpty {
                Spacer()
                Text("No live data right now")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            } else {
                ForEach(entry.rides.prefix(maxRows)) { ride in
                    HStack(spacing: 6) {
                        Text(ride.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                        Spacer(minLength: 4)
                        waitBadge(ride)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var accessoryView: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(entry.rides.prefix(maxRows)) { ride in
                HStack(spacing: 4) {
                    Text(ride.name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Text(waitText(ride))
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func waitText(_ ride: WidgetRide) -> String {
        guard ride.isOpen else { return "—" }
        if let wait = ride.wait, wait > 0 { return "\(wait)m" }
        return "Walk-on"
    }

    private func waitBadge(_ ride: WidgetRide) -> some View {
        Text(waitText(ride))
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(badgeColor(ride))
            )
    }

    private func badgeColor(_ ride: WidgetRide) -> Color {
        guard ride.isOpen else { return .gray.opacity(0.5) }
        let wait = ride.wait ?? 0
        if wait < 30 { return .green.opacity(0.8) }
        if wait < 60 { return .orange.opacity(0.8) }
        return .red.opacity(0.8)
    }
}
