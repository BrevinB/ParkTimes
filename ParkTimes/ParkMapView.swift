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
    @State private var showRestrooms = ProcessInfo.processInfo.arguments.contains("-showRestrooms")
    @State private var restrooms: [RestroomPlace] = []
    @State private var restroomSearchDone = false

    struct RestroomPlace: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

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
                if showRestrooms {
                    ForEach(restrooms) { restroom in
                        Annotation(restroom.name, coordinate: restroom.coordinate) {
                            Image(systemName: "toilet.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Circle().fill(Color.indigo))
                                .shadow(radius: 2)
                                .accessibilityLabel("\(restroom.name), restroom")
                        }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .safeAreaInset(edge: .top) {
                filterChips
            }
            .onChange(of: showRestrooms) { _, isOn in
                if isOn {
                    Task { await loadRestrooms() }
                }
            }
            .task {
                if showRestrooms {
                    await loadRestrooms()
                }
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
            .overlay(alignment: .bottomLeading) {
                if showRestrooms && !restrooms.isEmpty {
                    Text("Restrooms © OpenStreetMap")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .padding(.leading, 8)
                        .padding(.bottom, 26)
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

    /// The park API has no restroom data. OpenStreetMap maps park interiors
    /// accurately (amenity=toilets), so query it first; fall back to Apple's
    /// POI search only if OSM has nothing for this park.
    private func loadRestrooms() async {
        guard !restroomSearchDone, let region = parkRegion else { return }
        restroomSearchDone = true

        let osmResults = await RestroomService.restrooms(
            south: region.center.latitude - region.span.latitudeDelta / 2,
            west: region.center.longitude - region.span.longitudeDelta / 2,
            north: region.center.latitude + region.span.latitudeDelta / 2,
            east: region.center.longitude + region.span.longitudeDelta / 2,
            cacheKey: park.id
        )

        if !osmResults.isEmpty {
            restrooms = osmResults.map {
                RestroomPlace(
                    name: "Restroom",
                    coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                )
            }
            return
        }

        // Fallback: Apple's POI database (coverage and accuracy vary).
        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restroom])

        guard let response = try? await MKLocalSearch(request: request).start() else {
            restroomSearchDone = false
            return
        }
        restrooms = response.mapItems.map {
            RestroomPlace(name: $0.name ?? "Restroom", coordinate: $0.placemark.coordinate)
        }
    }

    /// Bounding region of everything we can place in this park, lightly padded.
    private var parkRegion: MKCoordinateRegion? {
        let coordinates = entities.compactMap { locations[$0.id] }
        guard !coordinates.isEmpty else { return nil }

        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.3, 0.005),
                longitudeDelta: max((maxLon - minLon) * 1.3, 0.005)
            )
        )
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
