//
//  ParkMapView.swift
//  ParkTimes
//
//  Every attraction plotted on a map, markers colored by current wait.
//

import SwiftUI
import MapKit

struct ParkMapView: View {
    let park: ParkModel
    let entities: [LiveEntity]
    let locations: [String: EntityLocation]
    let timezone: TimeZone?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedRide: LiveEntity?
    @State private var showRides = true
    @State private var showShows = true
    @State private var showDining = false
    @State private var showRestrooms = false

    private var mappableEntities: [LiveEntity] {
        entities.filter { entity in
            guard locations[entity.id] != nil else { return false }
            switch entity.entityType {
            case .attraction: return showRides
            case .show: return showShows
            case .restaurant: return showDining
            default: return false
            }
        }
    }

    var body: some View {
        NavigationStack {
            Map(initialPosition: .automatic) {
                ForEach(mappableEntities) { ride in
                    if let location = locations[ride.id] {
                        Annotation(ride.name, coordinate: CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )) {
                            markerView(for: ride)
                                .onTapGesture {
                                    selectedRide = ride
                                }
                        }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard(
                elevation: .realistic,
                // Restroom locations come from Apple's own POI data — the park
                // API doesn't provide them.
                pointsOfInterest: showRestrooms ? .including([.restroom]) : .excludingAll
            ))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .safeAreaInset(edge: .top) {
                filterChips
            }
            .navigationTitle(park.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedRide) { ride in
                NavigationStack {
                    RideDetailView(
                        ride: ride,
                        location: locations[ride.id],
                        park: park,
                        timezone: timezone ?? .current
                    )
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                MapFilterChip(label: "Rides", icon: "sparkles", color: .cyan, isOn: $showRides)
                MapFilterChip(label: "Shows", icon: "theatermasks.fill", color: .purple, isOn: $showShows)
                MapFilterChip(label: "Dining", icon: "fork.knife", color: .teal, isOn: $showDining)
                MapFilterChip(label: "Restrooms", icon: "toilet.fill", color: .indigo, isOn: $showRestrooms)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func markerView(for ride: LiveEntity) -> some View {
        Group {
            if ride.entityType == .restaurant {
                Image(systemName: "fork.knife")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(ride.status == nil || ride.isOpen ? Color.teal : Color.gray.opacity(0.8)))
            } else if ride.isShow {
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(.purple))
            } else if ride.isOpen {
                Text(ride.waitTime.map { "\($0)m" } ?? "0m")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.forWait(ride.waitTime ?? 0)))
            } else {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(6)
                    .background(Circle().fill(.gray.opacity(0.8)))
            }
        }
        .shadow(radius: 2)
        .accessibilityLabel(markerAccessibility(for: ride))
    }

    private func markerAccessibility(for ride: LiveEntity) -> String {
        if ride.entityType == .restaurant {
            return "\(ride.name), dining\(ride.status == nil || ride.isOpen ? "" : ", closed")"
        }
        if ride.isShow { return "\(ride.name), show" }
        if ride.isOpen {
            if let wait = ride.waitTime, wait > 0 { return "\(ride.name), \(wait) minute wait" }
            return "\(ride.name), walk on"
        }
        return "\(ride.name), closed"
    }
}

private struct MapFilterChip: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isOn ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isOn ? AnyShapeStyle(color) : AnyShapeStyle(Color.cardBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(isOn ? "shown" : "hidden")")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}
