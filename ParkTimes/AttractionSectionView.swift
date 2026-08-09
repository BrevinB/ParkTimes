//
//  AttractionSectionView.swift
//  ParkTimes
//

import SwiftUI

struct AttractionSectionView: View {
    let title: String
    let icon: String
    let color: Color
    let attractions: [LiveEntity]
    let locations: [String: EntityLocation]
    let park: ParkModel
    let timezone: TimeZone

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var isExpanded: Bool

    init(
        title: String,
        icon: String,
        color: Color,
        attractions: [LiveEntity],
        locations: [String: EntityLocation],
        park: ParkModel,
        timezone: TimeZone,
        startExpanded: Bool = true
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.attractions = attractions
        self.locations = locations
        self.park = park
        self.timezone = timezone
        _isExpanded = State(initialValue: startExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.title3)

                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("\(attractions.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.2))
                        )

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
            }
            .accessibilityLabel("\(title), \(attractions.count) items, \(isExpanded ? "expanded" : "collapsed")")

            if isExpanded {
                ForEach(attractions) { ride in
                    NavigationLink {
                        RideDetailView(
                            ride: ride,
                            location: locations[ride.id],
                            park: park,
                            timezone: timezone
                        )
                    } label: {
                        RideCardView(ride: ride, timezone: timezone)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            favoritesStore.toggle(ride: ride, park: park)
                        } label: {
                            if favoritesStore.isFavorite(ride.id) {
                                Label("Remove Favorite", systemImage: "star.slash")
                            } else {
                                Label("Add to Favorites", systemImage: "star")
                            }
                        }
                    }
                }
            }
        }
    }
}
