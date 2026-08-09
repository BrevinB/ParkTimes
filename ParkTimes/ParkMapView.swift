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

    private var mappableRides: [LiveEntity] {
        entities.filter { ($0.isAttraction || $0.isShow) && locations[$0.id] != nil }
    }

    var body: some View {
        NavigationStack {
            Map(initialPosition: .automatic) {
                ForEach(mappableRides) { ride in
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
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
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

    @ViewBuilder
    private func markerView(for ride: LiveEntity) -> some View {
        Group {
            if ride.isShow {
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
        if ride.isShow { return "\(ride.name), show" }
        if ride.isOpen {
            if let wait = ride.waitTime, wait > 0 { return "\(ride.name), \(wait) minute wait" }
            return "\(ride.name), walk on"
        }
        return "\(ride.name), closed"
    }
}
